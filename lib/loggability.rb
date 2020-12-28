# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require 'logger'
require 'date'

# A mixin that provides a top-level logging subsystem based on Logger.
module Loggability

	# Package version constant
	VERSION = '0.18.2'

	# The key for the global logger (Loggability's own logger)
	GLOBAL_KEY = :__global__

	# The methods that are delegated across all loggers
	AGGREGATE_METHODS = [ :level=, :output_to, :write_to, :format_with, :format_as, :formatter= ]

	# Configuration defaults
	CONFIG_DEFAULTS = {
		:__default__ => 'warn STDERR',
	}.freeze

	# Regexp for parsing logspec lines in the config
	LOGSPEC_PATTERN = %r{
		^
			\s*
			(?<severity>(?i:debug|info|warn|error|fatal))
		    (?:
				\s+
				(?<target>(?:[\w\-/:\.\[\]]|\\[ ])+)
			)?
			(?: \s+\(
				(?<format>\w+)
			\) )?
			\s*
		$
	}x


	# Automatically load subordinate classes/modules
	autoload :Constants, 'loggability/constants'
	autoload :LogDevice, 'loggability/log_device'
	autoload :Logger, 'loggability/logger'
	autoload :LogHost, 'loggability/loghost'
	autoload :LogClient, 'loggability/logclient'
	autoload :Override, 'loggability/override'

	include Loggability::Constants


	##
	# The Hash of modules that have a Logger, keyed by the name they register with
	class << self; attr_reader :log_hosts; end
	@log_hosts = {}

	##
	# The last logging configuration that was installed
	class << self; attr_accessor :config; end
	@config = CONFIG_DEFAULTS.dup.freeze




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
			# raise "Can't set a log host for nil" if key.nil?
			self.logger.warn "Replacing existing log host for %p (%p) with %p" %
				[ key, self.log_hosts[key], host ]
		end

		#self.logger.debug "Registering %p log host: %p" % [ key, host ] if self.logger
		self.log_hosts[ key ] = host
		if (( logspec = Loggability.config[key] ))
			self.apply_config( host.logger, logspec )
		elsif (( defaultspec = (Loggability.config[:__default__] || Loggability.config['__default__']) ))
			self.apply_config( host.logger, defaultspec )
		else
			self.apply_config( host.logger, CONFIG_DEFAULTS[:__default__] )
		end
	end


	### Return the log host key for +object+, using its #log_host_key method
	### if it has one, or returning it as a Symbol if it responds to #to_sym. Returns
	### +nil+ if no key could be derived.
	def self::log_host_key_for( object )
		return object.log_host_key if object.respond_to?( :log_host_key )
		return object.to_sym if object.respond_to?( :to_sym )
		return nil
	end


	### Return the log host for +object+, if any. Raises an ArgumentError if the +object+
	### doesn't have an associated log host.
	def self::log_host_for( object )
		key = self.log_host_key_for( object )
		key ||= GLOBAL_KEY

		loghost = self.log_hosts[ key ] or
			raise ArgumentError, "no log host set up for %p yet." % [ key ]

		return loghost
	end


	### Returns +true+ if there is a log host associated with the given +object+.
	def self::log_host?( object )
		key = self.log_host_key_for( object ) or return false
		return self.log_hosts.key?( key )
	end


	### Return the Loggability::Logger for the loghost associated with +logclient+.
	def self::[]( logclient )
		loghost = self.log_host_for( logclient )
		return loghost.logger
	end


	### Clear out all registered log hosts and reset the default logger. This is
	### mostly intended for facilitating tests.
	def self::reset
		self.log_hosts.clear
		self.logger = self.default_logger = Loggability::Logger.new
		Loggability.register_loghost( self )
	end


	#
	# :section: Aggregate Methods
	#

	### Call the method with the given +methodname+ across the loggers of all loghosts with
	### the given +arg+ and/or +block+.
	def self::aggregate( methodname, *args, &block )
		# self.log.debug "Aggregating a call to %p with %p to %d log hosts" %
		#	[ methodname, arg, Loggability.log_hosts.length ]
		Loggability.log_hosts.values.each do |loghost|
			# self.log.debug "  %p.logger.%s( %p )" % [ loghost, methodname, arg ]
			loghost.logger.send( methodname, *args, &block )
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


	### Aggregate method: set the log level on all loggers to +level+ for the duration
	### of the +block+, restoring the original levels afterward. If no block is given, returns a
	### Loggability::Override object that set the log level to +level+ while its +#call+
	### method is being called.
	def self::with_level( level, &block )
		override = Loggability::Override.with_level( level )

		if block
			return override.call( &block )
		else
			return override
		end
	end


	##
	# :method: output_to
	# :call-seq:
	#   output_to( destination )
	#   write_to( destination )
	#
	# Aggregate method: set all loggers to log to +destination+. See Loggability::Logger#output_to
	# for more info.
	def self::output_to( newdevice, *args )
		self.aggregate( :output_to, newdevice, *args )
	end
	class << self
		alias_method :write_to, :output_to
	end


	### Aggregate method: set all loggers to log to +destination+ for the duration of the
	### +block+, restoring the original destination afterward. If no block is given, returns a
	### Loggability::Override object that will log to +destination+ whenever its +#call+ method is
	### called.
	def self::outputting_to( newdevice, &block )
		override = Loggability::Override.outputting_to( newdevice )

		if block
			return override.call( &block )
		else
			return override
		end
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


	### Aggregate method: set all loggers to log with the given +formatter+ for the duration
	### of the +block+, restoring the original formatters afterward. If no block is given,
	### returns a Loggability::Override object that will override all formatters whenever its
	### +#call+ method is called.
	def self::formatted_with( formatter, &block )
		override = Loggability::Override.formatted_with( formatter )

		if block
			return override.call( &block )
		else
			return override
		end
	end


	### Aggregate method: override one or more settings for the duration of the +block+ for
	### only the given +hosts+. If no +block+ is given returns a
	### Loggability::Override object that will override the specified log hosts whenever its
	### +#call+ method is called.
	def self::for_logger( *hosts, &block )
		override = Loggability::Override.for_logger( *hosts )

		if block
			return override.call( &block )
		else
			return override
		end
	end
	class << self
		alias_method :for_loggers, :for_logger
		alias_method :for_log_host, :for_logger
		alias_method :for_log_hosts, :for_logger
	end


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



	#
	# :section: Configurability Support
	#

	### Configure the specified +logger+ (or anything that ducktypes the same) with the
	### configuration specified by +logspec+.
	def self::apply_config( logger, logspec )
		level, format, target = self.parse_config_spec( logspec )
		logger.level = level if level
		logger.format_with( format ) if format
		logger.output_to( target ) if target
	end


	### Parse the specified +spec+ into level,
	def self::parse_config_spec( spec )
		match = LOGSPEC_PATTERN.match( spec ) or
			raise ArgumentError, "Couldn't parse logspec: %p" % [ spec ]
		# self.log.debug "  parsed config spec %p -> %p" % [ spec, match ]
		severity, target, format = match.captures

		target = case target
			when 'STDOUT' then $stdout
			when 'STDERR' then $stderr
			when /:/ then Loggability::LogDevice.parse_device_spec( target )
			else
				target
			end

		return severity, format, target
	end


	# Install a global logger in Loggability itself
	extend( Loggability::LogHost )
	self.log_host_key = GLOBAL_KEY
	self.logger = self.default_logger = Loggability::Logger.new
	Loggability.register_loghost( self )


	### Configurability API -- configure logging.
	def self::configure( new_config=nil )
		if new_config
			self.config = new_config.dup.freeze
			confighash = new_config.to_hash

			# Set up all loggers with defaults first
			if defaultspec = confighash.delete( :__default__ ) || confighash.delete( '__default__' )
				self.apply_config( self, defaultspec )
			end

			# Then let individual configs override.
			confighash.each do |key, logspec|
				unless Loggability.log_host?( key )
					self.log.debug "  no such log host %p; skipping" % [ key ]
					next
				end

				# self.log.debug "  configuring logger for %p: %s" % [ key, logspec ]
				self.apply_config( Loggability[key], logspec )
			end
		else
			self.config = self.defaults.dup.freeze
		end
	end


end # module Loggability

