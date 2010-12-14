module SAAL
  class Sensor
    MAX_READ_TRIES = 5

    attr_reader :name, :description, :serial
    def initialize(dbstore, name, defs, opts={})
      @dbstore = dbstore
      @name = name
      @max_value = defs['max_value']
      @max_correctable = defs['max_correctable']
      @min_value = defs['min_value']
      @min_correctable = defs['min_correctable']
      @description = defs['name']
      @serial = defs['onewire']['serial']
      @connect_opts = {}
      @connect_opts[:server] = defs['onewire']['server'] if defs['onewire']['server']
      @connect_opts[:port] = defs['onewire']['port'] if defs['onewire']['port']
      @owconn = opts[:owconn]
      @outliercache = opts[:no_outliercache] ? nil : OutlierCache.new
    end
    
    def read
      normalize(owread(false))
    end

    def read_uncached
      normalize(owread(true))
    end

    def average(from, to)
      @dbstore.average(@name, from, to)
    end

    def store_value
      value = read_uncached
      @dbstore.write(@name, Time.now.utc.to_i, value) if value
    end

    private 
    def owconn
      @owconn ||= OWNet::Connection.new(@connect_opts)
    end
    
    def normalize(value)
      if @max_value and value > @max_value
        (@max_correctable and value <= @max_correctable) ? @max_value : nil
      elsif @min_value and value < @min_value
        (@min_correctable and value >= @min_correctable) ? @min_value : nil
      else
        value
      end
    end

    def owread(uncached = false)
      tries = 0
      value = nil
      begin
        tries += 1
        value = begin
          owconn.read((uncached ? '/uncached' : '')+@serial)
        rescue Exception
          nil
        end
      end while tries < MAX_READ_TRIES && @outliercache && !@outliercache.validate(value)
      value
    end
  end
end
