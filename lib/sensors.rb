module SAAL
  class Sensors
    include Enumerable
    
    def initialize(conffile=SAAL::SENSORSCONF, dbconffile=SAAL::DBCONF)
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
end
