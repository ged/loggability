# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require 'loggability' unless defined?( Loggability )
require 'loggability/formatter' unless defined?( Loggability::Formatter )


# The default sprintf-based log formatter class.
class Loggability::Formatter::Default < Loggability::Formatter

	# The default sprintf pattern
	DEFAULT_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'

	# The format to output unless debugging is turned on
	FORMAT = "[%1$s.%2$06d %3$d/%4$s] %5$5s {%6$s} -- %7$s\n"

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
	def initialize( logformat=FORMAT, datetime_format=DEFAULT_DATETIME_FORMAT )
		super()

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
			time.strftime( timeformat ),                                       # %1$s
			time.usec,                                                         # %2$d
			Process.pid,                                                       # %3$d
			Thread.current == Thread.main ? 'main' : Thread.current.object_id, # %4$s
			severity.downcase,                                                 # %5$s
			progname,                                                          # %6$s
			self.msg2str(message, severity)                                    # %7$s
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

end # class Loggability::Formatter::Default

