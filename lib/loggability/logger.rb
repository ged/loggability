#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'logger'
require 'loggability' unless defined?( Loggability )
require 'loggability/constants'
require 'loggability/formatter'


# A subclass of Logger that provides additional API for configuring outputters,
# formatters, etc.
class Loggability::Logger < ::Logger
	include Loggability::Constants,
	        Logger::Severity

	# Default log 'device'
	DEFAULT_DEVICE = $stderr

	# Default 'shift age'
	DEFAULT_SHIFT_AGE = 0

	# Default 'shift size'
	DEFAULT_SHIFT_SIZE = 1048576


	# A log device that appends to the object it's constructed with instead of writing
	# to a file descriptor or a file.
	class AppendingLogDevice

		### Create a new AppendingLogDevice that will append content to +array+.
		def initialize( target )
			@target = target
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

	end # class AppendingLogDevice


	# Proxy for the Logger that injects the name of the object it wraps as the 'progname'
	# of each log message.
	class ObjectNameProxy

		### Create a proxy for the given +logger+ that will inject the name of the
		### specified +object+ into the 'progname' of each log message.
		def initialize( logger, object )
			@logger = logger
			@progname = make_progname( object )
		end

		######
		public
		######

		# The Loggability::Logger this proxy is for.
		attr_reader :logger

		# The progname of the object the proxy is for.
		attr_reader :progname


		### Delegate debug messages
		def debug( msg=nil, &block )
			@logger.add( Logger::DEBUG, msg, @progname, &block )
		end

		### Delegate info messages
		def info( msg=nil, &block )
			@logger.add( Logger::INFO, msg, @progname, &block )
		end

		### Delegate warn messages
		def warn( msg=nil, &block )
			@logger.add( Logger::WARN, msg, @progname, &block )
		end

		### Delegate error messages
		def error( msg=nil, &block )
			@logger.add( Logger::ERROR, msg, @progname, &block )
		end

		### Delegate fatal messages
		def fatal( msg=nil, &block )
			@logger.add( Logger::FATAL, msg, @progname, &block )
		end


		### Return a human-readable string representation of the object, suitable for debugging.
		def inspect
			return "#<%p:%#016x for %s>" % [ self.class, self.object_id * 2, @progname ]
		end


		#######
		private
		#######

		### Make a progname for the specified object.
		def make_progname( object )
			case object
			when Class, Module
				object.inspect
			else
				"%p:%#x" % [ object.class, object.object_id * 2 ]
			end
		end


	end # class ObjectNameProxy


	### Return an equivalent Loggability::Logger object for the given +logger+.
	def self::from_std_logger( logger )
		device = logger.instance_variable_get( :@logdev ) or
			raise ArgumentError, "%p doesn't appear to be a Logger (no @logdev)" % [ logger ]

		newlogger = self.new( device.dev )

		newlogger.level     = logger.level
		newlogger.formatter = logger.formatter

		return newlogger
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Logger wrapper that will output to the specified +logdev+.
	def initialize( logdev=DEFAULT_DEVICE, *args )
		super( nil )

		self.level = if $DEBUG then :debug else :warn end
		self.output_to( logdev, *args )

		@created_from = caller( 3 ).first
		@default_formatter = Loggability::Formatter.create( :default )
	end


	######
	public
	######

	##
	# The line that caused this logger to be created.
	attr_reader :created_from


	### Return a human-readable representation of the object suitable for debugging.
	def inspect
		dev = if self.logdev.respond_to?( :dev )
				self.logdev.dev.class
			else
				self.logdev
			end

		return "#<%p:%#x severity: %s, formatter: %s, outputting to: %p>" % [
			self.class,
			self.object_id * 2,
			self.level,
			self.formatter.class.name.sub( /.*::/, '' ).downcase,
			dev,
		]
	end


	### Append operator -- Override Logger's append so log messages always have
	### formatting, and are always appended at :debug level.
	def <<( message )
		unless self.logdev.nil?
			self.add( Logger::DEBUG, message )
		end
	end


	### Rack::CommonLogger compatibility method -- append a +message+ at 'info' level.
	def write( message )
		unless self.logdev.nil?
			self.add( Logger::INFO, message )
		end
	end


	### Return a Hash that contains its settings suitable for restoration via
	### #restore_settings later.
	def settings
		return {
			level:     self.level,
			logdev:    self.logdev,
			formatter: self.formatter,
		}
	end


	### Restore the level, logdev, and formatter from the given +settings+.
	def restore_settings( settings )
		self.level = settings[:level]            if settings[ :level ]
		self.output_to( settings[:logdev] )      if settings[ :logdev ]
		self.format_with( settings[:formatter] ) if settings[ :formatter ]
	end


	#
	# :section: Severity Level
	#

	### Return the logger's level as a Symbol.
	def level
		numeric_level = super
		return LOG_LEVEL_NAMES[ numeric_level ]
	end


	### Set the logger level to +newlevel+, which can be a numeric level (e.g.,
	### Logger::DEBUG, etc.), or a symbolic level (e.g., :debug, :info, etc.)
	def level=( newlevel )
		newlevel = LOG_LEVELS[ newlevel.to_sym ] if
			newlevel.respond_to?( :to_sym ) && LOG_LEVELS.key?( newlevel.to_sym )
		super( newlevel )
	end


	#
	# :section: Output Device
	#

	# The raw log device
	attr_accessor :logdev


	### Change the log device to log to +target+ instead of what it was before. Any additional
	### +args+ are passed to the LogDevice's constructor. In addition to Logger's support for
	### logging to IO objects and files (given a filename in a String), this method can also
	### set up logging to any object that responds to #<<.
	def output_to( target, *args )
		if target.is_a?( Logger::LogDevice ) ||
		   target.is_a?( Loggability::Logger::AppendingLogDevice )
			self.logdev = target
		elsif target.respond_to?( :write ) || target.is_a?( String )
			opts = { :shift_age => args.shift || 0, :shift_size => args.shift || 1048576 }
			self.logdev = Logger::LogDevice.new( target, opts )
		elsif target.respond_to?( :<< )
			self.logdev = AppendingLogDevice.new( target )
		else
			raise ArgumentError, "don't know how to output to %p (a %p)" % [ target, target.class ]
		end
	end
	alias_method :write_to, :output_to


	#
	# :section: Output Formatting API
	#

	### Return the current formatter used to format log messages.
	def formatter
		return ( @formatter || @default_formatter )
	end


	### Format a log message using the current formatter and return it.
	def format_message( severity, datetime, progname, msg )
		self.formatter.call(severity, datetime, progname, msg)
	end


	### Set a new +formatter+ for the logger. If +formatter+ is +nil+ or +:default+, this causes the
	### logger to fall back to its default formatter. If it's a Symbol other than +:default+, it looks
	### for a similarly-named formatter under loggability/formatter/ and uses that. If +formatter+ is
	### an object that responds to #call (e.g., a Proc or a Method object), that object is used directly.
	###
	### Procs and methods should have the method signature: (severity, datetime, progname, msg).
	###
	###     # Load and use the HTML formatter
	###     MyProject.logger.format_with( :html )
	###
	###     # Call self.format_logmsg(...) to format messages
	###     MyProject.logger.format_with( self.method(:format_logmsg) )
	###
	###     # Reset to the default
	###     MyProject.logger.format_with( :default )
	###
	def format_with( formatter=nil, &block ) # :yield: severity, datetime, progname, msg
		formatter ||= block

		if formatter.nil? || formatter == :default
			@formatter = nil

		elsif formatter.respond_to?( :call )
			@formatter = formatter

		elsif formatter.respond_to?( :to_sym )
			@formatter = Loggability::Formatter.create( formatter )

		else
			raise ArgumentError, "don't know what to do with a %p formatter (%p)" %
				[ formatter.class, formatter ]
		end
	end
	alias_method :format_as, :format_with
	alias_method :formatter=, :format_with


	#
	# :section: Progname Proxy
	# Rather than require that the caller provide the 'progname' part of the log message
	# on every call, you can grab a Proxy object for a particular object and Logger combination
	# that will include the object's name with every log message.
	#


	### Create a logging proxy for +object+ that will include its name as the 'progname' of
	### each message.
	def proxy_for( object )
		return ObjectNameProxy.new( self, object )
	end


end # class Loggability::Logger

