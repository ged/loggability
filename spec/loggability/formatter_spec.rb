# -*- rspec -*-

require_relative '../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/logger'
require 'loggability/formatter'
require 'loggability/formatter/default'


describe Loggability::Formatter do

	it "formats messages with the pattern it's constructed with" do
		formatter = Loggability::Formatter.new( '[%5$s] %7$s' )
		result = formatter.call( 'INFO', Time.at(1336286481), nil, 'Foom.' )
		expect( result ).to match(/\[INFO\] Foom./i)
	end

	it "formats exceptions into useful messages" do
		formatter = Loggability::Formatter.new( '[%5$s] %7$s' )
		msg = nil

		begin
			raise ArgumentError, "invalid argument"
		rescue => err
			msg = formatter.call( 'INFO', Time.at(1336286481), nil, err )
		end

		expect( msg ).to match(/\[INFO\] ArgumentError: invalid argument/i)
	end

	it "formats regular objects into useful messages" do
		formatter = Loggability::Formatter.new( '[%5$s] %7$s' )
		result = formatter.call( 'INFO', Time.at(1336286481), nil, Object.new )

		expect( result ).to match(/\[INFO\] #<Object:0x[[:xdigit:]]+>/i)
	end

end

