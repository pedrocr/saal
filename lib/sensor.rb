module SAAL
  class Sensor
    attr_reader :name, :description, :serial
    def initialize(dbstore, name, defs, owconn=nil)
      @dbstore = dbstore
      @name = name
      @max_value = defs['max_value']
      @min_value = defs['min_value']
      @description = defs['name']
      @serial = defs['onewire']['serial']
      @connect_opts = {}
      @connect_opts[:server] = defs['onewire']['server'] if defs['onewire']['server']
      @connect_opts[:port] = defs['onewire']['port'] if defs['onewire']['port']
      @owconn = owconn
    end
    
    def read
      begin
        normalize(owconn.read(@serial))
      rescue Exception
        nil
      end
    end

    def read_uncached
      begin
        normalize(owconn.read('/uncached'+@serial))
      rescue Exception
        nil
      end
    end

    def average(from, to)
      @dbstore.average(@name, from, to)
    end

    def store_value
      value = read_uncached
      @dbstore.write @name, Time.now.utc.to_i, value if value
    end

    private 
    def owconn
      @owconn || OWNet::Connection.new(@connect_opts)
    end
    
    def normalize(value)
      if (@max_value and value > @max_value) or 
         (@min_value and value < @min_value)
        nil
      else
        value
      end
    end
  end
end
