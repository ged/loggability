# -*- rspec -*-
#encoding: utf-8

require 'tempfile'
require 'rspec'

require 'loggability/logger'
require 'loggability/log_device/file'


describe Loggability::LogDevice::File do

	let( :logfile ) { Tempfile.new( 'test.log' ) }
	let( :logger ) { described_class.new( logfile.path ) }


	it "The logger is an instance of Loggability::LogDevice::File" do
		expect( logger ).to be_instance_of( Loggability::LogDevice::File )
	end


	it "The log device is delegated to Ruby's built-in log device" do
		expect( logger.target ).to be_instance_of( ::Logger::LogDevice )
	end

end

