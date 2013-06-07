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

	before( :each ) do
		setup_logging( :fatal )
	end

	after( :each ) do
		reset_logging()
	end

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


	context "installed in a class as a log host" do

		before( :each ) do
			@class = Class.new do
				extend Loggability
				log_as :testing
			end
		end

		after( :each ) do
			Loggability.clear_loghosts
		end


		it "is included in the list of log hosts" do
			Loggability.log_hosts.should include( :testing => @class )
		end

		it "has an associated Loggability::Logger" do
			@class.logger.should be_a( Loggability::Logger )
		end

		it "has an associated default Loggability::Logger" do
			@class.default_logger.should be( @class.logger )
		end

		it "registers itself with the Loggability module" do
			Loggability[ @class ].should be( @class.logger )
		end

		it "registers its key with the Loggability module" do
			Loggability[ :testing ].should be( @class.logger )
		end

		it "has a proxy for its logger in its instances" do
			@class.new.log.logger.should be( @class.logger )
		end

		it "wraps Logger instances assigned as its logger in a Loggability::Logger" do
			logger = ::Logger.new( $stderr )

			@class.logger = logger
			@class.logger.should be_a( Loggability::Logger )

			@class.log.debug "This shouldn't raise."
		end

	end

	context "installed in a class as a logging client" do

		before( :each ) do
			@loghost = Module.new do
				extend Loggability
				log_as :testing
			end

			@class = Class.new do
				extend Loggability
				log_to :testing
			end
		end

		after( :each ) do
			Loggability.clear_loghosts
		end


		it "has a proxy for its log host's logger" do
			@class.log.logger.should be( @loghost.logger )
		end

		it "is associated with its log host's logger through the Loggability module" do
			Loggability[ @class ].should be( @loghost.logger )
		end

		it "has a proxy for its log host's logger available from its instances" do
			obj = @class.new
			obj.log.logger.should be( @loghost.logger )
		end


		it "is associated with its log host's logger via its instances through the Loggability module" do
			obj = @class.new
			Loggability[ obj ].should be( @loghost.logger )
		end

		it "propagates its log host key to subclasses" do
			subclass = Class.new( @class )
			subclass.log.logger.should be( @loghost.logger )
			Loggability[ subclass ].should be( @loghost.logger )
		end

	end


	context "aggregate methods" do

		before( :each ) do
			Loggability.clear_loghosts
			@loghost = Class.new do
				extend Loggability
				log_as :testing
			end
		end


		it "can propagate a logging level to every loghost" do
			Loggability.level = :warn
			Loggability[ @loghost ].level.should == :warn
		end

		it "can propagate an outputter to every loghost" do
			Loggability.output_to( $stdout )
			Loggability[ @loghost ].logdev.dev.should be( $stdout )
		end

		it "can propagate a formatter to every loghost" do
			Loggability.format_with( :color )
			Loggability[ @loghost ].formatter.should be_a( Loggability::Formatter::Color )
		end

	end


	describe "Configurability support", :configurability do

		after( :each ) do
			File.delete( 'spec-error.log' ) if File.exist?( 'spec-error.log' )
		end

		it "can parse a logging config spec with just a severity" do
			Loggability.parse_config_spec( 'debug' ).should == [ 'debug', nil, nil ]
		end

		it "can parse a logging config spec with a severity and STDERR" do
			Loggability.parse_config_spec( 'fatal STDERR' ).should == [ 'fatal', nil, $stderr ]
		end

		it "can parse a logging config spec with a severity and STDOUT" do
			Loggability.parse_config_spec( 'error STDOUT' ).should == [ 'error', nil, $stdout ]
		end

		it "can parse a logging config spec with a severity and a path" do
			Loggability.parse_config_spec( 'debug /var/log/debug.log' ).
				should == [ 'debug', nil, '/var/log/debug.log' ]
		end

		it "can parse a logging config spec with a severity and a path with escaped spaces" do
			Loggability.parse_config_spec( 'debug /store/media/Stormcrow\\ and\\ Raven/dl.log' ).
				should == [ 'debug', nil, '/store/media/Stormcrow\\ and\\ Raven/dl.log' ]
		end

		it "can parse a logging config spec with a severity and a formatter" do
			Loggability.parse_config_spec( 'warn (html)' ).
				should == [ 'warn', 'html', nil ]
		end

		it "can parse a logging config spec with a severity, a path, and a formatter" do
			Loggability.parse_config_spec( 'info /usr/local/www/htdocs/log.html (html)' ).
				should == [ 'info', 'html', '/usr/local/www/htdocs/log.html' ]
		end

		it "can configure loghosts via its ::configure method" do
			class1 = Class.new { extend Loggability; log_as :class1 }
			class2 = Class.new { extend Loggability; log_as :class2 }

			config = {'class1' => 'debug (html)', 'class2' => 'error spec-error.log'}
			Loggability.configure( config )

			Loggability[ class1 ].level.should == :debug
			Loggability[ class1 ].formatter.should be_a( Loggability::Formatter::HTML )
			Loggability[ class2 ].level.should == :error
			Loggability[ class2 ].logdev.dev.should be_a( File )
			Loggability[ class2 ].logdev.dev.path.should == 'spec-error.log'
		end

		it "can configure loghosts with a Configurability::Config object" do
			class1 = Class.new { extend Loggability; log_as :class1 }
			class2 = Class.new { extend Loggability; log_as :class2 }

			configsource = (<<-"END_CONFIG").gsub( /^\t{3}/, '' )
			---
			logging:
			  class1: debug (html)
			  class2: error spec-error.log

			END_CONFIG

			config = Configurability::Config.new( configsource )
			config.install

			Loggability[ class1 ].level.should == :debug
			Loggability[ class1 ].formatter.should be_a( Loggability::Formatter::HTML )
			Loggability[ class2 ].level.should == :error
			Loggability[ class2 ].logdev.dev.should be_a( File )
			Loggability[ class2 ].logdev.dev.path.should == 'spec-error.log'
		end

		it "can configure all loghosts with a config key of __default__" do
			Loggability.configure( '__default__' => 'debug STDERR (html)' )

			all_loggers = Loggability.log_hosts.values.map( &:logger )
			all_loggers.all? {|lh| lh.level == :debug }.should be_true()
			all_loggers.all? {|lh| lh.formatter.class == Loggability::Formatter::HTML }.should be_true()
			all_loggers.all? {|lh| lh.logdev.dev.should == $stderr }.should be_true()
		end

		it "raises an error if configured with a logspec with an invalid severity" do
			expect {
				Loggability.configure( 'class1' => 'awesome /var/log/awesome.log' )
			}.to raise_error( ArgumentError, /couldn't parse/i )
		end

		it "raises an error if configured with a logspec with an malformed filename" do
			expect {
				Loggability.configure( 'class1' => 'info Kitchen!!' )
			}.to raise_error( ArgumentError, /couldn't parse/i )
		end

		it "raises an error if configured with a bogus formatter" do
			expect {
				Loggability.configure( 'class1' => 'debug (mindwaves)' )
			}.to raise_error( LoadError, /cannot load such file/i )
		end

	end

end

