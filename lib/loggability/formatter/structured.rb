# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require 'time'
require 'json'

require 'loggability/formatter' unless defined?( Loggability::Formatter )


# Output logs as JSON.
class Loggability::Formatter::Structured < Loggability::Formatter

	# The version of the format output
	LOG_FORMAT_VERSION = 1


	### Format a message of the specified +severity+ using the given +time+,
	### +progname+, and +message+.
	def call( severity, time, progname, message )
		severity ||= 'DEBUG'
		time ||= Time.now
		entry = {
			'@version' => LOG_FORMAT_VERSION,
			'@timestamp' => time.iso8601( 3 ),
			'level' => severity,
			'progname' => progname,
			'message' => message,
		}

		return JSON.generate( entry )
	end

end # class Loggability::Formatter::Default

