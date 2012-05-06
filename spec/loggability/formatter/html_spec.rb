# -*- rspec -*-

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent.parent.parent
	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
}

require 'tempfile'
require 'rspec'
require 'spec/lib/helpers'
require 'loggability/logger'
require 'loggability/formatter'
require 'loggability/formatter/html'


describe Loggability::Formatter::HTML do

	subject { described_class.new }

	it "formats messages as HTML" do
		subject.call( 'INFO', Time.at(1336286481), nil, "Foom." ).should =~
			%r{<span class="log-message-text">Foom.</span>}i
	end

	it "formats exceptions into useful messages" do
		msg = nil

		begin
			raise ArgumentError, "invalid argument"
		rescue => err
			msg = subject.call( 'INFO', Time.at(1336286481), nil, err )
		end

		msg.should =~ %r{<span class=\"log-exc\">ArgumentError</span>}i
		msg.should =~ %r{<span class=\"log-exc-message\">invalid argument</span>}i
		msg.should =~ %r{ from <span class=\"log-exc-firstframe\">}i
	end

	it "formats regular objects into useful messages" do
		subject.call( 'INFO', Time.at(1336286481), nil, Object.new ).should =~
			%r{<span class=\"log-message-text\">#&lt;Object:0x\p{XDigit}+&gt;</span>}
	end
end

