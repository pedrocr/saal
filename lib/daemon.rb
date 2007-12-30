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
    DEFAULT_PORT = 4500
  
    def initialize(opts={})
      @opts = opts
    end

    def run
      ForkedRunner.run_as_fork do |forked_runner|
        @fstore = SAAL::FileStore.new(@opts)
        @sensors = SAAL::Sensors.new(@opts)
        @interval = @opts[:interval] || 5
        writer = Thread.new {write_sensor_values(forked_runner)}
        server = Thread.new {accept_requests(forked_runner)}
        writer.join
        server.join
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
    
    def accept_requests(fr)
      server = TCPServer.new(@opts[:port] || DEFAULT_PORT)
      begin
        if !fr.stop?
          sock = server.accept_nonblock 
          RequestHandler.new(sock, @fstore, @sensors, fr).run
          sock.close
        end
      rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
        fr.select([server])
      end while !fr.stop?  
    end
  end
  
  class RequestHandler
    def initialize(socket, filestore, sensors, forked_runner)
      @sensors = sensors
      @filestore = filestore
      @socket = socket
      @fr = forked_runner
    end
    
    def run
      handle_command(@socket.readline)
    end
    
    def handle_command(command)
      scommand = command.strip.split(" ")
      case scommand[0]
        when "GET"
          if check_num_args(scommand, 2)
            begin
              time = Time.now.utc.to_i
              value = @sensors.send(scommand[1]).read
              @socket.write("#{time} #{value}\n")
            rescue NoMethodError
              @socket.write("ERROR: No such sensor") 
            end
          end
      end
    end
    
    def check_num_args(command, num)
      @socket.write("ERROR: wrong number of arguments\n") if command.size != num
      command.size == num
    end
  end
end
