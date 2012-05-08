# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'logger'
require 'date'


# A mixin that provides a top-level logging subsystem based on Logger.
module Loggability

	# Package version constant
	VERSION = '0.1.0'

	# VCS revision
	REVISION = %q$Revision$

	# The key for the global logger (Loggability's own logger)
	GLOBAL_KEY = :__global__

	# The methods that are delegated across all loggers
	AGGREGATE_METHODS = [ :level=, :output_to, :write_to, :format_with, :format_as, :formatter= ]


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


	### Return the Loggability::Logger for the loghost associated with +logclient+.
	def self::[]( logclient )
		key = logclient.log_host_key if logclient.respond_to?( :log_host_key )
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
		Loggability.log_hosts.values.each do |loghost|
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
		attr_accessor :logger
		alias_method :log, :logger
		alias_method :log=, :logger=

		# The key associated with the logger for this host
		attr_accessor :log_host_key

	end # module LogHost


	#
	# :section: LogHost API
	#

	### Register as a log host associated with the given +key+, add the methods from
	### LogHost, and install a Loggability::Logger.
	def log_as( key )
		self.extend( Loggability::LogHost )
		self.log_host_key = key.to_sym
		self.logger = self.default_logger = Loggability::Logger.new
		Loggability.register_loghost( self )
	end

	# Install a global logger in Loggability itself
	extend( Loggability::LogHost )
	self.log_host_key = GLOBAL_KEY
	self.logger = self.default_logger = Loggability::Logger.new
	Loggability.register_loghost( self )



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
	# :section: LogClient API
	#

	### Register as a <b>log client</b> that will log to to the given +loghost+, which can be
	### either the +key+ the host registered with, or the log host object itself. Log messages
	### can be written to the loghost via the LogClient API, which is automatically included.
	def log_to( loghost )
		self.extend( Loggability::LogClient )
		self.log_host_key = if loghost.respond_to?( :log_host_key )
				loghost.log_host_key
			else
				loghost.to_sym
			end

		# For objects that also can be instantiated
		include( Loggability::LogClient::InstanceMethods ) if self.is_a?( Class )
	end


end # module Strelka

