module SAAL
  class Sensor
    attr_reader :name, :description, :serial
    def initialize(dbstore, name, defs)
      @dbstore = dbstore
      @name = name
      @description = defs['name']
      @serial = defs['onewire']['serial']
      @connect_opts = {}
      @connect_opts[:server] = defs['onewire']['server'] if defs['onewire']['server']
      @connect_opts[:port] = defs['onewire']['port'] if defs['onewire']['port']
    end
    
    def read
      begin
        OWNet::Connection.new(@connect_opts).read(@serial)
      rescue Exception
        nil
      end
    end

    def read_uncached
      begin
        OWNet::Connection.new(@connect_opts).read('/uncached'+@serial)
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
  end
end
