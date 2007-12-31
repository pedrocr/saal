module SAAL
  class Connection
    DEFAULT_HOST = "localhost"
    DEFAULT_PORT = 4500
    
    def initialize(opts={})
      @port = opts[:port] || DEFAULT_PORT
      @host = opts[:hostname] || DEFAULT_HOST
    end
        
    def read(sensor)
      @socket.write("GET #{sensor}\n")
      result = @socket.readline.split(" ")
      result[1].to_i
    end
    
    def average(sensor, from, to)
      @socket.write("AVERAGE #{sensor} #{from} #{to}\n")
      result = @socket.readline.split(" ")
      result[1].to_i
    end
    
    [:read, :average].each do |m|
       old = instance_method(m)
       define_method(m) do |*args|
         @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
         @socket.connect(Socket.pack_sockaddr_in(@port, @host))
         ret = old.bind(self).call(*args)
         @socket.close
         return ret
       end
    end
  end
end
