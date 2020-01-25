#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

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
	ENDPOINT = "https://http-intake.logs.datadoghq.com"

	### Datadogs API endpoint path for receiving logs
	PATH = "/v1/input/"

	### The max number of messages that can be sent to datadog in a single payload
	MAX_BATCH_SIZE = 480

	### The max size in bytes for a single message.
	### Limiting the message size to 200kB  to leave room for other info such as tags, metadata, etc.
	### DataDog's max size for a single log entry is 256kB
	MAX_MESSAGE_BYTESIZE = 204_800

	### The max size in bytes of all messages in the batch.
	### Limiting the total messages size to 4MB to leave room for other info such as tags, metadata, etc.
	### Datadog's max size for the entire payload is 5MB
	MAX_BATCH_BYTESIZE = 4_194_304


	def initialize( api_key )
		super( ENDPOINT )
		self.target = api_key
		@batched_messages_bytesize = 0
	end


	######
	public
	######

	## the thread-safe array for batching log messages
	attr_reader :logs_queue

	# The target of the log device
	attr_reader :target

	## This the size in bytes of batched messages. It cannot exceed 5MB, Datadogs limit per payload
	attr_accessor :batched_messages_bytesize


	### Batches log messages until it hits the datadog payload/message size limits and
	### then sends the batch to datadog.
	### From: https://docs.datadoghq.com/api/?lang=bash#send-logs-over-http
	###     Maximum content size per payload: 5MB
	###     Maximum size for a single log: 256kB
	###     Maximum array size if sending multiple logs in an array: 500 entries
	def write( msg )
		raise "Log message size cannot exceed %d bytes" % [ MAX_MESSAGE_BYTESIZE ] if msg.bytesize > MAX_MESSAGE_BYTESIZE

		self.batched_messages_bytesize += msg.bytesize

		self.logs_queue.push({
			hostname: Socket.gethostname,
			message: msg
		})

		## send the batch of logs if it is approaching datadog's payload size limits
		if self.logs_queue.size >= MAX_BATCH_SIZE || self.batched_messages_bytesize >= MAX_BATCH_BYTESIZE
			self.send_logs
			self.batched_messages_bytesize = 0
		end
	end


	### Closes the http connection
	def close
		begin
			self.http.finish
		rescue IOError
			## ignore it since http session has not yet started.
		end
	end


	##########
	protected
	##########


	### Sets up the HTTP request object that can send log message to Datadog
	def target=( api_key )
	end

end # class Loggability::LogDevice::Datadog
