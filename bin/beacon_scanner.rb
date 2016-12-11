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
# This script is supposed to be located at TOP/bin/this_script.
# Also TOP/Gemfile.lock exists.

gemfile = File.expand_path("../../Gemfile", __FILE__)

if File.exists?(gemfile + ".lock")
  ENV["BUNDLE_GEMFILE"] = gemfile
  require "bundler/setup"
end

require "rubygems"
require 'scan_beacon'


################################################################
# This script is supposed to be located at TOP/bin/this_script.
# Also TOP/Gemfile.lock exists.

STDOUT.sync = true

UUIDS = ["467fd32695d242f2bbbc5c8f4610b120"]

def dump(uuid, major, minor, pwr, rssi)
  time = Time.now.strftime("%Y-%m-%d %H:%M:%S %z")
  if UUIDS.member?(uuid)
    # 2016-12-10 21:47:49 +0900/467fd32695d242f2bbbc5c8f4610b120/0/0/-55/-84
    puts "#{time}/#{uuid}/#{major}/#{minor}/#{pwr}/#{rssi}"
  end
end

case RUBY_PLATFORM
when /darwin/
  ScanBeacon::CoreBluetooth::scan do
    advertisements = ScanBeacon::CoreBluetooth::new_adverts
    advertisements.each do |scan|
      # scan[] has :device, :data, :rssi, :service_uuid
      # iBeacon format:  4 + 16 + 2 + 2 + 1 = 25
      #   4C 00 02 15 (16bytes UUID) (2bytes Major) (2bytes Minor) (1byte Power)
      # CoreBluetooth includes first 4 bytes 4C 00 02 15 in scan[:data]
      if scan[:data] && scan[:data].size >= 25
        header, uuid, major, minor, pwr = scan[:data].unpack("H8 H32 n n c")
        if header == "4c000215" # Apple iBeacon
          dump(uuid, major, minor, pwr, scan[:rssi])
        end
      end
    end
    sleep 3
    true # loop forever
  end

when /linux/
  device_id = ScanBeacon::BlueZ.devices[0][:device_id]
  while true
    ScanBeacon::BlueZ.scan(device_id) do |mac, ad_data, rssi|
      if ad_data && ad_data.size >= 30
        # https://support.kontakt.io/hc/en-gb/articles/201492492-iBeacon-advertising-packet-structure
        # bluez retuns extra five bytes advertised header: discard it eating by H10
        _, header, uuid, major, minor, pwr = ad_data.unpack("H10 H8 H32 n n c")
        if header == "4c000215" # Apple iBeacon
          dump(uuid, major, minor, pwr, rssi)
        end
      end
    end
    sleep 3
  end
end
