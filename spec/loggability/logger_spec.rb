# -*- rspec -*-

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent
	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
}

require 'tempfile'
require 'rspec'
require 'spec/lib/helpers'
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


	before( :each ) do
		@logger = described_class.new
	end


	it "has a less-verbose inspection format than that of its parent" do
		@logger.inspect.should =~ /severity: \S+ formatter: \S+ outputting to: \S+/
	end

	describe "severity level API" do

		it "defaults to :warn level" do
			@logger.level.should == :warn
		end

		it "defaults to :debug level when $DEBUG is true" do
			begin
				$DEBUG = true
				described_class.new.level.should == :debug
			ensure
				$DEBUG = false
			end
		end

		it "allows its levels to be set with integers like Logger" do
			newlevel = Logger::DEBUG
			$stderr.puts "Setting newlevel to %p" % [ newlevel ]
			@logger.level = newlevel
			@logger.level.should == :debug
		end

		it "allows its levels to be set with Symbolic level names" do
			@logger.level = :info
			@logger.level.should == :info
		end

		it "allows its levels to be set with Stringish level names" do
			@logger.level = 'fatal'
			@logger.level.should == :fatal
		end

	end


	describe "log device API" do

		it "logs to STDERR by default" do
			@logger.logdev.dev.should be( $stderr )
		end

		it "can be told to log to a file" do
			tmpfile = Tempfile.new( 'loggability-device-spec' )
			@logger.output_to( tmpfile.path )
			@logger.logdev.dev.should be_a( File )
		end

		it "supports log-rotation arguments for logfiles" do
			tmpfile = Tempfile.new( 'loggability-device-spec' )
			@logger.output_to( tmpfile.path, 5, 125000 )
			@logger.logdev.dev.should be_a( File )
			@logger.logdev.filename.should == tmpfile.path
			@logger.logdev.instance_variable_get( :@shift_age ).should == 5
			@logger.logdev.instance_variable_get( :@shift_size ).should == 125000
		end

		it "can be told to log to an Array" do
			logmessages = []
			@logger.output_to( logmessages )
			@logger.logdev.should be_a( Loggability::Logger::AppendingLogDevice )
			@logger.level = :debug
			@logger.info( "Something happened." )
			logmessages.should have( 1 ).member
			logmessages.first.should =~ /something happened/i
		end

	end


	describe "formatter API" do

		it "logs with the default formatter by default" do
			@logger.formatter.should be_a( Loggability::Formatter::Default )
		end

		it "can be told to use the default formatter explicitly" do
			@logger.format_as( :default )
			@logger.formatter.should be_a( Loggability::Formatter::Default )
		end

		it "can be told to use a block as a formatter" do
			@logger.format_with do |severity, datetime, progname, msg|
				original_formatter.call(severity, datetime, progname, msg.dump)
			end

			@logger.formatter.should be_a( Proc )
		end

		it "can be told to use the HTML formatter" do
			@logger.format_as( :html )
			@logger.formatter.should be_a( Loggability::Formatter::HTML )
		end

	end


	describe "progname proxy" do

		it "can create a proxy object that will log with the argument object as the 'progname'" do
			messages = []
			@logger.output_to( messages )
			@logger.level = :debug

			obj = Object.new
			proxy = @logger.proxy_for( obj )
			proxy.debug( "A debug message." )
			proxy.info( "An info message." )
			proxy.warn( "A warn message." )
			proxy.error( "An error message." )
			proxy.fatal( "A fatal message." )

			messages.first.should =~ /DEBUG \{Object:0x[[:xdigit:]]+\} -- A debug message.\n/i
		end

		it "has a terse inspection format" do
			object = Object.new
			@logger.proxy_for( object ).inspect.
				should =~ /ObjectNameProxy.* for Object/
		end

	end

end

