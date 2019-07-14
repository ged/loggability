# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

require_relative '../helpers'

require 'loggability/formatter'


describe Loggability::Formatter do

	before( :all ) do
		@actual_derivatives = described_class.derivatives.dup
	end

	after( :all ) do
		described_class.derivatives.replace( @actual_derivatives )
	end


	describe "concrete subclasses" do

		class Test < described_class
		end


		it "must implement #call" do
			expect {
				Test.new.call( 'INFO', Time.now, nil, "A message." )
			}.to raise_error( /doesn't implement required method/i )
		end


		it "is tracked by the base class" do
			expect( described_class.derivatives ).to include( test: Test )
		end


		it "is tracked if its anonymous" do
			subclass = Class.new( described_class )
			expect( described_class.derivatives.values ).to include( subclass )
		end


		it "can be loaded by name" do
			expect( described_class ).to receive( :require ).
				with( "loggability/formatter/test" )

			expect( described_class.create(:test) ).to be_an_instance_of( Test )
		end


		it "raises a LoadError if loading doesn't work" do
			expect( described_class ).to receive( :require ).
				with( "loggability/formatter/circus" )

			expect {
				described_class.create( :circus )
			}.to raise_error( LoadError, /didn't load a class/i )
		end


	end

end

