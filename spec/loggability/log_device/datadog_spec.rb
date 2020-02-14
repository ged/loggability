# -*- rspec -*-
#encoding: utf-8

require 'securerandom'
require 'rspec'

require 'loggability/logger'
require 'loggability/log_device/datadog'


describe Loggability::LogDevice::Datadog do


	let( :api_key ) { SecureRandom.hex(24) }
	let( :http_client ) { instance_double(Net::HTTP) }


	it "includes the configured API key in request headers" do
		device = described_class.new(
			api_key,
			max_batch_size: 3,
			batch_interval: 0.1,
			executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( http_client ).to receive( :request ) do |request|
			expect( request ).to be_a( Net::HTTP::Post )
			expect( request['Content-type'] ).to match( %r|application/json|i )
			expect( request['DD-API-KEY'] ).to eq( api_key )
		end.at_least( :once )

		device.write( "message data" * 10 )  # 120 bytes
		device.write( "message data" * 100 ) # 1200 bytes
		device.write( "message data" * 85 )  # 1020 bytes
		device.write( "message data" * 86 )  # 1032 bytes

		sleep( 0.1 ) until device.logs_queue.empty?
	end


	it "includes the hostname in individual log messages" do
		device = described_class.new(
			api_key,
			max_batch_size: 3,
			batch_interval: 0.1,
			executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( http_client ).to receive( :request ) do |request|
			expect( request ).to be_a( Net::HTTP::Post )

			data = JSON.parse( request.body )

			expect( data ).to all( be_a Hash )
			expect( data ).to all( include('hostname' => device.hostname) )
		end.at_least( :once )

		device.write( "message data" * 10 )  # 120 bytes
		device.write( "message data" * 100 ) # 1200 bytes
		device.write( "message data" * 85 )  # 1020 bytes
		device.write( "message data" * 86 )  # 1032 bytes

		sleep( 0.1 ) until device.logs_queue.empty?
	end

end

