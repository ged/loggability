#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'uri'
require 'socket'
require 'net/https'
require 'json'
require 'concurrent'
require 'loggability/logger' unless defined?( Loggability::Logger )

require 'loggability/log_device/http'


# A log device that sends logs to Datadog's HTTP endpoint
# for receiving logs
class Loggability::LogDevice::Datadog < Loggability::LogDevice::Http

	### Datadog's HTTP endpoint URL for sending logs to
	DEFAULT_ENDPOINT = URI( "https://http-intake.logs.datadoghq.com/v1/input" )

	### The max number of messages that can be sent to datadog in a single payload
	MAX_BATCH_SIZE = 480

	### The max size in bytes for a single message.
	### Limiting the message size to 200kB	to leave room for other info such as
	### tags, metadata, etc.
	### DataDog's max size for a single log entry is 256kB
	MAX_MESSAGE_BYTESIZE = 204_800

	### The max size in bytes of all messages in the batch.
	### Limiting the total messages size to 4MB to leave room for other info such as
	### tags, metadata, etc.
	### Datadog's max size for the entire payload is 5MB
	MAX_BATCH_BYTESIZE = 4_194_304

	# Override the default HTTP device options for sending logs to DD
	DEFAULT_OPTIONS = {
		max_batch_size: MAX_BATCH_SIZE,
		max_message_bytesize: MAX_MESSAGE_BYTESIZE,
		max_batch_bytesize: MAX_BATCH_BYTESIZE,
	}


	### Create a new Datadog
	def initialize( api_key, endpoint=DEFAULT_ENDPOINT, options={} )
		if endpoint.is_a?( Hash )
			options = endpoint
			endpoint = DEFAULT_ENDPOINT
		end

		super( endpoint, options )

		@api_key = api_key
		@hostname = Socket.gethostname
	end


	######
	public
	######

	##
	# The name of the current host
	attr_reader :hostname

	##
	# The configured Datadog API key
	attr_reader :api_key


	### Format an individual log +message+ for Datadog.
	def format_log_message( message )
		return {
			hostname: self.hostname,
			message: message
		}.to_json
	end


	### Overridden to add the configured API key to the headers of each request.
	def make_batch_request
		request = super

		request[ 'DD-API-KEY' ] = self.api_key

		return request
	end

end # class Loggability::LogDevice::Datadog
