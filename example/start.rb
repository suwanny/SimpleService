#!/usr/bin/env ruby
# 
#
require File.dirname(__FILE__) + '/simple'

# Create your service.
service = SimpleService.new

# trap signals to stop the service.
["TERM", "KILL", "INT"].each do |signal|
    Signal.trap(signal) do
        puts "Terminating Service ..."
        service.shutdown
    end
end

# set the document root.
service.document_root = File.dirname(__FILE__) + '/www'

# start the service with the port 8080.
service.start 8080