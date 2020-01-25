# -*- rspec -*-

require_relative '../../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/log_device/http'


describe Loggability::LogDevice::Http do


	it "can be created with defaults" do
		result = described_class.new

		expect( result ).to be_an_instance_of( described_class )
		expect( result.execution_interval ).to eq( described_class::DEFAULT_EXECUTION_INTERVAL )
		expect( result.send_timeout ).to eq( described_class::DEFAULT_SEND_TIMEOUT )
	end


	it "doesn't start when created" do
		result = described_class.new

		expect( result ).to_not be_running
	end


	

end
