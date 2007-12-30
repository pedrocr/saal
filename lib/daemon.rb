#!/usr/bin/env ruby
$-w = true

require File.dirname(__FILE__)+'/filestore.rb'
require File.dirname(__FILE__)+'/sensors.rb'

module SAAL
  class ForkedRunner
    def self.run_as_fork
      fork do
        $stderr.reopen "/dev/null", "a"
        $stdin.reopen "/dev/null", "a"
        $stdout.reopen "/dev/null", "a"
        yield ForkedRunner.new
      end
    end
    
    def initialize
      @rd, @wr = IO.pipe
      @stop = false
      trap_signals
    end
    
    def trap_signals
      Signal.trap("TERM") {do_exit}
      Signal.trap("INT") {do_exit}
    end
    
    def do_exit
      @stop = true
      @wr.write(1) 
    end
    
    def stop?
      @stop
    end
    
    def sleep(time)
      select [@rd],[],[],time
    end
  end

  class Daemon
    def initialize(opts={})
      @opts = opts
      @stop_daemon = false
      @fstore = SAAL::FileStore.new(@opts)
      @sensors = SAAL::Sensors.new(@opts)
      @interval = @opts[:interval] || 5
    end

    def run
      ForkedRunner.run_as_fork do |forked_runner|
        writer = Thread.new {write_sensor_values(forked_runner)}
        writer.join
        @fstore.close
      end
    end

    private
   
    def write_sensor_values(forked_runner)
      begin
        t = Time.now.utc.to_i
        @sensors.each do |name, sensor|
          @fstore.write(name, t, sensor.read_uncached)
        end
        forked_runner.sleep @interval
      end while !forked_runner.stop?
    end
  end
end
