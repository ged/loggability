#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'socket'
require 'net/https'
require 'json'
require 'concurrent'
require 'loggability/logger' unless defined?( Loggability::Logger )

require 'loggability/log_device'

### This is the a generalized class that allows its subclasses to send
### log messages to HTTP endpoints asynchronously on a separate thread.
class Loggability::HttpLogDevice < Loggability::LogDevice

	def initialize( endpoint, opts={} )
		@execution_interval = opts[:execution_interval] || 60
		@timeout_interval = opts[:timeout_interval] || 5
		self.http = endpoint
		self.start_executor
		self.start_timertask
	end


	######
	public
	######

	## The single thread pool executor
	attr_reader :executor

	## The http client for making http requests to datadog
	attr_reader :http

	### Number of seconds after the task completes before the task is performed again.
	attr_reader :execution_interval

	### Number of seconds the task can run before it is considered to have failed.
	attr_reader :timeout_interval

	### The timer task thread
	attr_reader :timer_task


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


	###
	### sends log messages asynchronously to logging service' http endpoint
	def send_logs
		raise "Subclass must implement this method"
	end


	### sets up a configured http object ready to instantiate connections
	def http=( endpoint )
		uri = URI.parse( endpoint )
		@http = Net::HTTP.new( uri.host, uri.port )
		@http.use_ssl = true
		@http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	end


	### Starts a thread pool with a single thread.
	def start_executor
		### +fallback_policy+ is the policy for handling new tasks that are received
		### when the queue size has reached `max_queue` or the executor has shut down
		@executor = Concurrent::SingleThreadExecutor.new( fallback_policy: :abort )

		# auto-terminate the executor when the application exits.
		@executor.auto_terminate = true
	end

	### Shutdown the executor, which is a pool of single thread
	### waits 3 seconds for shutdown to complete
	def stop
		return if !self.executor || self.executor.shuttingdown? || self.executor.shutdown?

		self.executor.shutdown
		unless self.executor.wait_for_termination( 3 )
			self.executor.halt
			self.executor.wait_for_termination( 3 )
		end
	end


	### Create a timer task that calls that sends logs at regular interval
	def start_timertask
		@timer_task = Concurrent::TimerTask.new(
			execution_interval: self.execution_interval,
			timeout_interval: self.timeout_interval,
			run_now: true
		) do
			self.send_logs
		end

		@timer_task.execute
	end


	### Shut down the executor, gracefully the first time it's called, then
	### just kill it if it is called again.
	def shutdown
		self.timer_task.shutdown if self.timer_task.running?
		if self.timer_task.shuttingdown?
			self.timer_task.kill
		else
			self.timer_task.shutdown || self.timer_task.kill
		end
	end


end
