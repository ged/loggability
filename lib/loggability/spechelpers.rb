# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability' unless defined?( Loggability )

# Some helper functions for testing. Usage:
#
#    RSpec.configure do |c|
#        c.include( Loggability::SpecHelpers )
#    end
#
#    describe MyClass do
#        before( :all ) { setup_logging }
#        after( :all ) { reset_logging }
#
#        # ...
#
#    end
module Loggability::SpecHelpers

	### Reset the logging subsystem to its default state.
	def reset_logging
		Loggability.formatter = nil
		Loggability.output_to( $stderr )
		Loggability.level = :fatal
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	### if HTML_LOGGING is set or TM_FILENAME is set to something containing _spec.rb.
	def setup_logging( level=:fatal )

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			logarray = []
			Thread.current['logger-output'] = logarray
			Loggability.output_to( logarray )
			Loggability.format_as( :html )
			Loggability.level = :debug
		else
			Loggability.level = level
		end
	end


end # Loggability::SpecHelpers

