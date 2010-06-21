#!/usr/bin/env ruby
$-w = true

module SAAL
  class ForkedRunner
    def self.run_as_fork(opts={})
      fork do
        if not opts[:keep_stdin]
          $stderr.reopen "/dev/null", "a"
          $stdin.reopen "/dev/null", "a"
          $stdout.reopen "/dev/null", "a"
        end
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
      select([],[],[],time)
    end
    
    def select(read, write=[], err=[], time=nil)
      if time
        Kernel.select(read+[@rd],write,err,time)
      else
        Kernel.select(read+[@rd],write,err)
      end
    end
  end

  class Daemon
    def initialize(opts={})
      @opts = opts
    end

    def run
      ForkedRunner.run_as_fork do |forked_runner|
        @dbstore = SAAL::DBStore.new(@opts[:db])
        @sensors = SAAL::Sensors.new(@opts[:sensors])
        @interval = @opts[:interval] || 60
        begin
          time = Time.now.utc.to_i
          @sensors.each {|name, s| @dbstore.write(name, time, s.read_uncached)}
          forked_runner.sleep @interval
        end while !forked_runner.stop?
        @dbstore.close
      end
    end
  end
end
