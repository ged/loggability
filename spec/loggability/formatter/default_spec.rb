# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require_relative '../../helpers'

require 'loggability/formatter/default'


describe Loggability::Formatter::Default do

	it "formats messages with the pattern it's constructed with" do
		formatter = described_class.new( '[%5$s] %7$s' )
		result = formatter.call( 'INFO', Time.at(1336286481), nil, 'Foom.' )
		expect( result ).to match(/\[INFO\] Foom./i)
	end


	it "formats exceptions into useful messages" do
		formatter = described_class.new( '[%5$s] %7$s' )
		msg = nil

		begin
			raise ArgumentError, "invalid argument"
		rescue => err
			msg = formatter.call( 'INFO', Time.at(1336286481), nil, err )
		end

		expect( msg ).to match(/\[INFO\] ArgumentError: invalid argument/i)
	end


	it "formats regular objects into useful messages" do
		formatter = described_class.new( '[%5$s] %7$s' )
		result = formatter.call( 'INFO', Time.at(1336286481), nil, Object.new )

		expect( result ).to match(/\[INFO\] #<Object:0x[[:xdigit:]]+>/i)
	end


	it "includes the thread ID if logging from a thread other than the main thread" do
		formatter = described_class.new( '%4$d' )
		thr = Thread.new do
			formatter.call( 'INFO', Time.now, nil, 'Foom.' )
		end
		expect( thr.value ).to eq( thr.object_id.to_s )
	end

end

