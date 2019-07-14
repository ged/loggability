# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require_relative '../helpers'

require 'loggability/override'


describe Loggability::Override do

	after( :each ) do
		Loggability.reset
	end


	let!( :override ) { described_class.new }
	let!( :loghost ) do
		Class.new do
			extend Loggability
			log_as :testing
		end
	end
	let!( :another_loghost ) do
		Class.new do
			extend Loggability
			log_as :testing_another
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


	it "can be inspected" do
		expect( override.inspect ).
			to match( %r(
				#<
					#{described_class.name}
					:
					0x\p{Xdigit}+
					\s
					formatter:\s-,\slevel:\s-,\soutput:\s-,\s
					affecting\sall\slog\shosts
				>
			)x )
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

		expect( log.size ).to eq( 1 )
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

		expect( original_destination.size ).to eq(  2  )
		expect( new_destination.size ).to eq(  1  )
	end


	it "can mutate itself to only affect a subset of log hosts" do
		log = []

		Loggability.level = :info
		Loggability.output_to( log )
		Loggability.format_with( :default )

		loghost_override = override.for_logger( another_loghost ).with_level( :debug )

		another_loghost.logger.debug "This shouldn't show up."
		loghost.logger.debug "This also shouldn't show up."
		loghost_override.call do
			loghost.logger.debug "And this also should not show up."
			another_loghost.logger.debug "But this should."
		end
		loghost.logger.debug "This shouldn't show up either."
		another_loghost.logger.debug "And neither should this."

		expect( log.size ).to eq( 1 )
	end


	it "can affect a subset of more than one log host" do
		log = []

		Loggability.level = :info
		Loggability.output_to( log )
		Loggability.format_with( :default )

		loghost_override = override.for_logger( loghost, another_loghost ).with_level( :debug )

		another_loghost.logger.debug "This shouldn't show up."
		loghost.logger.debug "This also shouldn't show up."
		loghost_override.call do
			loghost.logger.debug "Now this one should show up."
			another_loghost.logger.debug "And so should this."
		end
		loghost.logger.debug "This shouldn't show up though."
		another_loghost.logger.debug "And neither should this."

		expect( log.size ).to eq( 2 )
	end


	it "works when mutating log hosts by log clients as well" do
		log = []

		Loggability.level = :info
		Loggability.output_to( log )
		Loggability.format_with( :default )

		logclient = Class.new do
			extend Loggability
			log_to :testing
		end

		loghost_override = override.for_logger( logclient ).with_level( :debug )

		another_loghost.logger.debug "This shouldn't show up."
		loghost.logger.debug "This also shouldn't show up."
		logclient.log.debug "And neither should this."
		loghost_override.call do
			another_loghost.logger.debug "And this also should not show up."
			loghost.logger.debug "But this should since it's using the same logger as the client."
			logclient.log.debug "And this one should too."
		end
		loghost.logger.debug "And now this shouldn't show up."
		another_loghost.logger.debug "And neither should this."
		logclient.log.debug "Nor this."

		expect( log.size ).to eq( 2 )
	end


	it "errors if for_logger is called with no loggers" do
		expect {
			override.for_logger
		}.to raise_error( ArgumentError, /no log hosts given/i )
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

		expect( log.size ).to eq(  3  )
		expect( html_log.size ).to eq(  1  )
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


	it "executes a block passed to a mutator with the mutated override" do
		Loggability.level = :info
		Loggability.format_with( :default )

		log = []
		result = override.formatted_with( :html ).with_level( :debug ).outputting_to( log ) do
			Loggability[ loghost ].debug "Doing it!"
			:did_it
		end

		expect( result ).to eq( :did_it )
		expect( log.size ).to eq(  1  )
		expect( log.first ).to match( /Doing it!/ )
	end

end

