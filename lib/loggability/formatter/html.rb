#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability' unless defined?( Loggability )
require 'loggability/formatter' unless defined?( Loggability::Formatter )


# The default log formatter class.
class Loggability::Formatter::HTML < Loggability::Formatter

	# The default HTML fragment that'll be used as the template for each log message.
	HTML_LOG_FORMAT = %q{
	<div class="log-message %5$s-log-message">
		<span class="log-time">%1$s.%2$06d</span>
		[
			<span class="log-pid">%3$d</span>
			/
			<span class="log-tid">%4$s</span>
		]
		<span class="log-level">%5$s</span>
		:
		<span class="log-name">%6$s</span>
		<span class="log-message-text">%7$s</span>
	</div>
	}.gsub( /[\t\n]/, ' ' )

	# The format for dumping exceptions
	HTML_EXCEPTION_FORMAT = %Q{
		<span class="log-exc">%1$p</span>:
		<span class="log-exc-message">%2$s</span>
		  from <span class="log-exc-firstframe">%3$s</span>
	}.gsub( /[\t\n]/, ' ' )


	### Override the logging formats with ones that generate HTML fragments
	def initialize( format=HTML_LOG_FORMAT ) # :notnew:
		super
	end


	### Format the +message+; Overridden to escape the +progname+.
	def call( severity, time, progname, message )
		super( severity, time, escape_html(progname), message )
	end


	#########
	protected
	#########

	### Format the specified +object+ for output to the log.
	def msg2str( object, severity )
		case object
		when String
			return escape_html( object )
		when Exception
			return HTML_EXCEPTION_FORMAT % [
				object.class,
				escape_html(object.message),
				escape_html(object.backtrace.first)
			]
		else
			return escape_html(object.inspect)
		end
	end


	#######
	private
	#######

	### Escape any HTML special characters in +string+.
	def escape_html( string )
		return string unless string.respond_to?( :gsub )
		return string.
			gsub( '&', '&amp;' ).
			gsub( '<', '&lt;'  ).
			gsub( '>', '&gt;'  )
	end

end # class Loggability::Formatter::Default

