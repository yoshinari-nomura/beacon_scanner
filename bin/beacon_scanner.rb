#!/usr/bin/env ruby

################################################################
# rbenv support:
# If this file is a symlink, and bound to a specific ruby
# version via rbenv (indicated by RBENV_VERSION),
# I want to resolve the symlink and re-exec
# the original executable respecting the .ruby_version
# which should indicate the right version.
#
if File.symlink?(__FILE__) and ENV["RBENV_VERSION"]
  ENV["RBENV_VERSION"] = nil
  shims_path = File.expand_path("shims", ENV["RBENV_ROOT"])
  ENV["PATH"] = shims_path + ":" + ENV["PATH"]
  exec(File.readlink(__FILE__), *ARGV)
end

gemfile = File.expand_path("../../Gemfile", __FILE__)

if File.exists?(gemfile + ".lock")
  ENV["BUNDLE_GEMFILE"] = gemfile
  require "bundler/setup"
end

require "rubygems"
require 'scan_beacon'
require 'pp'

STDOUT.sync = true

UUID = "467fd32695d242f2bbbc5c8f4610b120"

# 2016-12-10 21:47:49 +0900/467fd32695d242f2bbbc5c8f4610b120/0/0/-55/-84
def dump(uuid, major, minor, pwr, rssi)
  time = Time.now.strftime("%Y-%m-%d %H:%M:%S %z")
  if uuid == UUID
    puts "#{time}/#{uuid}/#{major}/#{minor}/#{pwr}/#{rssi}"
  end
end

# https://support.kontakt.io/hc/en-gb/articles/201492492-iBeacon-advertising-packet-structure

case RUBY_PLATFORM
when /darwin/
  ScanBeacon::CoreBluetooth::scan do
    advertisements = ScanBeacon::CoreBluetooth::new_adverts
    advertisements.each do |scan|
      # scan[] has :device, :data, :rssi, :service_uuid
      # iBeacon format:  4 + 16 + 2 + 2 + 1 = 25
      #   4C 00 02 15 (16bytes UUID) (2bytes Major) (2bytes Minor) (1byte Power)
      # CoreBluetooth includes first 4 bytes 4C 00 02 15 in scan[:data]
      # puts "service_uuid: #{scan[:service_uuid]}" if scan[:service_uuid]
      head, uuid, major, minor, pwr = scan[:data].unpack("H8 H32 n n c")
      if head == "4c000215" # Apple iBeacon
        dump(uuid, major, minor, pwr, scan[:rssi])
      end
    end
    sleep 3
    true # loop forever
  end

when /linux/
  device_id = ScanBeacon::BlueZ.devices[0][:device_id]
  while true
    STDERR.puts "scanning..."
    ScanBeacon::BlueZ.scan(device_id) do |mac, ad_data, rssi|
      if ad_data && ad_data.size >= 30
        uuid, major, minor, pwr = ad_data.unpack("@9 H32 n n c")
        dump(uuid, major, minor, pwr, rssi)
      else
        # debug
        # puts "nil"
      end
    end
    sleep 3
  end
end
