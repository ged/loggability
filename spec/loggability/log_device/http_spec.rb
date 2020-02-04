# -*- rspec -*-

require_relative '../../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/log_device/http'


describe Loggability::LogDevice::Http do


	let( :http_client ) { instance_double(Net::HTTP) }


	it "can be created with defaults" do
		result = described_class.new

		expect( result ).to be_an_instance_of( described_class )
		expect( result.batch_interval ).to eq( described_class::DEFAULT_BATCH_INTERVAL )
		expect( result.write_timeout ).to eq( described_class::DEFAULT_WRITE_TIMEOUT )
	end


	it "doesn't start when created" do
		result = described_class.new

		expect( result ).to_not be_running
	end


	it "sends logs when a full batch is ready" do
		device = described_class.new( max_batch_size: 3, executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( http_client ).to receive( :request ) do |request|
			expect( request ).to be_a( Net::HTTP::Post )
			expect( request['Content-type'] ).to match( %r|application/json|i )
			expect( request.body ).to match( /message 1/i )
			expect( request.body ).to match( /message 2/i )
			expect( request.body ).to match( /message 3/i )
		end

		device.write( "Message 1" )
		device.write( "Message 2" )
		device.write( "Message 3" )
		device.write( "Message 4" )

		expect( device.logs_queue ).to have_attributes( length: 1 )
	end


	it "sends logs when enough time has elapsed since the last message" do
		device = described_class.new(
			max_batch_size: 3, batch_interval: 0.1, executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )
		device.start
		device.timer_task.shutdown # Don't let the timer fire

		expect( http_client ).to receive( :request ) do |request|
			expect( request ).to be_a( Net::HTTP::Post )
			expect( request['Content-type'] ).to match( %r|application/json|i )
			expect( request.body ).to match( /message 1/i )
			expect( request.body ).to match( /message 2/i )
		end

		device.write( "Message 1" )

		# Now wait for the batch interval to pass and send another
		sleep device.batch_interval
		expect( device ).to have_batch_ready
		device.write( "Message 2" )

		expect( device.logs_queue ).to have_attributes( length: 0 )
	end


	it "sends logs on the batch interval even when messages aren't arriving" do
		device = described_class.new(
			max_batch_size: 3, batch_interval: 0.1, executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( http_client ).to receive( :request ) do |request|
			expect( request ).to be_a( Net::HTTP::Post )
			expect( request['Content-type'] ).to match( %r|application/json|i )
			expect( request.body ).to match( /message 1/i )
		end

		device.write( "Message 1" )

		# Now wait for the batch interval to pass and send another
		sleep device.batch_interval * 2

		expect( device.logs_queue ).to have_attributes( length: 0 )
	end


	it "limits the batch to the configured size constraints"
	it "limits the batch to the configured bytesize constraints"


end
