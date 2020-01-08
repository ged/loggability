# -*- rspec -*-

require_relative '../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/http_log_device'


describe Loggability::HttpLogDevice do

	let( :ENDPOINT ) { 'https://localhost' }
	let( :http_log_device ) do
		described_class.new( self.ENDPOINT )
	end

	context "initializing it" do
		it "creates an instance of executor" do
			executor = http_log_device.executor
			expect( executor ).to be_an_instance_of( Concurrent::SingleThreadExecutor )

			expect( executor.fallback_policy ).to eq( :abort )
			expect( executor.auto_terminate? ).to be_truthy
		end


		it "sets up http client with the correct uri" do
			http = http_log_device.http
			expect( http.address ).to eq( 'localhost' )
			expect( http.port ).to eq( 443 )
			expect( http.verify_mode ).to eq( OpenSSL::SSL::VERIFY_PEER )
			expect( http.use_ssl? ).to be_truthy
		end


		it "sets up a timertask with correct params" do
			timertask = http_log_device.timer_task

			expect( timertask.execution_interval ).to eq( 60 )
			expect( timertask.timeout_interval ).to eq( 5 )
			expect( timertask.running? ).to be_truthy
		end

	end

	it "can stop the executor" do
		expect{ http_log_device.send( :stop ) }.to change{ http_log_device.executor.running? }.to be_falsey
	end


	it "can shutdown the timertask" do
		timertask = http_log_device.timer_task

		expect { http_log_device.send( :shutdown ) }.to change { timertask.running? }.to be_falsey
	end


	it "raises an error when sending a message" do
		expect{ http_log_device.send( :send_logs ) }.to raise_error( /Subclass must implement this method/i )
	end

end
