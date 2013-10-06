# -*- rspec -*-

require_relative '../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/logger'
require 'loggability/override'


describe Loggability::Override do

	after( :each ) do
		Loggability.clear_loghosts
	end


	let!( :override ) { described_class.new }
	let!( :loghost ) do
		Class.new do
			extend Loggability
			log_as :testing
		end
	end


	it "doesn't override anything by default" do
		previous_level = Loggability[ loghost ].level
		override.call do
			expect( Loggability[ loghost ].level ).to be( previous_level )
		end
	end


	it "raises an error when #called re-entrantly" do
		override.call do
			expect { override.call {} }.to raise_error( LocalJumpError )
		end
	end


	it "can mutate itself into a variant that modifies the logging level" do
		log = []

		Loggability.level = :fatal
		Loggability.output_to( log )
		Loggability.format_with( :default )

		level_override = override.with_level( :debug )

		loghost.logger.debug "This shouldn't show up."
		level_override.call do
			loghost.logger.debug "But this should."
		end
		loghost.logger.debug "This shouldn't either."

		expect( log ).to have( 1 ).log_entry
	end


	it "has a constructor delegator for its level mutator" do
		override = described_class.with_level( :debug )
		expect( override.settings ).to eq({ level: :debug })
	end


	it "can mutate itself into a variant that modifies where output goes" do
		original_destination = []
		new_destination      = []
		output_override      = override.outputting_to( new_destination )

		Loggability.level = :debug
		Loggability.output_to( original_destination )
		Loggability.format_with( :default )

		loghost.logger.debug "This should be output to the original destination"
		output_override.call do
			loghost.logger.debug "This should be output to the overridden destination"
		end
		loghost.logger.debug "This should be output to the original destination"

		expect( original_destination ).to have( 2 ).log_entries
		expect( new_destination ).to have( 1 ).log_entry
	end


	it "has a constructor delegator for its output mutator" do
		log = []
		override = described_class.outputting_to( log )
		expect( override.settings ).to eq({ logdev: log })
	end


	it "can mutate itself into a variant that formats output differently" do
		log = []
		Loggability.level = :debug
		Loggability.output_to( log )
		Loggability.format_with( :default )

		format_override = override.formatted_with( :html )

		loghost.logger.debug "This should be in the default format"
		format_override.call do
			loghost.logger.debug "This should be in the color format"
		end
		loghost.logger.debug "This should be in the default format again"

		html_log = log.grep( /<div/ )

		expect( log ).to have( 3 ).entries
		expect( html_log ).to have( 1 ).entry
	end


	it "has a constructor delegator for its format mutator" do
		override = described_class.formatted_with( :color )
		expect( override.settings ).to eq({ formatter: :color })
	end


	it "has additive mutators" do
		override = described_class.
			formatted_with( :color ).
			with_level( :debug ).
			outputting_to( $stdout )

		expect( override.settings[:formatter] ).to be( :color )
		expect( override.settings[:logdev] ).to be( $stdout )
		expect( override.settings[:level] ).to be( :debug )
	end

end

