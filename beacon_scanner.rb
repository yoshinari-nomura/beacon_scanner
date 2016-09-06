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

UUID = "467fd32695d242f2bbbc5c8f4610b120"

def dump(uuid, major, minor, pwr, rssi)
  time = Time.now.strftime("%Y-%m-%d %H:%M:%S %z")
  if uuid == UUID
    puts "#{time}/#{uuid}/#{major}/#{minor}/#{pwr}/#{rssi}"
  end
end

if false
scanner = ScanBeacon::DefaultScanner.new

scanner.scan do |beacons|
  puts "scanning..."
  beacons.each do |beacon|
    puts beacon.inspect
  end
end

end
device_id = ScanBeacon::BlueZ.devices[0][:device_id]

STDOUT.sync = true
while true
  STDERR.puts "scanning..."
  ScanBeacon::BlueZ.scan(device_id) do |mac, ad_data, rssi|
    if ad_data && ad_data.size >= 30
      uuid, major, minor, pwr = ad_data.unpack("@9 H32 n n c")
      dump(uuid, major, minor, pwr, rssi)
    else
     # puts "nil"
    end
  end
  sleep 3
end
