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


describe Loggability::Formatter do

	it "loads plugins out of loggability/formatter" do
		Loggability::Formatter.derivative_dirs.should == ['loggability/formatter']
	end


	it "formats messages with the pattern it's constructed with" do
		formatter = Loggability::Formatter.new( '[%5$s] %7$s' )
		formatter.call( 'INFO', Time.at(1336286481), nil, 'Foom.' ).should =~
			/\[INFO\] Foom./
	end

	it "formats exceptions into useful messages" do
		formatter = Loggability::Formatter.new( '[%5$s] %7$s' )
		msg = nil

		begin
			raise ArgumentError, "invalid argument"
		rescue => err
			msg = formatter.call( 'INFO', Time.at(1336286481), nil, err )
		end

		msg.should =~ /\[INFO\] ArgumentError: invalid argument/i
	end

	it "formats regular objects into useful messages" do
		formatter = Loggability::Formatter.new( '[%5$s] %7$s' )
		formatter.call( 'INFO', Time.at(1336286481), nil, Object.new ).should =~
			/\[INFO\] #<Object:0x[[:xdigit:]]+>/i
	end

end

