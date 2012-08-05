module SAAL  
  class UnimplementedMethod < RuntimeError
  end

  class SensorUnderlying
    def sensor_type; nil; end
    def writeable?; false; end
    def self.writeable! 
      define_method(:writeable?){true}
    end
  end

  class Sensor
    MAX_READ_TRIES = 5

    attr_reader :name, :description
    attr_accessor :underlying
    def initialize(dbstore, name, underlying, defs, opts={})
      @dbstore = dbstore
      @name = name
      @underlying = underlying
      @description = defs['name']
      @mock_opts = {}

      @read_offset = if defs['altitude'] && @underlying.sensor_type == :pressure
        defs['altitude'].to_f/9.2
      else
        0.0
      end
    end

    def writeable?
      @underlying.writeable?
    end

    def sensor_type
      @underlying.sensor_type
    end

    def read
      real_read(false)
    end

    def read_uncached
      real_read(true)
    end

    def write(value)
      if @mock_opts[:value]
        @mock_opts[:value] = value
      else
        ret = @underlying.write(value)
        store_value
        ret
      end
    end 

    def average(from, to)
      return @mock_opts[:average] if @mock_opts[:average]
      apply_offset @dbstore.average(@name, from, to)
    end

    def minimum(from, to)
      return @mock_opts[:minimum] if @mock_opts[:minimum]
      apply_offset @dbstore.minimum(@name, from, to)
    end

    def maximum(from, to)
      return @mock_opts[:maximum] if @mock_opts[:maximum]
      apply_offset @dbstore.maximum(@name, from, to)
    end

    def last_value
      return @mock_opts[:last_value] if @mock_opts[:last_value]
      apply_offset @dbstore.last_value(@name)
    end

    def store_value
      value = read_uncached
      @dbstore.write(@name, Time.now.utc.to_i, value-@read_offset) if value
    end

    def mock_set(opts)
      @mock_opts.merge!(opts)
    end

    private
    def real_read(uncached)
      return @mock_opts[:value] if @mock_opts[:value]
      values = (0..2).map{@underlying.read(uncached)}
      #FIXME: If we don't get three values give up and return the first value
      if not values.all? {|v| v.instance_of?(Float) || v.instance_of?(Integer)}
        value = values[0]
      else
        value = values.sort[1]
      end
      apply_offset(value)
    end
      
    def apply_offset(v)
      v ? v+@read_offset : v
    end
  end
end
