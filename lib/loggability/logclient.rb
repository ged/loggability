# -*- ruby -*-
#encoding: utf-8

require 'loggability' unless defined?( Loggability )

# Methods to install for objects which call +log_to+.
module Loggability::LogClient

	##
	# The key of the log host this client targets
	attr_accessor :log_host_key

	### Return the Loggability::Logger object associated with the log host the
	### client is logging to.
	### :TODO: Use delegation for efficiency.
	def log
		@__log ||= Loggability[ self ].proxy_for( self )
	end


	### Inheritance hook -- set the log host key of subclasses to the same
	### thing as the extended class.
	def inherited( subclass )
		super
		Loggability.log.debug "Setting up subclass %p of %p to log to %p" %
			[ subclass, self, self.log_host_key ]
		subclass.log_host_key = self.log_host_key
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

end # module Loggability::LogClient

