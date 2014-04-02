#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

# SimpleCov test coverage reporting; enable this using the :coverage rake task
if ENV['COVERAGE']
	$stderr.puts "\n\n>>> Enabling coverage report.\n\n"
	require 'simplecov'
	SimpleCov.start do
		add_filter 'spec'
	end
end

begin
	require 'configurability'
rescue LoadError
end

require 'loggability'
require 'loggability/spechelpers'


# Helpers specific to Loggability specs
module SpecHelpers

    ### An object identity matcher for collections.
	class AllBeMatcher

		def initialize( expected )
			@expected = expected
		end

		def matches?( collection )
			@collection = collection
			return collection.all? {|obj| obj.equal?(@expected) }
		end

		def description
			"to all be %p" % [ @expected ]
		end

		def failure_message
			"but they were: %p" % [ @collection ]
		end

	end # class AllBeMatcher


	### An object kind matcher for collections
	class AllBeAMatcher

		def initialize( expected_class )
			@expected_class = expected_class
		end

		def matches?( collection )
			@collection = collection
			return collection.all? {|obj| obj.is_a?(@expected_class) }
		end

		def description
			"to all be a %p" % [ @expected_class ]
		end

		def failure_message
			unmatched = @collection.find {|obj| !obj.is_a?(@expected_class) }
			"but (at least) one was not. It was a %p (%s)" % [
				unmatched.class,
				unmatched.class.ancestors.map(&:inspect).join(' < '),
			]
		end

	end # class AllBeAMatcher


	###############
	module_function
	###############

	### Return true if the actual value includes the specified +objects+.
	def all_be( expected_object )
		AllBeMatcher.new( expected_object )
	end

	### Returns +true+ if every object in the collection inherits from the +expected_class+.
	def all_be_a( expected_class )
		AllBeAMatcher.new( expected_class )
	end

end # module SpecHelpers


### Mock with RSpec
RSpec.configure do |c|
	c.run_all_when_everything_filtered = true
	c.filter_run :focus
	c.order = 'random'
	c.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	c.include( SpecHelpers )
	c.include( Loggability::SpecHelpers )
	c.filter_run_excluding( :configurability ) unless defined?( Configurability )

end

