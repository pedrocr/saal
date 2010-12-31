module SAAL
  class Chart
    attr_reader :name, :num, :periods, :sensors, :alignlabels
    def initialize(name, defs, sensors, opts={})
      @name = name
      @defs = defs
      @alignlabels = (defs['alignlabels'] || :center).to_sym
      @sensors = defs['sensors'].map{|name| sensors.send(name)} 
      @num = defs['last']
      @periods = defs['periods']
      @datarange = ChartDataRange.new(defs.merge(:now => opts[:now]))
    end

    def periodnames
      @datarange.periodnames
    end

    def average(num)
      h = {}
      @sensors.each{|s| h[s.name.to_sym] = @datarange.average(s,num)}
      h
    end
  end
end
