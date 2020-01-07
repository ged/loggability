# -*- rspec -*-

require_relative '../helpers'

require 'tempfile'
require 'rspec'

require 'loggability/log_device'
require 'loggability/log_device/datadog'
require 'loggability/log_device/file'
require 'loggability/log_device/appending'


describe Loggability::LogDevice do

	after( :each ) do
		File.unlink( "mylog.log" ) if File.exist?( "mylog.log" )
	end


	it "can parse a config entry and return a Loggability::LogDevice::Datadog instance" do
		target_spec = ' datadog[data_dog_api_key] (color)'

		targets_array = described_class.parse_device_spec( target_spec )
		expect( targets_array ).to be_instance_of( Array )
		expect( targets_array.first ).to be_instance_of( Loggability::LogDevice::Datadog )
	end


	it "can parse a config entry and return a Loggability::LogDevice::File log instance" do
		target_spec = "file[mylog.log]"

		targets_array = described_class.parse_device_spec( target_spec )
		expect( targets_array ).to be_instance_of( Array )
		expect( targets_array.first ).to be_instance_of( Loggability::LogDevice::File )
	end


	it "can parse a config entry and return a Loggability::LogDevice::Appending log instance" do
		targets_array = described_class.parse_device_spec( 'appending' )
		expect( targets_array ).to be_instance_of( Array )
		expect( targets_array.first ).to be_instance_of( Loggability::LogDevice::Appending )
	end

end
