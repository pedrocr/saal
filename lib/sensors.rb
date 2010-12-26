module SAAL
  class UnknownSensorType < RuntimeError
  end

  class Sensors
    include Enumerable
    
    def initialize(conffile=SAAL::SENSORSCONF, dbconffile=SAAL::DBCONF)
      @defs = YAML::load(File.new(conffile))
      @dbstore = DBStore.new(dbconffile)
      @sensors =  {}
      @defs.each do |name, defs|
        self.class.sensors_from_defs(@dbstore, name, defs).each{|s| @sensors[s.name] = s}
      end 
      
    end
        
    # Implements the get methods to fetch a specific sensor
    def method_missing(name, *args)
      name = name.to_s
      if args.size == 0 && @sensors.include?(name)
        @sensors[name]
      else
        raise NoMethodError, "undefined method \"#{name}\" for #{self}"
      end
    end
    
    def each
      @sensors.each{|name, sensor| yield sensor}
    end

    def self.sensors_from_defs(dbstore, name, defs, opts={})
      if defs['onewire']
        return [Sensor.new(dbstore, name, OWSensor.new(defs['onewire'], opts), 
                           defs, opts)]
      elsif defs['dinrelay']
        og = DINRelay::OutletGroup.new(defs['dinrelay'])
        outlet_names = defs['dinrelay']['outlets'] || []
        return outlet_names.map do |num, oname|
          Sensor.new(dbstore, oname, DINRelay::Outlet.new(num.to_i, og), defs, opts)
        end
      else
        raise UnknownSensorType, "Couldn't figure out a valid sensor type "
                                 "from the configuration for #{name}"
      end
    end
  end
end
