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

beacon = ScanBeacon::EddystoneUrlBeacon.new(
  url: "https://goo.gl/VPfbp1",
  power: -20
)

advertiser = ScanBeacon::DefaultAdvertiser.new(beacon: beacon)

advertiser.start
puts "Advertising started."

puts "Press Enter key to stop advertising."
gets

advertiser.stop
puts "Advertising stopped."
