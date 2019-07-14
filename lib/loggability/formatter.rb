# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require 'loggability' unless defined?( Loggability )


### An abstract base class for Loggability log formatters.
class Loggability::Formatter

	##
	# Derivative classes, keyed by name
	singleton_class.attr_reader( :derivatives )
	@derivatives = {}


	### Inherited hook -- add subclasses to the ::derivatives Array.
	def self::inherited( subclass )
		super

		if ( name = subclass.name )
			classname = name.sub( /.*::/, '' ).downcase
		else
			classname = "anonymous_%d" % [ subclass.object_id ]
		end

		Loggability::Formatter.derivatives[ classname.to_sym ] = subclass
	end


	### Create a formatter of the specified +type+, loading it if it hasn't already been
	### loaded.
	def self::create( type, *args )
		require "loggability/formatter/#{type}"
		type = type.to_sym

		if self.derivatives.key?( type )
			return self.derivatives[ type ].new( *args )
		else
			raise LoadError,
				"require of %s formatter succeeded (%p), but it didn't load a class named %p::%s" %
				[ type, self.derivatives, self, type.to_s.capitalize ]
		end
	end


	### Create a log message from the given +severity+, +time+, +progname+, and +message+
	### and return it.
	def call( severity, time, progname, message )
		raise NotImplementedError, "%p doesn't implement required method %s" %
			[ self.class, __method__ ]
	end


end # class Loggability::Formatter

