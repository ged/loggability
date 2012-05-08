#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'logger'
require 'loggability' unless defined?( Loggability )


module Loggability::Constants

	# Log level names and their Logger constant equivalents
	LOG_LEVELS = {
		:debug => Logger::DEBUG,
		:info  => Logger::INFO,
		:warn  => Logger::WARN,
		:error => Logger::ERROR,
		:fatal => Logger::FATAL,
	}.freeze

	# Logger levels -> names
	LOG_LEVEL_NAMES = LOG_LEVELS.invert.freeze


end # module Loggability::Constants


