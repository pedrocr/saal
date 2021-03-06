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
    attr_reader :name, :description, :numreads
    attr_accessor :underlying
    def initialize(dbstore, name, underlying, defs, opts={})
      @dbstore = dbstore
      @name = name
      @underlying = underlying
      @description = defs['name']
      @mock_opts = {}

      if defs['altitude'] && @underlying.sensor_type == :pressure  
        @read_offset = defs['altitude'].to_f/9.2
      elsif defs['linear_offset']
        @read_offset = defs['linear_offset'].to_f
      else
        @read_offset = 0.0
      end

      if defs['linear_multiplier']
        @read_multiplier = defs['linear_multiplier'].to_f
      else
        @read_multiplier = 1.0
      end

      @set_type = defs['type'] ? defs['type'].to_sym : nil

      @numreads = (defs['numreads']||1).to_i
      @numreads = 1 if @numreads == 0
      @numreads += 1 if @numreads.even?
    end

    def writeable?
      @underlying.writeable?
    end

    def sensor_type
      @set_type || @underlying.sensor_type
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

    def weighted_average(from, to)
      return @mock_opts[:weighted_average] if @mock_opts[:weighted_average]
      apply_offset @dbstore.weighted_average(@name, from, to)
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
      value = real_read(true,false)
      @dbstore.write(@name, Time.now.utc.to_i, value) if value
    end

    def mock_set(opts)
      @mock_opts.merge!(opts)
    end

    private
    def real_read(uncached,offset=true)
      return @mock_opts[:value] if @mock_opts[:value]
      values = (0..@numreads-1).map{@underlying.read(uncached)}
      #FIXME: If we don't get all values give up and return the first value
      if not values.all? {|v| v.instance_of?(Float) || v.instance_of?(Integer)}
        value = values[0]
      else
        value = values.sort[@numreads/2]
      end
      offset ? apply_offset(value) : value
    end
      
    def apply_offset(v)
      v ? v*@read_multiplier+@read_offset : v
    end
  end
end
