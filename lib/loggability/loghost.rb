# -*- ruby -*-
#encoding: utf-8

require 'loggability' unless defined?( Loggability )

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
module Loggability::LogHost

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


	### Register subclasses of log hosts as their own log hosts.
	def inherited( subclass )
		super
		Loggability.register_loghost( subclass )
	end

end # module Loggability::LogHost


