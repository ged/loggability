# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require 'loggability' unless defined?( Loggability )
require 'loggability/formatter' unless defined?( Loggability::Formatter )


# The default log formatter class.
class Loggability::Formatter::Default < Loggability::Formatter

	# The format to output unless debugging is turned on
	FORMAT = "[%1$s.%2$06d %3$d/%4$s] %5$5s {%6$s} -- %7$s\n"

	### Specify the format for the default formatter.
	def initialize( format=FORMAT )
		super
	end

end # class Loggability::Formatter::Default

