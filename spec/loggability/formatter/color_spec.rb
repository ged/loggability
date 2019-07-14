# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require_relative '../../helpers'

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

