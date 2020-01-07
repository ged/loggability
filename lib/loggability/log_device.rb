#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability' unless defined?( Loggability )


### Parent class of all Loggability's log devices and can require
### and instantiate its subclassses by name and args
class Loggability::LogDevice

	### Parses out the target class name and its arguments from the +target_spec+
	### then requires the subclass and instantiates it by passing the arguments
	### The +target_spec+ comes from a config file in the format of:
	### logging:
	###     datadog[data_dog_api_key]
	### In the above example:
	### 	"datadog" is the log device to send logs to
	### 	"data_dog_api_key" is the argument that will be passed onto the datadog log device's constructor
	def self::parse_device_spec( target_spec )
		targets = target_spec.split( ':' ).compact
		return targets.map do |t|
			target_regex = /^([\s*a-z]\w*)(?:\[(.*)\])?/

			target_subclass = t[ target_regex, 1 ]&.strip().to_sym
			target_subclass_args = t[ target_regex, 2 ]

			self.create( target_subclass, target_subclass_args )
		end
	end


	### Requires the subclass and instantiates it with the passed-in
	### arguments and then returns an instance of it.
	def self::create( target, target_args )
		case target
		when :appending
			require 'loggability/log_device/appending'
			return Loggability::LogDevice::Appending.new( target_args )
		when :file
			require 'loggability/log_device/file'
			return Loggability::LogDevice::File.new( target_args )
		when :datadog
			require 'loggability/log_device/datadog'
			return Loggability::LogDevice::Datadog.new( target_args )
		else
			raise "%s sublcass not found" % [ target ]
		end
	end

end
