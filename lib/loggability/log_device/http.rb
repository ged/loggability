#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'socket'
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

	# The max number of messages that can be sent to the server in a single payload
	MAX_BATCH_SIZE = 100

	# The max size in bytes for a single message.
	MAX_MESSAGE_BYTESIZE = 2 * 16

	# The max size in bytes of all messages in the batch.
	MAX_BATCH_BYTESIZE = MAX_MESSAGE_BYTESIZE * MAX_BATCH_SIZE

	# The default number of seconds between batches
	DEFAULT_EXECUTION_INTERVAL = 60

	# The default number of seconds to wait for the send to complete before timing
	# out.
	DEFAULT_SEND_TIMEOUT = 5

	# The default options for new instances
	DEFAULT_OPTIONS = {
		execution_interval: DEFAULT_EXECUTION_INTERVAL,
		send_timeout: DEFAULT_SEND_TIMEOUT,
	}



	### Initialize the HTTP log device to send to the specified +endpoint+ with the
	### given +options+. Valid options are:
	###
	### [:execution_interval]
	###   How many seconds between sending batches of queued messages.
	### [:send_timeout]
	###   How many seconds to wait for a batch to complete sending
	def initialize( endpoint=DEFAULT_ENDPOINT, opts={} )
		opts = DEFAULT_OPTIONS.merge( opts )

		@endpoint           = endpoint.freeze
		@logs_queue         = Queue.new

		@execution_interval = opts[:execution_interval] || DEFAULT_EXECUTION_INTERVAL
		@send_timeout       = opts[:send_timeout] || DEFAULT_SEND_TIMEOUT
		@executor           = nil
		@timer_task         = nil

		@http_client        = nil
	end


	######
	public
	######

	##
	# The single thread pool executor
	attr_reader :executor

	##
	# The URL of the endpoint to send messages to
	attr_writer :endpoint

	##
	# The Queue that contains any log messages which have not yet been sent to the
	# logging service.
	attr_reader :logs_queue

	##
	# Number of seconds after the task completes before the task is performed again.
	attr_reader :execution_interval

	##
	# Number of seconds the task can run before it is considered to have failed.
	attr_reader :send_timeout

	##
	# The timer task thread
	attr_reader :timer_task


	### Sends a batch of log messages asynchronously to the logging service.
	def send_logs
		return if self.logs_queue.empty? || !self.running?

		# Do the actual sending asynchronously on a separate thread
		self.executor.post do
			request = self.make_batch_request
			request.body = self.get_next_log_payload

			self.http.request( request ) do |res|
				p( res ) if $DEBUG
			end
		end
	end


	### Returns a new HTTP request (a subclass of Net::HTTPRequest) suitable for
	### sending the next batch of logs to the service. Defaults to a POST of JSON data.
	def make_batch_request
		request = Net::HTTP::Post.new( self.endpoint.path )
		request[ 'Content-Type' ] = 'application/json'

		return request
	end


	### Dequeue pending log messages to send to the service and return them as a
	### suitably-encoded String. The default is a JSON Array. This executes inside
	### the sending thread.
	def get_next_log_payload
		buf = String.new( encoding: 'utf-8' )
		count = 0
		bytes = 0

		# Be conservative so as not to overflow
		max_size = MAX_BATCH_BYTESIZE - MAX_MESSAGE_BYTESIZE - 2 # for the outer Array

		while count < MAX_BATCH_SIZE && bytes < max_size && !self.logs_queue.empty?
			formatted_message = self.format_log_message( self.logs_queue.pop )

			count += 1
			bytes += formatted_message.bytesize

			buf << formatted_message
		end

		return buf
	end


	### Returns the given +message+ in whatever format individual log messages are
	### expected to be in by the service. The default just returns the stringified
	### +message+. This executes inside the sending thread.
	def format_log_message( message )
		return message.to_s[ 0 ... MAX_MESSAGE_BYTESIZE ]
	end


	### sets up a configured http object ready to instantiate connections
	def http
		return @http ||= begin
			uri = URI.parse( self.endpoint )

			http = Net::HTTP.new( uri.host, uri.port )

			if uri.scheme == 'https'
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			end

			http
		end
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


	### Closes the http connection
	def close
		self.http.finish
	rescue IOError
		# ignore it since http session has not yet started.
	end


	### Start the background thread that sends messages.
	def start_executor
		@executor = Concurrent::SingleThreadExecutor.new
		@executor.auto_terminate = true
	end


	### Create a timer task that calls that sends logs at regular interval
	def start_timer_task
		@timer_task = Concurrent::TimerTask.execute(
			execution_interval: self.execution_interval,
			&self.method(:send_logs) )
	end


end # class Loggability::LogDevice::Http

