module SAAL
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
              value = @sensors.send(scommand[1]).read
              @socket.write "#{scommand[1]} #{value}\n"
            rescue NoMethodError
              @socket.write "ERROR: No such sensor"
            end
          end
        else
          @socket.write "No such command\n"
      end
    end
    
    def check_num_args(command, num)
      @socket.write("ERROR: wrong number of arguments\n") if command.size != num
      command.size == num
    end
  end
end
