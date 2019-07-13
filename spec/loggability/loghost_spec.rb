# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require_relative '../helpers'

require 'loggability/loghost'


describe Loggability::LogHost do


	let( :class_with_loggability ) do
		Class.new { extend Loggability; log_as :loghost_specs }
	end


	it "makes subclasses log clients of itself" do
		subclass = Class.new( class_with_loggability )
		expect( subclass.log ).to be_a( Loggability::Logger::ObjectNameProxy )
		expect( subclass.log.logger ).to eq( class_with_loggability.logger )
	end

end

