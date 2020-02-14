#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability/logger' unless defined?( Loggability::Logger )

# A log device that appends to the object it's constructed with instead of writing
# to a file descriptor or a file.
class Loggability::LogDevice::Appending < Loggability::LogDevice

	### Create a new +Appending+ log device that will append content to +array+.
	def initialize( target )
		@target = target || []
	end


	######
	public
	######

	# The target of the log device
	attr_reader :target


	### Append the specified +message+ to the target.
	def write( message )
		@target << message
	end


	### No-op -- this is here just so Logger doesn't complain
	def close; end

end # class Loggability::LogDevice::Appending
