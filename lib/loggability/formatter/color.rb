#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability' unless defined?( Loggability )
require 'loggability/formatter' unless defined?( Loggability::Formatter )
require 'loggability/formatter/default'


# ANSI color log formatter. Outputs log messages color-coded by their
# severity if the current terminal appears to support it.
class Loggability::Formatter::Color < Loggability::Formatter::Default

	# ANSI reset
	RESET = "\e[0m"

	# ANSI color escapes keyed by severity
	LEVEL_CODES = {
		:debug => "\e[1;30m", # bold black
		:info  =>  "\e[37m",   # white
		:warn  =>  "\e[1;33m", # bold yellow
		:error => "\e[31m",   # red
		:fatal => "\e[1;31m", # bold red
	}

	# Pattern for matching color terminals
	COLOR_TERMINAL_NAMES = /(?:vt10[03]|xterm(?:-color)?|linux|screen)/i


	### Create a new formatter.
	def initialize( * )
		super
		@color_enabled = COLOR_TERMINAL_NAMES.match( ENV['TERM'] ) ? true : false
	end


	######
	public
	######

	### Format the specified +msg+ for output to the log.
	def msg2str( msg, severity )
		msg = super
		if @color_enabled
			color = severity.downcase.to_sym
			msg = [ LEVEL_CODES[color], msg, RESET ].join( '' )
		end

		return msg
	end

end # class Loggability::Formatter::Color

