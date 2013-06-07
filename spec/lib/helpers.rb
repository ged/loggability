#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

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

require 'loggability' unless defined?( Loggability )
require 'loggability/spechelpers'


### Mock with RSpec
RSpec.configure do |c|
	c.mock_with( :rspec )
	c.treat_symbols_as_metadata_keys_with_true_values = true

	c.include( Loggability::SpecHelpers )
	c.filter_run_excluding( :configurability ) unless defined?( Configurability )
end

