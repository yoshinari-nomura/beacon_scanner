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
require "pp"

# scanner = ScanBeacon::DefaultScanner.new
# scanner = ScanBeacon::CoreBluetoothScanner.new

while true
  ScanBeacon::CoreBluetooth::scan do
    sleep 0.2
    advertisements = ScanBeacon::CoreBluetooth::new_adverts
    advertisements.each do |scan|
      puts "----------------------------------"
      if scan[:service_uuid]
        pp scan[:service_uuid] + scan[:data]
      else
        puts "device: #{scan[:device]}"
        puts scan[:data].unpack("C*").map{|c| "%02X" % c}.join
      end
    end
  end
  sleep 2
end

# scanner.scan do |beacons|
#   puts "scanning..."
#   beacons.each do |beacon|
#     puts beacon.inspect
#   end
# end
