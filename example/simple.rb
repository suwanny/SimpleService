require 'rubygems'
require 'json'
require File.dirname(__FILE__) + '/../lib/service'

class SimpleService < Service
    def initialize
        super()
        @name = "Simple Service."
        register_apis
    end
    
    # Main Loop. (This will be called every one second.)
    def process
        # puts "SimpleService run...#{Time.now.to_f}"
    end
    
    # Create your REST APIs by using Proc.
    def register_apis
        mount_method "/version", :version
    end
    
    # Very simple API.
    def version params
        warn "From version: #{params.inspect}"
        JSON.generate({:version => "0.1.0", :name => @name })
    end
end

