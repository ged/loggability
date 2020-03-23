#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'socket'
require 'uri'
require 'net/https'
require 'json'
require 'concurrent'
require 'loggability/logger' unless defined?( Loggability::Logger )

require 'loggability/log_device'

# This is the a generalized class that allows its subclasses to send log
# messages to HTTP endpoints asynchronously on a separate thread.
class Loggability::LogDevice::Http < Loggability::LogDevice

	# The default HTTP endpoint URL to send logs to
	DEFAULT_ENDPOINT = "http://localhost:12775/v1/logs"

	# The default maximum number of messages that can be sent to the server in a single payload
	DEFAULT_MAX_BATCH_SIZE = 100

	# The default max size in bytes for a single message.
	DEFAULT_MAX_MESSAGE_BYTESIZE = 2 * 16

	# The default number of seconds between batches
	DEFAULT_BATCH_INTERVAL = 60

	# The default number of seconds to wait for data to be written before timing out
	DEFAULT_WRITE_TIMEOUT = 15

	# The default Executor class to use for asynchronous tasks
	DEFAULT_EXECUTOR_CLASS = Concurrent::SingleThreadExecutor

	# The default for the maximum bytesize of the queue (1 GB)
	DEFAULT_MAX_QUEUE_BYTESIZE = ( 2 ** 10 ) * ( 2 ** 10 ) * ( 2 ** 10 )

	# The default options for new instances
	DEFAULT_OPTIONS = {
		execution_interval: DEFAULT_BATCH_INTERVAL,
		write_timeout: DEFAULT_WRITE_TIMEOUT,
		max_batch_size: DEFAULT_MAX_BATCH_SIZE,
		max_message_bytesize: DEFAULT_MAX_MESSAGE_BYTESIZE,
		executor_class: DEFAULT_EXECUTOR_CLASS,
	}


	### Initialize the HTTP log device to send to the specified +endpoint+ with the
	### given +options+. Valid options are:
	###
	### [:batch_interval]
	###   Maximum number of seconds between batches
	### [:write_timeout]
	###   How many seconds to wait for data to be written while sending a batch
	### [:max_batch_size]
	###   The maximum number of messages that can be in a single batch
	### [:max_batch_bytesize]
	###   The maximum number of bytes that can be in the payload of a single batch
	### [:max_message_bytesize]
	###   The maximum number of bytes that can be in a single message
	### [:executor_class]
	###   The Concurrent executor class to use for asynchronous tasks.
	def initialize( endpoint=DEFAULT_ENDPOINT, opts={} )
		if endpoint.is_a?( Hash )
			opts = endpoint
			endpoint = DEFAULT_ENDPOINT
		end

		opts = DEFAULT_OPTIONS.merge( opts )

		@endpoint             = URI( endpoint ).freeze
		@logs_queue           = Queue.new

		@logs_queue_bytesize  = 0
		@max_queue_bytesize   = opts[:max_queue_bytesize] || DEFAULT_MAX_QUEUE_BYTESIZE
		@batch_interval       = opts[:batch_interval] || DEFAULT_BATCH_INTERVAL
		@write_timeout        = opts[:write_timeout] || DEFAULT_WRITE_TIMEOUT
		@max_batch_size       = opts[:max_batch_size] || DEFAULT_MAX_BATCH_SIZE
		@max_message_bytesize = opts[:max_message_bytesize] || DEFAULT_MAX_MESSAGE_BYTESIZE
		@executor_class       = opts[:executor_class] || DEFAULT_EXECUTOR_CLASS

		@max_batch_bytesize   = opts[:max_batch_bytesize] || @max_batch_size * @max_message_bytesize
		@last_send_time       = Concurrent.monotonic_time
	end


	######
	public
	######

	##
	# The single thread pool executor
	attr_reader :executor

	##
	# The URI of the endpoint to send messages to
	attr_reader :endpoint

	##
	# The Queue that contains any log messages which have not yet been sent to the
	# logging service.
	attr_reader :logs_queue

	##
	# The max bytesize of the queue. Will not queue more messages if this threshold is hit
	attr_reader :max_queue_bytesize

	##
	# The size of +logs_queue+ in bytes
	attr_accessor :logs_queue_bytesize

	##
	# The monotonic clock time when the last batch of logs were sent
	attr_accessor :last_send_time

	##
	# Number of seconds after the task completes before the task is performed again.
	attr_reader :batch_interval

	##
	# How many seconds to wait for data to be written while sending a batch
	attr_reader :write_timeout

	##
	# The maximum number of messages to post at one time
	attr_reader :max_batch_size

	##
	# The maximum number of bytes of a single message to include in a batch
	attr_reader :max_message_bytesize

	##
	# The maximum number of bytes that will be included in a single POST
	attr_reader :max_batch_bytesize

	##
	# The Concurrent executor class to use for asynchronous tasks
	attr_reader :executor_class

	##
	# The timer task thread
	attr_reader :timer_task


	### LogDevice API -- write a message to the HTTP device.
	def write( message )
		self.start unless self.running?
		if message.is_a?( Hash )
			message_size = message.to_json.bytesize
		else
			message_size = message.bytesize
		end
		return if ( self.logs_queue_bytesize + message_size ) >= self.max_queue_bytesize
		self.logs_queue_bytesize += message_size
		self.logs_queue.enq( message )
		self.send_logs
	end


	### LogDevice API -- stop the batch thread and close the http connection
	def close
		self.stop
		self.http_client.finish
	rescue IOError
		# ignore it since http session has not yet started.
	end


	### Starts a thread pool with a single thread.
	def start
		self.start_executor
		self.start_timer_task
	end


	### Returns +true+ if the device has started sending messages to the logging endpoint.
	def running?
		return self.executor&.running?
	end


	### Shutdown the executor, which is a pool of single thread
	### waits 3 seconds for shutdown to complete
	def stop
		return unless self.running?

		self.timer_task.shutdown if self.timer_task&.running?
		self.executor.shutdown

		unless self.executor.wait_for_termination( 3 )
			self.executor.halt
			self.executor.wait_for_termination( 3 )
		end
	end


	### Start the background thread that sends messages.
	def start_executor
		@executor = self.executor_class.new
		@executor.auto_terminate = true unless @executor.serialized?
	end


	### Create a timer task that calls that sends logs at regular interval
	def start_timer_task
		@timer_task = Concurrent::TimerTask.execute( execution_interval: self.batch_interval ) do
			self.send_logs
		end
	end


	### Sends a batch of log messages to the logging service. This executes inside
	### the sending thread.
	def send_logs
		self.executor.post do
			if self.batch_ready?
				# p "Batch ready; sending."
				request = self.make_batch_request
				request.body = self.get_next_log_payload

				# p "Sending request", request

				self.http_client.request( request ) do |res|
					p( res ) if $DEBUG
				end

				self.last_send_time = Concurrent.monotonic_time
			else
				# p "Batch not ready yet."
			end
		end
	end


	### Returns +true+ if a batch of logs is ready to be sent.
	def batch_ready?
		seconds_since_last_send = Concurrent.monotonic_time - self.last_send_time

		return self.logs_queue.size >= self.max_batch_size ||
			seconds_since_last_send >= self.batch_interval
	end
	alias_method :has_batch_ready?, :batch_ready?


	### Returns a new HTTP request (a subclass of Net::HTTPRequest) suitable for
	### sending the next batch of logs to the service. Defaults to a POST of JSON data. This
	### executes inside the sending thread.
	def make_batch_request
		request = Net::HTTP::Post.new( self.endpoint.path )
		request[ 'Content-Type' ] = 'application/json'

		return request
	end


	### Dequeue pending log messages to send to the service and return them as a
	### suitably-encoded String. The default is a JSON Array. This executes inside
	### the sending thread.
	def get_next_log_payload
		buf = []
		count = 0
		bytes = 0

		# Be conservative so as not to overflow
		max_size = self.max_batch_bytesize - self.max_message_bytesize - 2 # for the outer Array

		while count < self.max_batch_size && bytes < max_size && !self.logs_queue.empty?
			message = self.logs_queue.deq
			formatted_message = self.format_log_message( message )
			self.logs_queue_bytesize -= message.bytesize

			count += 1
			bytes += formatted_message.bytesize + 3 # comma and delimiters

			buf << formatted_message
		end

		return '[' + buf.join(',') + ']'
	end


	### Returns the given +message+ in whatever format individual log messages are
	### expected to be in by the service. The default just returns the stringified
	### +message+. This executes inside the sending thread.
	def format_log_message( message )
		return message.to_s[ 0 ... self.max_message_bytesize ].dump
	end


	### sets up a configured http object ready to instantiate connections
	def http_client
		return @http_client ||= begin
			uri = URI( self.endpoint )

			http = Net::HTTP.new( uri.host, uri.port )
			http.write_timeout = self.write_timeout

			if uri.scheme == 'https'
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			end

			http
		end
	end


end # class Loggability::LogDevice::Http

