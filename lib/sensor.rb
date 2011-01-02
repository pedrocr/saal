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
    def initialize(dbstore, name, underlying, defs, opts={})
      @dbstore = dbstore
      @name = name
      @underlying = underlying
      @description = defs['name']
      @mock_opts = {}
      
      # Reading correction settings
      @max_value = defs['max_value']
      @max_correctable = defs['max_correctable']
      @min_value = defs['min_value']
      @min_correctable = defs['min_correctable']

      @read_offset = if defs['altitude'] && defs['type'] == 'pressure'
        defs['altitude'].to_f/9.2
      else
        0.0
      end

      # Outliercache
      @outliercache = opts[:no_outliercache] ? nil : OutlierCache.new
    end

    def writeable?
      @underlying.writeable?
    end

    def sensor_type
      @underlying.sensor_type
    end

    def read
      outlier_proof_read(false)
    end

    def read_uncached
      outlier_proof_read(true)
    end

    def write(value)
      if @mock_opts[:value]
        @mock_opts[:value] = value
      else
        @underlying.write(value)
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

    def store_value
      value = read_uncached
      @dbstore.write(@name, Time.now.utc.to_i, value-@read_offset) if value
    end

    def mock_set(opts)
      @mock_opts.merge!(opts)
    end

    private
    def outlier_proof_read(uncached)
      return @mock_opts[:value] if @mock_opts[:value]
      tries = 0
      value = nil
      begin
        tries += 1
        value = @underlying.read(uncached)
        break if value && @outliercache && @outliercache.validate(value)
      end while tries < MAX_READ_TRIES
      normalize(value)
    end

    def apply_offset(v)
      v ? v+@read_offset : v
    end

    def normalize(value)
      apply_offset(if @max_value and value > @max_value
        (@max_correctable and value <= @max_correctable) ? @max_value : nil
      elsif @min_value and value < @min_value
        (@min_correctable and value >= @min_correctable) ? @min_value : nil
      else
        value
      end)
    end
  end
end
