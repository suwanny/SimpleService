require 'webrick'

class Service
    # New attributes for the REST APIs.
    attr_accessor :document_root
    
    def initialize
        @interval = 1.0
        @resolution = 0.001
        @start_time = Time.now 
        @__stop_flag = false
        
        # New attributes for the REST APIs.
        @apis = []
        @api_server = nil
        @document_root = nil
    end
    
    def start port=nil
        # Update the start-time
        @start_time = Time.now 
        
        # Start API Server.
        start_api port if port
        
        # run loop
        loop do
            break if @__stop_flag 
            
            # process the job
            t_start = Time.now
            process
            elapsed = Time.now - t_start
            @logger.info "process took #{elapsed} seconds." if @logger
            
            if elapsed > @interval
                if @logger
                    @logger.warn "Bummer: Job is bigger than Interval.. #{elapsed}"
                else
                    warn "Bummer: Job is bigger than Interval.. #{elapsed}"
                end
                next
            end

            # apply some compensation. 
            compensation = (Time.now - @start_time) % @interval
            sleeping_interval = @interval - compensation
            sleeping_interval += @interval if sleeping_interval < @resolution
            sleep sleeping_interval
        end
    end
    
    def process
        raise NotImplementedError
    end
    
    def reset_start_time time = Time.now
        @start_time = time
    end
    
    def stop
        @__stop_flag = true
    end
    
    # New Methods for the REST APIs.
    def shutdown
        warn "Shutdown Service...."
        stop
        # stop the api_server
        @api_server.shutdown if @api_server
    end
    
    def mount mount, proc
        @apis << {:mount => mount, :proc => proc}
    end
    
    def mount_method mount, method
        warn "MountMethod #{mount} with #{method}"
        proc = Proc.new { |req, resp|
            params = {}
            if req.query_string
                arr1 = req.query_string.split("&")
                arr1.each do |param|
                    arr2 = param.split("=", 2)
                    next unless arr2.size == 2
                    params[arr2[0]] = arr2[1]
                end
            end
            
            resp['Content-Type'] = "application/json"
            resp.body = send(method, params)
        }
        @apis << {:mount => mount, :proc => proc}
    end
    
    def start_api port
        config = {:Port => port}
        config.update(:DocumentRoot => @document_root) if @document_root
        
        # Create WEBrick server.
        @api_server = WEBrick::HTTPServer.new(config)
        
        # Register APIs.
        @apis.each do |api|
            next unless api[:mount].is_a? String
            next unless api[:proc].is_a? Proc
            @api_server.mount_proc(api[:mount], api[:proc])
        end
        
        Thread.new {
            @api_server.start
        }
    end
end


