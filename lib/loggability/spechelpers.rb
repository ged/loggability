# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability' unless defined?( Loggability )

# Some helper functions for testing. Usage:
#
#    # in spec_helpers.rb
#    RSpec.configure do |c|
#      c.include( Loggability::SpecHelpers )
#    end
#
#    # in my_class_spec.rb; set logging level to :error
#    describe MyClass, log: :error do
#
#      # Except for this example, which logs at :debug
#      it "does something", log: :debug do
#        # anything the spec does here will be logged at :debug
#      end
#
#      it "does something else" do
#        # but this will use the :error level from the 'describe'
#      end
#
#    end
#
module Loggability::SpecHelpers

	### Inclusion callback -- install some hooks that set up logging
	### for RSpec specs.
	def self::included( context )
		context.around( :each ) do |example|
			if level = (example.metadata[:log] || example.metadata[:logging])
				Loggability.with_level( level, &example )
			else
				example.run
			end
		end

		context.before( :all ) do
			setup_logging()
		end

		context.after( :all ) do
			reset_logging()
		end

		super
	end


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

