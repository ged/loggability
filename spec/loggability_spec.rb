# -*- rspec -*-

require_relative 'helpers'

require 'rspec'

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
		expect( described_class.logger ).to be_a( Loggability::Logger )
		expect( described_class.log_hosts ).to include( Loggability::GLOBAL_KEY => Loggability )
	end


	describe "version methods" do
		it "returns a version string if asked" do
			expect( described_class.version_string ).to match( /\w+ [\d.]+/ )
		end

		it "returns a version string with a build number if asked" do
			expect( described_class.version_string(true) ).
				to match(/\w+ [\d.]+ \(build [[:xdigit:]]+\)/)
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
			expect( Loggability.log_hosts ).to include( :testing => @class )
		end

		it "has an associated Loggability::Logger" do
			expect( @class.logger ).to be_a( Loggability::Logger )
		end

		it "has an associated default Loggability::Logger" do
			expect( @class.default_logger ).to be( @class.logger )
		end

		it "registers itself with the Loggability module" do
			expect( Loggability[@class] ).to be( @class.logger )
		end

		it "registers its key with the Loggability module" do
			expect( Loggability[:testing] ).to be( @class.logger )
		end

		it "has a proxy for its logger in its instances" do
			expect( @class.new.log.logger ).to be( @class.logger )
		end

		it "wraps Logger instances assigned as its logger in a Loggability::Logger" do
			logger = ::Logger.new( $stderr )

			@class.logger = logger
			expect( @class.logger ).to be_a( Loggability::Logger )

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
			expect( @class.log.logger ).to be( @loghost.logger )
		end

		it "is associated with its log host's logger through the Loggability module" do
			expect( Loggability[@class] ).to be( @loghost.logger )
		end

		it "has a proxy for its log host's logger available from its instances" do
			obj = @class.new
			expect( obj.log.logger ).to be( @loghost.logger )
		end


		it "is associated with its log host's logger via its instances through the Loggability module" do
			obj = @class.new
			expect( Loggability[obj] ).to be( @loghost.logger )
		end

		it "propagates its log host key to subclasses" do
			subclass = Class.new( @class )
			expect( subclass.log.logger ).to be( @loghost.logger )
			expect( Loggability[subclass] ).to be( @loghost.logger )
		end

		it "raises an exception if asked for a log host that hasn't yet been declared" do
			logged_class = Class.new { extend Loggability; log_to :the_void }
			expect { logged_class.log.logger }.to raise_error( ArgumentError, /no log host/i )
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
			expect( Loggability[@loghost].level ).to be( :warn )
		end

		it "can propagate an outputter to every loghost" do
			Loggability.output_to( $stdout )
			expect( Loggability[@loghost].logdev.dev ).to be( $stdout )
		end

		it "can propagate a formatter to every loghost" do
			Loggability.format_with( :color )
			expect( Loggability[@loghost].formatter ).to be_a( Loggability::Formatter::Color )
		end


		describe "overrideable behaviors" do

			before( :each ) do
				@default_output = []
				Loggability.level = :info
				Loggability.output_to( @default_output )
			end


			it "can temporarily override where Loggability outputs to while executing a block" do
				tmp_output = []

				Loggability[ @loghost ].info "Before the override"
				Loggability.outputting_to( tmp_output ) do
					Loggability[ @loghost ].info "During the override"
				end
				Loggability[ @loghost ].info "After the override"

				expect( @default_output.size ).to eq(  2  )
				expect( tmp_output.size ).to eq(  1  )
			end


			it "can return an object that overrides where Loggability outputs to for any block" do
				tmp_output = []
				with_tmp_logging = Loggability.outputting_to( tmp_output )

				Loggability[ @loghost ].info "Before the overrides"
				with_tmp_logging.call do
					Loggability[ @loghost ].info "During the first override"
				end
				Loggability[ @loghost ].info "Between overrides"
				with_tmp_logging.call do
					Loggability[ @loghost ].info "During the second override"
				end
				Loggability[ @loghost ].info "After the overrides"

				expect( @default_output.size ).to eq(  3  )
				expect( tmp_output.size ).to eq(  2  )
			end


			it "can temporarily override what level Loggability logs at while executing a block" do
				Loggability[ @loghost ].debug "Before the override"
				Loggability.with_level( :debug ) do
					Loggability[ @loghost ].debug "During the override"
				end
				Loggability[ @loghost ].debug "After the override"

				expect( @default_output.size ).to eq(  1  )
			end


			it "can return an object that overrides what level Loggability logs at for any block" do
				with_debug_logging = Loggability.with_level( :debug )

				Loggability[ @loghost ].debug "Before the overrides"
				with_debug_logging.call do
					Loggability[ @loghost ].debug "During the first override"
				end
				Loggability[ @loghost ].debug "Between overrides"
				with_debug_logging.call do
					Loggability[ @loghost ].debug "During the second override"
				end
				Loggability[ @loghost ].debug "After the overrides"

				expect( @default_output.size ).to eq(  2  )
			end


			it "can temporarily override what formatter loggers use while executing a block" do
				Loggability[ @loghost ].info "Before the override"
				Loggability.formatted_with( :html ) do
					Loggability[ @loghost ].info "During the override"
				end
				Loggability[ @loghost ].info "After the override"

				expect( @default_output.size ).to eq(  3  )
				expect( @default_output.grep(/<div/).size ).to eq(  1  )
			end


			it "can return an object that overrides what formatter loggers use for any block" do
				with_html_logging = Loggability.formatted_with( :html )

				Loggability[ @loghost ].info "Before the overrides"
				with_html_logging.call do
					Loggability[ @loghost ].info "During the first override"
				end
				Loggability[ @loghost ].info "Between overrides"
				with_html_logging.call do
					Loggability[ @loghost ].info "During the second override"
				end
				Loggability[ @loghost ].info "After the overrides"

				expect( @default_output.size ).to eq(  5  )
				expect( @default_output.grep(/<div/).size ).to eq(  2  )
			end


		end


	end


	describe "Configurability support", :configurability do

		after( :each ) do
			File.delete( 'spec-error.log' ) if File.exist?( 'spec-error.log' )
		end


		let!( :class1 ) { Class.new {extend Loggability; log_as :class1} }
		let!( :class2 ) { Class.new {extend Loggability; log_as :class2} }


		it "can parse a logging config spec with just a severity" do
			result = Loggability.parse_config_spec( 'debug' )
			expect( result ).to eq([ 'debug', nil, nil ])
		end

		it "can parse a logging config spec with a severity and STDERR" do
			result = Loggability.parse_config_spec( 'fatal STDERR' )
			expect( result ).to eq([ 'fatal', nil, $stderr ])
		end

		it "can parse a logging config spec with a severity and STDOUT" do
			result = Loggability.parse_config_spec( 'error STDOUT' )
			expect( result ).to eq([ 'error', nil, $stdout ])
		end

		it "can parse a logging config spec with a severity and a path" do
			result = Loggability.parse_config_spec( 'debug /var/log/debug.log' )
			expect( result ).to eq([ 'debug', nil, '/var/log/debug.log' ])
		end

		it "can parse a logging config spec with a severity and a path with escaped spaces" do
			result = Loggability.parse_config_spec( 'debug /store/media/Stormcrow\\ and\\ Raven/dl.log' )
			expect( result ).to	eq([ 'debug', nil, '/store/media/Stormcrow\\ and\\ Raven/dl.log' ])
		end

		it "can parse a logging config spec with a severity and a formatter" do
			result = Loggability.parse_config_spec( 'warn (html)' )
			expect( result ).to eq([ 'warn', 'html', nil ])
		end

		it "can parse a logging config spec with a severity, a path, and a formatter" do
			result = Loggability.parse_config_spec( 'info /usr/local/www/htdocs/log.html (html)' )
			expect( result ).to eq([ 'info', 'html', '/usr/local/www/htdocs/log.html' ])
		end

		it "can configure loghosts via its ::configure method" do
			config = {'class1' => 'debug (html)', 'class2' => 'error spec-error.log'}
			Loggability.configure( config )

			expect( Loggability[class1].level ).to be( :debug )
			expect( Loggability[class1].formatter ).to be_a( Loggability::Formatter::HTML )
			expect( Loggability[class2].level ).to be( :error )
			expect( Loggability[class2].logdev.dev ).to be_a( File )
			expect( Loggability[class2].logdev.dev.path ).to eq( 'spec-error.log' )
		end

		it "can configure loghosts with a Configurability::Config object" do
			configsource = (<<-"END_CONFIG").gsub( /^\t{3}/, '' )
			---
			logging:
			  class1: debug (html)
			  class2: error spec-error.log

			END_CONFIG

			config = Configurability::Config.new( configsource )
			config.install

			expect( Loggability[class1].level ).to be( :debug )
			expect( Loggability[class1].formatter ).to be_a( Loggability::Formatter::HTML )
			expect( Loggability[class2].level ).to be( :error )
			expect( Loggability[class2].logdev.dev ).to be_a( File )
			expect( Loggability[class2].logdev.dev.path ).to eq( 'spec-error.log' )
		end

		it "can configure all loghosts with a config key of __default__" do
			Loggability.configure( '__default__' => 'debug STDERR (html)' )

			loggers = Loggability.log_hosts.values.map( &:logger )
			expect( loggers.map(&:level) ).to all_be( :debug )
			expect( loggers.map(&:formatter) ).to all_be_a( Loggability::Formatter::HTML )
			expect( loggers.map(&:logdev).map(&:dev) ).to all_be( $stderr )
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

