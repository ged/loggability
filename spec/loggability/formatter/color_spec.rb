# -*- rspec -*-
#encoding: utf-8

require_relative '../../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/logger'
require 'loggability/formatter'
require 'loggability/formatter/color'


describe Loggability::Formatter::Color do

	before( :all ) do
		@original_term = ENV['TERM']
		ENV['TERM'] = 'xterm-color'
	end

	after( :all ) do
		ENV['TERM'] = @original_term
	end

	before( :each ) do
		@formatter = described_class.new
	end

	it "formats messages with ANSI color" do
		@formatter.call( 'INFO', Time.at(1336286481), nil, "Foom." ).
			should include( "-- \e[37mFoom.\e[0m\n" )
	end

end

