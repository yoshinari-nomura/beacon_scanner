#!/usr/bin/env ruby

################################################################
# rbenv support:
# If this file is a symlink, and bound to a specific ruby
# version via rbenv (indicated by RBENV_VERSION),
# I want to resolve the symlink and re-exec
# the original executable respecting the .ruby-version
# which should indicate the right version.

if File.symlink?(__FILE__) and ENV["RBENV_VERSION"]
  ENV["RBENV_VERSION"] = nil
  ENV["RBENV_DIR"] = nil

  shims_path = File.expand_path("shims", ENV["RBENV_ROOT"])
  ENV["PATH"] = shims_path + ":" + ENV["PATH"]

  exec(File.readlink(__FILE__), *ARGV)
end

################################################################
# Linux bluez needs root privilege.
# If current user is not root, try to exec sudo.

if /linux/ =~ RUBY_PLATFORM
  unless Process.uid.zero?
    exec("sudo", *([RbConfig.ruby, __FILE__] + ARGV))
  end
end

################################################################
# This script is supposed to be located at TOP/bin/this_script,
# also TOP/Gemfile.lock exists.

gemfile = File.expand_path("../../Gemfile", __FILE__)

if File.exists?(gemfile + ".lock")
  ENV["BUNDLE_GEMFILE"] = gemfile
  require "bundler/setup"
end

require "rubygems"
require 'scan_beacon'
require 'redis'

################################################################
# Helper classes

class BeaconStatus
  # room 205 and 106
  MEMBER_UUIDS = ["467fd32695d242f2bbbc5c8f4610b120", "467fd32695d242f2bbbc5c8f4610b121"]

  attr_reader :uuid, :major, :minor, :power, :rssi, :timestamp

  def initialize(uuid, major, minor, power, rssi, timestamp = Time.now)
    @uuid, @major, @minor, @power, @rssi, @timestamp =
      uuid, major.to_i, minor.to_i, power.to_i, rssi.to_i, timestamp
  end

  def lock_status
    return 0 if major == 8
    return 1 # locked
  end

  def member?
    MEMBER_UUIDS.member?(uuid)
  end

  def dump
    timestr = timestamp.strftime("%Y-%m-%d %H:%M:%S %z")
    return "#{timestr}/#{uuid}/#{major}/#{minor}/#{power}/#{rssi} (lock:#{lock_status})"
  end

  # XXX should be in subclass
  def push_to_redis(redis, key)
    redis.set     "#{key}.major",     major
    redis.set     "#{key}.minor",     minor
    redis.set     "#{key}.power",     power
    redis.set     "#{key}.rssi",      rssi
    redis.set     "#{key}.timestamp", timestamp
    redis.set     "#{key}.locked",    lock_status
    redis.publish "#{key}.updated",   timestamp
  end

end # class BeaconStatus

class BeaconScanner
  def event_loop(&block)
    case RUBY_PLATFORM
    when /darwin/
      event_loop_macos(&block)
    when /linux/
      event_loop_linux(&block)
    end
  end

  private

  # XXX should be in subclass
  def event_loop_macos(&block)
    ScanBeacon::CoreBluetooth::scan do
      advertisements = ScanBeacon::CoreBluetooth::new_adverts
      continue_loop = true

      advertisements.each do |scan|
        # scan[] has :device, :data, :rssi, :service_uuid
        # iBeacon format:  4 + 16 + 2 + 2 + 1 = 25
        #   4C 00 02 15 (16bytes UUID) (2bytes Major) (2bytes Minor) (1byte Power)
        # CoreBluetooth includes first 4 bytes 4C 00 02 15 in scan[:data]
        break unless scan[:data] && scan[:data].size >= 25
        header, uuid, major, minor, power = scan[:data].unpack("H8 H32 n n c")
        continue_loop = yield header, uuid, major, minor, power, scan[:rssi]
      end

      sleep 3 if continue_loop
      continue_loop # loop forever if true
    end
  end

  # XXX should be in subclass
  def event_loop_linux(&block)
    device_id = ScanBeacon::BlueZ.devices[0][:device_id]
    continue_loop = true

    while continue_loop
      ScanBeacon::BlueZ.scan(device_id) do |mac, scan, rssi|
        # https://support.kontakt.io/hc/en-gb/articles/201492492-iBeacon-advertising-packet-structure
        # bluez retuns extra five bytes advertised header: discard it eating by H10
        break unless scan && scan.size >= 30
        _, header, uuid, major, minor, power = scan.unpack("H10 H8 H32 n n c")
        continue_loop = yield header, uuid, major, minor, power, rssi
      end
      sleep 3 if continue_loop
    end
  end
end

################################################################
### main

STDOUT.sync = true

#
# Usage: beacon_scanner.rb [--redis key]
#
if ARGV.shift == '--redis'
  $redis = Redis.new
  $redis_key = ARGV.shift

  unless $redis_key
    STDERR.puts "beacon_scanner.rb [--redis key]"
    exit(-1)
  end
end

BeaconScanner.new.event_loop do |header, uuid, major, minor, power, rssi|
  if header == "4c000215" # Apple iBeacon
    stat = BeaconStatus.new(uuid, major, minor, power, rssi)
    if stat.member?
      puts stat.dump
      stat.push_to_redis($redis, $redis_key) if $redis
    end
  end
  true # loop forever
end
