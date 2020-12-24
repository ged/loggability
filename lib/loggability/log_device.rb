#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability' unless defined?( Loggability )


# An abstract base class for logging devices. A device manages the actual writing of messages
# to whatever destination logs are supposed to be shipped to, along with any buffering,
# encoding, or serialization that needs to be done.
#
# Log devices are loadable by name via the ::create method if they are declared in a
# directory named `loggability/log_device/` in the gem path.
#
# Concrete log devices are required to implement two methods: #write and #close.
#
# [write]
#   Takes one argument, which is the message that needs to be written.
#
# [close]
#   Close any open filehandles or connections established by the device.
class Loggability::LogDevice


	# Regexp used to split up logging devices in config lines
	DEVICE_TARGET_REGEX = /^([\s*a-z]\w*)(?:\[(.*)\])?/


	### Parses out the target class name and its arguments from the +target_spec+
	### then requires the subclass and instantiates it by passing the arguments.
	### The +target_spec+ comes from a config file in the format of:
	###
	###   logging:
	###     datadog[data_dog_api_key]
	###
	### In the above example:
	### * "datadog" is the log device to send logs to
	### * "data_dog_api_key" is the argument that will be passed onto the datadog
	###   log device's constructor
	def self::parse_device_spec( target_spec )
		targets = target_spec.split( ';' ).compact
		return targets.map do |t|
			target_subclass = t[ DEVICE_TARGET_REGEX, 1 ]&.strip.to_sym
			target_subclass_args = t[ DEVICE_TARGET_REGEX, 2 ]

			self.create( target_subclass, target_subclass_args )
		end
	end


	### Requires the subclass and instantiates it with the passed-in arguments and
	### then returns an instance of it.
	def self::create( target, *target_args )
		modname = target.to_s.capitalize

		self.load_device_type( target ) unless self.const_defined?( modname, false )
		subclass = self.const_get( modname, false )

		return subclass.new( *target_args )
	rescue NameError => err
		raise LoadError, "failed to load %s LogDevice: %s" % [ target, err.message ]
	end


	### Attempt to load a LogDevice of the given +type+.
	def self::load_device_type( type )
		require_path = "loggability/log_device/%s" % [ type.to_s.downcase ]
		require( require_path )
	end


	### Write a +message+ to the device. This needs to be overridden by concrete
	### subclasses; calling this implementation will raise an NotImplementedError.
	def write( message )
		raise NotImplementedError, "%s is not implemented by %s" % [ __callee__, self.class.name ]
	end


	### Close the device. This needs to be overridden by concrete subclasses;
	### calling this implementation will raise an NotImplementedError.
	def close
		raise NotImplementedError, "%s is not implemented by %s" % [ __callee__, self.class.name ]
	end

end # class Loggability::LogDevice

