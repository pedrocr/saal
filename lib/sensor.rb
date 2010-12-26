module SAAL  
  class UnimplementedMethod < RuntimeError
  end

  class SensorUnderlying
    def writeable?; false; end
    def self.writeable! 
      define_method(:writeable?){true}
    end
  end

  class Sensor
    MAX_READ_TRIES = 5

    attr_reader :name, :description
    def initialize(dbstore, name, underlying, defs, opts={})
      @dbstore = dbstore
      @name = name
      @underlying = underlying
      @description = defs['name']
      
      # Reading correction settings
      @max_value = defs['max_value']
      @max_correctable = defs['max_correctable']
      @min_value = defs['min_value']
      @min_correctable = defs['min_correctable']

      # Outliercache
      @outliercache = opts[:no_outliercache] ? nil : OutlierCache.new
    end  

    def writeable?
      @underlying.writeable?
    end

    def read
      normalize(outlier_proof_read(false))
    end

    def read_uncached
      normalize(outlier_proof_read(true))
    end

    def write(value)
      @underlying.write(value)
    end 

    def average(from, to)
      @dbstore.average(@name, from, to)
    end

    def store_value
      value = read_uncached
      @dbstore.write(@name, Time.now.utc.to_i, value) if value
    end

    private
    def outlier_proof_read(uncached)
      tries = 0
      value = nil
      begin
        tries += 1
        value = @underlying.read(uncached)
        break if value && @outliercache && @outliercache.validate(value)
      end while tries < MAX_READ_TRIES
      value
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
  end
end
