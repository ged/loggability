# -*- ruby -*-
#encoding: utf-8

require 'monitor'
require 'loggability' unless defined?( Loggability )


# A class which encapsulates the logic and data of temporarily overriding one or
# more aspects of logging for the execution of one or more blocks of code.
#
# It's not meant to be used directly, but via one of the override aggregate methods
# on Loggability:
#
# * Loggability.with_level
# * Loggability.outputting_to
# * Loggability.formatted_with
#
class Loggability::Override
	include MonitorMixin


	### Set up an Override with its logging level set to +newlevel+. If called with
	### a block, call #call immediately on the Override with the block and return
	### the result of that instead.
	def self::with_level( new_level, &block )
		return self.new( level: new_level, &block )
	end


	### Set up an Override with its logging output set to +new_destination+. If called with
	### a block, call #call immediately on the Override with the block and return
	### the result of that instead.
	def self::outputting_to( new_destination, &block )
		return self.new( logdev: new_destination, &block )
	end


	### Set up an Override with its logging formatter set to +formatter+. If called with
	### a block, call #call immediately on the Override with the block and return
	### the result of that instead.
	def self::formatted_with( new_formatter, &block )
		return self.new( formatter: new_formatter, &block )
	end


	### Create a new Override with the specified +settings+ that will be applied
	### during a call to #call, and then reverted when #call returns. Valid +settings+
	### are:
	###
	### [:level]
	###   Set the level of all Loggers to the value.
	### [:logdev]
	###   Set the destination log device of all Loggers to the value.
	### [:formatter]
	###   Set the formatter for all Loggers to the value (a Loggability::Formatter).
	###
	def initialize( settings={} )
		super()

		@settings = settings
		@overridden_settings = {}
	end


	### Copy constructor -- make copies of the internal data structures
	### when duplicated.
	def initialize_copy( original )
		@settings = original.settings.dup
		@overridden_settings = {}
	end


	######
	public
	######

	# The Override's settings Hash (the settings that will be applied during
	# an overridden #call).
	attr_reader :settings

	# The original settings preserved by the Override during a call to #call,
	# keyed by the logger they belong to.
	attr_reader :overridden_settings


	### Call the provided block with configured overrides applied, and then restore
	### the previous settings before control is returned.
	def call
		self.apply_overrides
		yield
	ensure
		self.restore_overridden_settings
	end


	#
	# Mutator Methods
	#

	### Return a clone of the receiving Override with its logging level
	### set to +newlevel+.
	def with_level( new_level, &block )
		return self.clone_with( level: new_level, &block )
	end


	### Return a clone of the receiving Override with its logging output
	### set to +new_destination+.
	def outputting_to( new_destination, &block )
		return self.clone_with( logdev: new_destination, &block )
	end


	### Return a clone of the receiving Override with its logging formatter
	### set to +formatter+.
	def formatted_with( new_formatter, &block )
		return self.clone_with( formatter: new_formatter, &block )
	end


	### Return the object as a human-readable string suitable for debugging.
	def inspect
		return "#<%p:%#016x formatter: %s, level: %s, output: %s>" % [
			self.class,
			self.object_id * 2,
			self.settings[:formatter] || '-',
			self.settings[:level] || '-',
			self.settings[:logdev] ? self.settings[:logdev].class : '-',
		]
	end


	#########
	protected
	#########

	### Return a clone that has been modified with the specified +new_settings+.
	def clone_with( new_settings, &block )
		newobj = self.dup
		newobj.settings.merge!( new_settings )

		if block
			return newobj.call( &block )
		else
			return newobj
		end
	end


	### Apply any configured overrides to all loggers.
	def apply_overrides
		self.synchronize do
			raise LocalJumpError, "can't be called re-entrantly" unless
				@overridden_settings.empty?
			@overridden_settings = self.gather_current_settings
		end

		Loggability.log_hosts.each do |key, host|
			host.logger.restore_settings( self.settings )
		end
	end


	### Return a Hash of Loggers with the settings they currently have.
	def gather_current_settings
		return Loggability.log_hosts.values.each_with_object( {} ) do |host, hash|
			hash[ host ] = host.logger.settings
		end
	end


	### Restore the last settings saved by #apply_overrides to their corresponding
	### loggers.
	def restore_overridden_settings
		@overridden_settings.each do |host, settings|
			host.logger.restore_settings( settings )
		end
		@overridden_settings.clear
	end

end # class Loggability::Override