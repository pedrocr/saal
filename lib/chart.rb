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

    def average(num=nil)
      get_data(:average, num)
    end

    def minimum(num=nil)
      get_data(:minimum, num)
    end

    def maximum(num=nil)
      get_data(:minimum, num)
    end

    private
    def get_data(method, num)
      n = num || 1
      h = {}
      @sensors.each do |s| 
        data = @datarange.get_data(method,s,n)
        h[s.name.to_sym] = num ? data : data[0]
      end
      h
    end
  end
end
