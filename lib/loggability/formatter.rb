#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability' unless defined?( Loggability )


### An abstract base class for Loggability log formatters.
class Loggability::Formatter

	# The default sprintf pattern
	DEFAULT_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'


	##
	# Derivative classes, keyed by name
	class << self; attr_reader :derivatives; end
	@derivatives = {}


	### Inherited hook -- add subclasses to the ::derivatives Array.
	def self::inherited( subclass )
		super
		classname = subclass.name.sub( /.*::/, '' ).downcase.to_sym
		Loggability::Formatter.derivatives[ classname ] = subclass
	end


	### Create a formatter of the specified +type+, loading it if it hasn't already been
	### loaded.
	def self::create( type, *args )
		require "loggability/formatter/#{type}"
		type = type.to_sym

		if self.derivatives.key?( type )
			return self.derivatives[ type ].new( *args )
		else
			raise LoadError,
				"require of %s formatter succeeded (%p), but it didn't load a class named %p::%s" %
				[ type, self.derivatives, self, type.to_s.capitalize ]
		end
	end



	### Initialize a new Loggability::Formatter. The specified +logformat+ should
	### be a sprintf pattern with positional placeholders:
	###
	### [<tt>%1$s</tt>] Time (pre-formatted using strftime with the +datetime_format+)
	### [<tt>%2$d</tt>] Time microseconds
	### [<tt>%3$d</tt>] PID
	### [<tt>%4$s</tt>] Thread ID
	### [<tt>%5$s</tt>] Severity
	### [<tt>%6$s</tt>] Object/Program Name
	### [<tt>%7$s</tt>] Message
	###
	def initialize( logformat, datetime_format=DEFAULT_DATETIME_FORMAT )
		@format          = logformat.dup
		@datetime_format = datetime_format.dup
	end


	######
	public
	######

	# Main log sprintf format
	attr_accessor :format

	# Strftime format for log messages
	attr_accessor :datetime_format


	### Create a log message from the given +severity+, +time+, +progname+, and +message+
	### and return it.
	def call( severity, time, progname, message )
		timeformat = self.datetime_format
		args = [
			time.strftime( timeformat ),                                  # %1$s
			time.usec,                                                    # %2$d
			Process.pid,                                                  # %3$d
			Thread.current == Thread.main ? 'main' : Thread.object_id,    # %4$s
			severity.downcase,                                            # %5$s
			progname,                                                     # %6$s
			self.msg2str(message, severity)                               # %7$s
		]

		return self.format % args
	end


	#########
	protected
	#########

	### Format the specified +msg+ for output to the log.
	def msg2str( msg, severity )
		case msg
		when String
			return msg
		when Exception
			bt = severity == 'DEBUG' ? msg.backtrace.join("\n") : msg.backtrace.first
			return "%p: %s from %s" % [ msg.class, msg.message, bt ]
		else
			return msg.inspect
		end
	end

end # class Loggability::Formatter

