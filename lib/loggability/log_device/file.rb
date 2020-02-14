#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'logger'
require 'loggability/logger' unless defined?( Loggability::Logger )

# A log device that delegates to the ruby's default Logger's file device and writes
# to a file descriptor or a file.
class Loggability::LogDevice::File < Loggability::LogDevice

	### Create a new +File+ device that will write to the file using the built-in ruby's +File+ log device
	def initialize( target )
		@target = ::Logger::LogDevice.new( target )
	end


	######
	public
	######

	# The target of the log device
	attr_reader :target


	### Append the specified +message+ to the target.
	def write( message )
		self.target.write( message )
	end


	### close the file
	def close
		self.target.close
	end

end # class Loggability::LogDevice::File
