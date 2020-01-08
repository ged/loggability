# -*- rspec -*-
#encoding: utf-8

require 'rspec'

require 'loggability/logger'
require 'loggability/log_device/appending'


describe Loggability::LogDevice::Appending do

	let ( :logger ) { described_class.new( [] ) }


	it "The target is an array" do
		expect( logger.target ).to be_instance_of( Array )
	end


	it "can append to the array" do
		logger.write("log message one")
		logger.write("log message two")
		expect( logger.target.size ).to eq( 2 )
	end

end

