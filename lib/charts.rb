module SAAL
  class Charts
    include Enumerable

    def initialize(conffile=SAAL::CHARTSCONF, opts={})
      @defs = YAML::load(File.new(conffile))
      @sensors = opts[:sensors] || Sensors.new
      @charts = {}
      @defs.each do |name, defs|
        @charts[name.to_sym] = Chart.new(name, defs, @sensors, opts)
      end  
    end

    # Fetch a specific chart by name
    def find(name)
      @charts[name.to_sym]
    end

    def each
      @charts.each{|name, chart| yield chart}
    end
  end
end
