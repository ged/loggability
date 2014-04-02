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


	let( :formatter ) { described_class.new }


	it "formats messages with ANSI color" do
		expect(
			formatter.call( 'INFO', Time.at(1336286481), nil, "Foom." )
		).to include( "-- \e[37mFoom.\e[0m\n" )
	end

end

