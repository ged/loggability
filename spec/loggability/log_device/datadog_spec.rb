# -*- rspec -*-
#encoding: utf-8

require 'rspec'

require 'loggability/logger'
require 'loggability/log_device/datadog'


describe Loggability::LogDevice::Datadog do

	let( :logger ) { described_class.new( 'datadog_api_key' ) }


	it "The logger is an instance of Loggability::LogDevice::Datadog" do
		expect( logger ).to be_instance_of( Loggability::LogDevice::Datadog )
	end


	it "It queses up log entries using the ::Thread::Queue data structure " do
		expect( logger.logs_queue ).to be_instance_of( Thread::Queue )
	end


	it "sets up the target correctly" do
		expect( logger.target ).to be_instance_of( ::Net::HTTP::Post )
		expect( logger.target.path ).to eq( '/v1/input/datadog_api_key' )
		expect( logger.target.content_type ).to eq( 'application/json' )
	end


	

end

