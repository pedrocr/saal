require 'yaml'
require 'ownet'

module SAAL
  class Sensors
    include Enumerable
    
    def initialize(opts)
      @defs = YAML::load(File.new(opts[:conf]))
    end
        
    # Implements the get methods to fetch a specific sensor
    def method_missing(name, *args)
      name = name.to_s
      if args.size == 0 && @defs.include?(name)
        Sensor.new @defs[name]
      else
        raise NoMethodError, "undefined method \"#{name}\" for #{self}"
      end
    end
    
    def each
      @defs.each{ |name, value| yield name, Sensor.new(value)}
    end
  end

  class Sensor
    attr_reader :name, :serial
    def initialize(defs)
      @name = defs['name']
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
        OWNet::Connection.new.read('/uncached'+@serial)
      rescue Exception
        nil
      end
    end

  end
end
