# -*- rspec -*-

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'loggability'
require 'loggability/logger'

describe Loggability do

	it "is itself a log host for the global logger" do
		described_class.logger.should be_a( Loggability::Logger )
		described_class.log_hosts.should include( Loggability::GLOBAL_KEY => Loggability )
	end


	describe "version methods" do
		it "returns a version string if asked" do
			described_class.version_string.should =~ /\w+ [\d.]+/
		end

		it "returns a version string with a build number if asked" do
			described_class.version_string(true).should =~ /\w+ [\d.]+ \(build [[:xdigit:]]+\)/
		end
	end


	context "installed in a class" do

		before( :each ) do
			@class = Class.new { extend Loggability }
		end

		after( :each ) do
			Loggability.clear_loghosts
		end


		it "allows it to be designated as a log host" do
			@class.log_as( :testing )
			Loggability.log_hosts.should include( :testing => @class )
			@class.logger.should be_a( Loggability::Logger )
			@class.default_logger.should be( @class.logger )
		end

		it "allows it to designate itself as a logging client" do
			origin = Class.new do
				extend Loggability
				log_as :testing
			end
			@class.log_to( :testing )
			@class.log.logger.should be( origin.logger )

			@class.new.log.logger.should be( origin.logger )
		end

	end


	context "aggregate methods" do

		it "propagate some setting methods to every Logger" do
			origin = Class.new do
				extend Loggability
				log_as :testing
			end
			Loggability.level = :warn
			Loggability.output_to( $stdout )
			Loggability.format_with( :color )

			Loggability[ origin ].level.should == :warn
			Loggability[ origin ].logdev.dev.should be( $stdout )
			Loggability[ origin ].formatter.class.should == Loggability::Formatter::Color
		end

	end

end

