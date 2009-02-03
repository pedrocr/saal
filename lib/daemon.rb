#!/usr/bin/env ruby
$-w = true

require File.dirname(__FILE__)+'/filestore.rb'
require File.dirname(__FILE__)+'/sensors.rb'

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
    DEFAULT_PORT = 4500
    DEFAULT_INTERFACE = "127.0.0.1"
    
    def initialize(opts={})
      @opts = opts
    end

    def run
      ForkedRunner.run_as_fork do |forked_runner|
        @fstore = SAAL::FileStore.new(@opts)
        @sensors = SAAL::Sensors.new(@opts)
        @interval = @opts[:interval] || 60
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
      interface = @opts[:interface] || DEFAULT_INTERFACE
      port = @opts[:port] || DEFAULT_PORT
      server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0 )
      sockaddr = Socket.pack_sockaddr_in(port, interface)
      server.bind sockaddr
      server.listen 5
      begin
        if !fr.stop?
          sock = server.accept_nonblock[0]
          RequestHandler.new(sock, @fstore, @sensors, fr).run
          sock.close
        end
      rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
        fr.select([server])
      end while !fr.stop?  
    end
  end
end
