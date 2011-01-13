module SAAL
  class ForkedRunner
    def self.run_as_fork(opts={})
      if opts[:foreground]
        yield ForkedRunner.new
      else
        fork do
          if not opts[:keep_stdin]
            $stderr.reopen "/dev/null", "a"
            $stdin.reopen "/dev/null", "a"
            $stdout.reopen "/dev/null", "a"
          end
          yield ForkedRunner.new
        end
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
      ForkedRunner.run_as_fork(@opts) do |forked_runner|
        @sensors = SAAL::Sensors.new(@opts[:sensorconf], @opts[:dbconf])
        @interval = @opts[:interval] || 60
        begin
          @sensors.each {|sensor| sensor.store_value}
          forked_runner.sleep @interval
        end while !forked_runner.stop?
      end
    end
  end
end
