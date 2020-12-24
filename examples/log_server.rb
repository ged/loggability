#!/usr/bin/env ruby

require 'sinatra/base'
require 'json'


class LogServer < Sinatra::Base

	set :server, :puma
	set :port, 12775

	post '/v1/logs' do
		r = self.request

		halt 406, "Expected a JSON body!" unless r.media_type == 'application/json'

		logmsgs = JSON.parse( r.body )

		logmsgs.each do |logmsg|
			$stderr.puts "%s [%s] %p" % [ r.ip, Time.now.strftime("%Y/%m/%d %H:%M:%S.%N"), logmsg ]
		end

		return [202, "Accepted"]
	end


end


LogServer.run! if __FILE__ == $0

