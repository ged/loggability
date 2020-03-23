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


	it "limits messages to the configured byte size constraints" do
		device = described_class.new(
			max_batch_size: 3,
			max_message_bytesize: 1024,
			batch_interval: 0.1,
			executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( http_client ).to receive( :request ) do |request|
			expect( request ).to be_a( Net::HTTP::Post )
			expect( request['Content-type'] ).to match( %r|application/json|i )

			data = JSON.parse( request.body )

			expect( data ).to all( have_attributes(bytesize: a_value <= 1024) )
		end.at_least( :once )

		device.write( "message data" * 10 )  # 120 bytes
		device.write( "message data" * 100 ) # 1200 bytes
		device.write( "message data" * 85 )  # 1020 bytes
		device.write( "message data" * 86 )  # 1032 bytes

		sleep( 0.1 ) until device.logs_queue.empty?
	end


	it "limits the batch to the configured byte size constraints" do
		device = described_class.new(
			max_batch_bytesize: 1024,
			batch_interval: 0.1,
			executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( http_client ).to receive( :request ) do |request|
			expect( request ).to be_a( Net::HTTP::Post )
			expect( request['Content-type'] ).to match( %r|application/json|i )

			expect( request.body.bytesize ).to be <= 1024
		end.at_least( :once )

		20.times { device.write( "message data" * 10 )  } # 120 bytes
		20.times { device.write( "message data" * 100 ) } # 1200 bytes
		20.times { device.write( "message data" * 85 )  } # 1020 bytes
		20.times { device.write( "message data" * 86 )  } # 1032 bytes

		sleep( 0.1 ) until device.logs_queue.empty?
	end


	it "uses an HTTP client for the appropriate host and port" do
		device = described_class.new(
			'http://logs.example.com:12881/v1/log_ingester',
			executor_class: Concurrent::ImmediateExecutor )
		http = device.http_client

		expect( http.address ).to eq( 'logs.example.com' )
		expect( http.port ).to eq( 12881 )
	end


	it "verifies the peer cert if sending to an HTTPS endpoint" do
		device = described_class.new(
			'https://logs.example.com:12881/v1/log_ingester',
			executor_class: Concurrent::ImmediateExecutor )
		http = device.http_client

		expect( http.use_ssl? ).to be_truthy
		expect( http.verify_mode ).to eq( OpenSSL::SSL::VERIFY_PEER )
	end


	it "stops queuing more messages if max queue size is reached" do
		device = described_class.new(
			max_batch_bytesize: 1024,
			batch_interval: 100,
			max_queue_bytesize: 100,
			executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( device ).to receive( :send_logs ).at_least( :once )

		msg = "test message"
		device.write(msg)
		expect( device.logs_queue_bytesize == msg.bytesize )

		hash_msg = { message: "This is a test log message", tags: ["tag1", "tag2"] }
		device.write( hash_msg )
		previous_bytesize = device.logs_queue_bytesize - hash_msg.to_json.bytesize
		expect( device.logs_queue_bytesize ).to eq( hash_msg.to_json.bytesize + previous_bytesize )

		queue_current_bytesize = device.logs_queue_bytesize
		hash_msg = { message: "This is a test log message", tags: ["tag1", "tag2"] }
		device.write( hash_msg )
		expect( device.logs_queue_bytesize ).to eq( queue_current_bytesize )
	end


	it "reduces the queue bytesize once messages are sent" do
		device = described_class.new(
			max_batch_bytesize: 1024,
			batch_interval: 100,
			max_queue_bytesize: 100,
			executor_class: Concurrent::ImmediateExecutor )
		device.instance_variable_set( :@http_client, http_client )

		expect( device ).to receive( :send_logs ).at_least( :once )
		msg = "test message"
		device.write(msg)
		expect( device.logs_queue_bytesize == msg.bytesize )

		msg = "this is just a test message"
		device.write( msg )
		previous_bytesize = device.logs_queue_bytesize - msg.bytesize
		expect( device.logs_queue_bytesize ).to eq( msg.bytesize + previous_bytesize )

		expect { device.get_next_log_payload }.to change { device.logs_queue_bytesize }.to( 0 )
	end

end
