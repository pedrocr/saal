#!/usr/bin/env ruby
$-w = true

require File.dirname(__FILE__)+'/filestore.rb'
require File.dirname(__FILE__)+'/sensors.rb'

module SAAL
  class Daemon
    def initialize(opts={})
      @opts = opts
      @in_sleep = false
      @stop_daemon = false
    end

    def run
      pid = fork do
        $stderr.reopen "/dev/null", "a"
        $stdin.reopen "/dev/null", "a"
        $stdout.reopen "/dev/null", "a"
        @fstore = SAAL::FileStore.new(@opts)
        @sensors = SAAL::Sensors.new(@opts)
        @interval = @opts[:interval] || 5
        @rd, @wr = IO.pipe
        trap_signals
        begin
          t = Time.now.utc.to_i
          @sensors.each do |name, sensor|
            @fstore.write(name, t, sensor.read_uncached)
          end
          select [@rd],[],[],@interval
        end while !@stop_daemon
        @fstore.close
      end
      pid
    end
        
    def trap_signals
      Signal.trap("TERM") {do_exit}
      Signal.trap("INT") {do_exit}
    end
    
    def do_exit
      @stop_daemon = true
      @wr.write(1) 
    end
  end
end
