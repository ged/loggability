# -*- rspec -*-

require_relative '../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/logger'
require 'loggability/formatter'
require 'loggability/formatter/default'


describe Loggability::Logger do

	before( :all ) do
		@original_debug_level = $DEBUG
		$DEBUG = false
	end

	after( :all ) do
		$DEBUG = @original_debug_level
	end


	let( :logger ) { described_class.new }


	it "has a less-verbose inspection format than that of its parent" do
		expect( logger.inspect ).to match( /severity: \S+ formatter: \S+ outputting to: \S+/ )
	end


	it "provides an upgrade constructor for regular Logger objects" do
		regular_logger = ::Logger.new( $stderr )
		newlogger = described_class.from_std_logger( regular_logger )
		expect( newlogger ).to be_a( Loggability::Logger )
		expect( newlogger.logdev.dev ).to be( regular_logger.instance_variable_get(:@logdev).dev )
		expect( Loggability::LOG_LEVELS[newlogger.level] ).to eq( regular_logger.level )
		expect( newlogger.formatter ).to be_a( Loggability::Formatter::Default )
	end


	it "writes to itself at :debug level if appended to" do
		results = []
		logger.level = :debug
		logger.output_to( results )
		logger << "This is an appended message."

		expect( results.first ).to match( /debug.*this is an appended message/i )
	end


	it "supports #write so it can be used with Rack::CommonLogger" do
		results = []
		logger.level = :debug
		logger.output_to( results )
		logger.write( "This is a written message." )

		expect( results.first ).to match( /info.*this is a written message/i )
	end


	it "can return a Hash of its current settings" do
		expect( logger.settings ).to be_a( Hash )
		expect( logger.settings ).to include( :level, :formatter, :logdev )
		expect( logger.settings[:level] ).to eq( logger.level )
		expect( logger.settings[:formatter] ).to eq( logger.formatter )
		expect( logger.settings[:logdev] ).to eq( logger.logdev )
	end


	it "can restore its settings from a Hash" do
		settings = logger.settings

		logger.level = :fatal
		logger.formatter = Loggability::Formatter.create( :html )
		logger.output_to( [] )

		logger.restore_settings( settings )

		expect( logger.level ).to be( settings[:level] )
		expect( logger.formatter ).to be( settings[:formatter] )
		expect( logger.logdev ).to be( settings[:logdev] )
	end


	it "ignores missing keys when restoring its settings from a Hash" do
		settings = logger.settings
		settings.delete( :level )

		logger.level = :fatal
		logger.formatter = Loggability::Formatter.create( :html )
		logger.output_to( [] )

		logger.restore_settings( settings )

		expect( logger.level ).to be( :fatal )
		expect( logger.formatter ).to be( settings[:formatter] )
		expect( logger.logdev ).to be( settings[:logdev] )
	end


	describe "severity level API" do

		it "defaults to :warn level" do
			expect( logger.level ).to eq( :warn )
		end

		it "defaults to :debug level when $DEBUG is true" do
			begin
				$DEBUG = true
				expect( described_class.new.level ).to eq( :debug )
			ensure
				$DEBUG = false
			end
		end

		it "allows its levels to be set with integers like Logger" do
			newlevel = Logger::DEBUG
			$stderr.puts "Setting newlevel to %p" % [ newlevel ]
			logger.level = newlevel
			expect( logger.level ).to eq( :debug )
		end

		it "allows its levels to be set with Symbolic level names" do
			logger.level = :info
			expect( logger.level ).to eq( :info )
		end

		it "allows its levels to be set with Stringish level names" do
			logger.level = 'fatal'
			expect( logger.level ).to eq( :fatal )
		end

	end


	describe "log device API" do

		it "logs to STDERR by default" do
			expect( logger.logdev.dev ).to be( $stderr )
		end

		it "can be told to log to a file" do
			tmpfile = Tempfile.new( 'loggability-device-spec' )
			logger.output_to( tmpfile.path )
			expect( logger.logdev.dev ).to be_a( File )
		end

		it "supports log-rotation arguments for logfiles" do
			tmpfile = Tempfile.new( 'loggability-device-spec' )
			logger.output_to( tmpfile.path, 5, 125000 )
			expect( logger.logdev.dev ).to be_a( File )
			expect( logger.logdev.filename ).to eq( tmpfile.path )
			expect( logger.logdev.instance_variable_get(:@shift_age) ).to eq( 5 )
			expect( logger.logdev.instance_variable_get(:@shift_size) ).to eq( 125000 )
		end

		it "can be told to log to an Array" do
			logmessages = []
			logger.output_to( logmessages )
			expect( logger.logdev ).to be_a( Loggability::Logger::AppendingLogDevice )
			logger.level = :debug
			logger.info( "Something happened." )
			expect( logmessages.size ).to eq(  1  )
			expect( logmessages.first ).to match( /something happened/i )
		end

		it "doesn't re-wrap a Logger::LogDevice" do
			tmpfile = Tempfile.new( 'loggability-device-spec' )
			logger.output_to( tmpfile.path, 5, 125000 )

			original_logdev = logger.logdev
			logger.output_to( original_logdev )

			expect( logger.logdev ).to be( original_logdev )
		end

		it "doesn't re-wrap an AppendingLogDevice" do
			log_array = []
			logger.output_to( log_array )
			logger.output_to( logger.logdev )

			expect( logger.logdev.target ).to be( log_array )
		end

	end


	describe "formatter API" do

		it "logs with the default formatter by default" do
			expect( logger.formatter ).to be_a( Loggability::Formatter::Default )
		end

		it "can be told to use the default formatter explicitly" do
			logger.format_as( :default )
			expect( logger.formatter ).to be_a( Loggability::Formatter::Default )
		end

		it "can be told to use a block as a formatter" do
			logger.format_with do |severity, datetime, progname, msg|
				original_formatter.call(severity, datetime, progname, msg.dump)
			end

			expect( logger.formatter ).to be_a( Proc )
		end

		it "can be told to use the HTML formatter" do
			logger.format_as( :html )
			expect( logger.formatter ).to be_a( Loggability::Formatter::HTML )
		end

		it "supports formatting with ::Logger::Formatter, too" do
			output = []
			logger.output_to( output )
			logger.level = :debug
			logger.formatter = ::Logger::Formatter.new
			logger.debug "This should work."

			expected_format = /D, \[\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d.\d+ #\d+\] DEBUG -- : This should work.\n/
			expect( output.first ).to match( expected_format )
		end

	end


	describe "progname proxy" do

		it "can create a proxy object that will log with the argument object as the 'progname'" do
			messages = []
			logger.output_to( messages )
			logger.level = :debug

			obj = Object.new
			proxy = logger.proxy_for( obj )
			proxy.debug( "A debug message." )
			proxy.info( "An info message." )
			proxy.warn( "A warn message." )
			proxy.error( "An error message." )
			proxy.fatal( "A fatal message." )

			expected_format = /DEBUG \{Object:0x[[:xdigit:]]+\} -- A debug message.\n/i
			expect( messages.first ).to match( expected_format )
		end

		it "has a terse inspection format" do
			object = Object.new
			expect(
				logger.proxy_for( object ).inspect
			).to match( /ObjectNameProxy.* for Object/ )
		end

	end

end

