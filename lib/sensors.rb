require 'yaml'
require 'ownet'

module SAAL
  class Sensors
    include Enumerable
    
    def initialize(conffile, dbconffile)
      @defs = YAML::load(File.new(conffile))
      @dbstore = DBStore.new(dbconffile)
    end
        
    # Implements the get methods to fetch a specific sensor
    def method_missing(name, *args)
      name = name.to_s
      if args.size == 0 && @defs.include?(name)
        Sensor.new @dbstore, name, @defs[name]
      else
        raise NoMethodError, "undefined method \"#{name}\" for #{self}"
      end
    end
    
    def each
      @defs.each{ |name, value| yield name, Sensor.new(@dbstore, name, value)}
    end
  end

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
