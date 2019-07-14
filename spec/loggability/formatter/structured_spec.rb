# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require_relative '../../helpers'

require 'loggability/formatter/structured'


describe Loggability::Formatter::Structured do

	before( :each ) do
		ENV['TZ'] = 'UTC'
	end


	it "outputs a stream of JSON objects" do
		expect(
			subject.call('INFO', Time.at(1336286481), nil, "Foom.")
		).to eq(
			%q|{"@version":1,"@timestamp":"2012-05-06T06:41:21.000+00:00"| +
			%q|,"level":"INFO","progname":null,"message":"Foom."}|
		)
	end


	it "includes a time even if called without one" do
		Timecop.freeze( Time.at(1563114765.123) ) do
			expect(
				subject.call('WARN', nil, nil, "Right.")
			).to match( %r(
				\{
					"@version":1,
					"@timestamp":"2019-07-14T14:32:45\.\d{3}\+00:00",
					"level":"WARN",
					"progname":null,
					"message":"Right\."
				\}
			)x )
		end
	end


	it "defaults to DEBUG severity" do
		Timecop.freeze( Time.at(1563114765.123) ) do
			expect(
				subject.call(nil, nil, nil, "Crane.")
			).to match( %r(
				\{
					"@version":1,
					"@timestamp":"2019-07-14T14:32:45\.\d{3}\+00:00",
					"level":"DEBUG",
					"progname":null,
					"message":"Crane\."
				\}
			)x )
		end
	end

end

