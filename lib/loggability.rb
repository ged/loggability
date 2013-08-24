# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'logger'
require 'date'

# A mixin that provides a top-level logging subsystem based on Logger.
module Loggability

	# Package version constant
	VERSION = '0.7.0'

	# VCS revision
	REVISION = %q$Revision$

	# The key for the global logger (Loggability's own logger)
	GLOBAL_KEY = :__global__

	# The methods that are delegated across all loggers
	AGGREGATE_METHODS = [ :level=, :output_to, :write_to, :format_with, :format_as, :formatter= ]

	# Configuration defaults
	CONFIG_DEFAULTS = {
		:__default__ => 'warn STDERR',
	}

	# Regexp for parsing logspec lines in the config
	LOGSPEC_PATTERN = %r{
		^
			\s*
			((?i:debug|info|warn|error|fatal))   # severity
		    (?:
				\s+
				((?:[\w\-/:\.]|\\[ ])+)
			)?
			(?: \s+\(
				(\w+)
			\) )?
			\s*
		$
	}x

	require 'loggability/constants'
	include Loggability::Constants

	require 'loggability/logger'


	##
	# The Hash of modules that have a Logger, keyed by the name they register with
	class << self; attr_reader :log_hosts; end
	@log_hosts = {}


	### Return the library's version string
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end


	### Cast the given +device+ to a Loggability::Logger, if possible, and return it. If
	### it can't be converted, raises a ArgumentError.
	def self::Logger( device )
		return device if device.is_a?( Loggability::Logger )
		return Loggability::Logger.from_std_logger( device ) if device.is_a?( ::Logger )
		return Loggability::Logger.new( device )
	end


	### Register the specified +host+ as a log host. It should already have been extended
	### with LogHostMethods.
	def self::register_loghost( host )
		key = host.log_host_key
		if self.log_hosts.key?( key )
			self.logger.warn "Replacing existing log host for %p (%p) with %p" %
				[ key, self.log_hosts[key], host ]
		end

		self.logger.debug "Registering %p log host: %p" % [ key, host ] if self.logger
		self.log_hosts[ key ] = host
	end


	### Return the log host key for +object+, using its #log_host_key method
	### if it has one, or returning it as a Symbol if it responds to #to_sym. Returns
	### +nil+ if no key could be derived.
	def self::log_host_key_for( object )
		return object.log_host_key if object.respond_to?( :log_host_key )
		return object.to_sym if object.respond_to?( :to_sym )
		return nil
	end


	### Returns +true+ if there is a log host associated with the given +object+.
	def self::log_host?( object )
		key = self.log_host_key_for( object ) or return false
		return self.log_hosts.key?( key )
	end


	### Return the Loggability::Logger for the loghost associated with +logclient+.
	def self::[]( logclient )
		key = self.log_host_key_for( logclient )
		key ||= GLOBAL_KEY

		return self.log_hosts[ key ].logger
	end


	### Clear out all log hosts except for ones which start with '_'. This is intended
	### to be used for testing.
	def self::clear_loghosts
		self.log_hosts.delete_if {|key,_| !key.to_s.start_with?('_') }
	end


	#
	# :section: Aggregate Methods
	#

	### Call the method with the given +methodname+ across the loggers of all loghosts with
	### the given +arg+ and/or +block+.
	def self::aggregate( methodname, arg, &block )
		# self.log.debug "Aggregating a call to %p with %p to %d log hosts" %
		#	[ methodname, arg, Loggability.log_hosts.length ]
		Loggability.log_hosts.values.each do |loghost|
			# self.log.debug "  %p.logger.%s( %p )" % [ loghost, methodname, arg ]
			loghost.logger.send( methodname, arg, &block )
		end
	end


	##
	# :method: level=
	# :call-seq:
	#   level = newlevel
	#
	# Aggregate method: set the log level on all loggers to +newlevel+. See
	# Loggability::Logger#level= for more info.
	def self::level=( newlevel )
		self.aggregate( :level=, newlevel )
	end


	##
	# :method: output_to
	# :call-seq:
	#   output_to( destination )
	#   write_to( destination )
	#
	# Aggregate method: set all loggers to log to +destination+. See Loggability::Logger#output_to
	# for more info.
	def self::output_to( newdevice )
		self.aggregate( :output_to, newdevice )
	end
	class << self
		alias_method :write_to, :output_to
	end


	##
	# :method: format_with
	# :call-seq:
	#   format_with( formatter )
	#   format_as( formatter )
	#   formatter = formatter
	#
	# Aggregate method: set all loggers to log with the given +formatter+. See
	# Loggability::Logger#format_with for more info.
	def self::format_with( formatter )
		self.aggregate( :format_with, formatter )
	end
	class << self
		alias_method :format_as, :format_with
		alias_method :formatter=, :format_with
	end


	# Extension for 'log hosts'. A <b>log host</b> is an object that hosts a Loggability::Logger
	# object, and is typically the top of some kind of hierarchy, like a namespace
	# module for a project:
	#
	#     module MyProject
	#
	#     end
	#
	# This module isn't mean to be used directly -- it's installed via the Loggability#log_as
	# declaration, which also does some other initialization that you'll likely want.
	#
	#
	module LogHost

		# The logger that will be used when the logging subsystem is reset
		attr_accessor :default_logger

		# The logger that's currently in effect
		attr_reader :logger
		alias_method :log, :logger

		# The key associated with the logger for this host
		attr_accessor :log_host_key


		### Set the logger associated with the LogHost to +newlogger+. If +newlogger+ isn't a
		### Loggability::Logger, it will be converted to one.
		def logger=( newlogger )
			@logger = Loggability::Logger( newlogger )
		end
		alias_method :log=, :logger=

	end # module LogHost


	# Methods to install for objects which call +log_to+.
	module LogClient

		##
		# The key of the log host this client targets
		attr_accessor :log_host_key

		### Return the Loggability::Logger object associated with the log host the
		### client is logging to.
		### :TODO: Use delegation for efficiency.
		def log
			@__log ||= Loggability[ self ].proxy_for( self )
		end


		### Inheritance hook -- set the log host key of subclasses to the same
		### thing as the extended class.
		def inherited( subclass )
			super
			Loggability.log.debug "Setting up subclass %p of %p to log to %p" %
				[ subclass, self, self.log_host_key ]
			subclass.log_host_key = self.log_host_key
		end


		# Stuff that gets added to instances of Classes that are log hosts.
		module InstanceMethods

			### Fetch the key of the log host the instance of this client targets
			def log_host_key
				return self.class.log_host_key
			end


			### Delegate to the class's logger.
			def log
				@__log ||= Loggability[ self.class ].proxy_for( self )
			end

		end # module InstanceMethods

	end # module LogClient


	#
	# :section: LogHost API
	#

	### Register as a log host associated with the given +key+, add the methods from
	### LogHost, and install a Loggability::Logger.
	def log_as( key )
		extend( Loggability::LogHost )
		include( Loggability::LogClient::InstanceMethods ) if self.is_a?( Class )

		self.log_host_key = key.to_sym
		self.logger = self.default_logger = Loggability::Logger.new
		Loggability.register_loghost( self )
	end


	#
	# :section: LogClient API
	#

	### Register as a <b>log client</b> that will log to to the given +loghost+, which can be
	### either the +key+ the host registered with, or the log host object itself. Log messages
	### can be written to the loghost via the LogClient API, which is automatically included.
	def log_to( loghost )
		extend( Loggability::LogClient )
		include( Loggability::LogClient::InstanceMethods ) if self.is_a?( Class )

		self.log_host_key = Loggability.log_host_key_for( loghost )
	end


	# Install a global logger in Loggability itself
	extend( Loggability::LogHost )
	self.log_host_key = GLOBAL_KEY
	self.logger = self.default_logger = Loggability::Logger.new
	Loggability.register_loghost( self )


	#
	# :section: Configurability Support
	#

	### Configurability API -- configure logging.
	def self::configure( config=nil )
		if config
			self.log.debug "Configuring Loggability with custom config."
			confighash = config.to_hash

			# Set up all loggers with defaults first
			if defaultspec = confighash.delete( :__default__ ) || confighash.delete( '__default__' )
				level, format, target = self.parse_config_spec( defaultspec )
				Loggability.level = level if level
				Loggability.format_as( format ) if format
				Loggability.output_to( target ) if target
			end

			# Then let individual configs override.
			confighash.each do |key, logspec|
				unless Loggability.log_host?( key )
					self.log.debug "  no such log host %p; skipping" % [ key ]
					next
				end

				self.log.debug "  configuring logger for %p: %s" % [ key, logspec ]
				level, format, target = self.parse_config_spec( logspec )
				Loggability[ key ].level = level if level
				Loggability[ key ].format_with( format ) if format
				Loggability[ key ].output_to( target ) if target
			end
		else
			self.log.debug "Configuring Loggability with defaults."
		end
	end


	### Parse the specified +spec+ into level,
	def self::parse_config_spec( spec )
		match = LOGSPEC_PATTERN.match( spec ) or
			raise ArgumentError, "Couldn't parse logspec: %p" % [ spec ]
		self.log.debug "  parsed config spec %p -> %p" % [ spec, match ]
		severity, target, format = match.captures

		target = case target
			when 'STDOUT' then $stdout
			when 'STDERR' then $stderr
			else
				target
			end

		return severity, format, target
	end


end # module Loggability

