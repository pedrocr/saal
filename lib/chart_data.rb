module SAAL
  class ChartData
    def initialize(opts = {})
      @sensor = opts[:sensor]
    end
    
    def get_data(from, to, num)
      step = (to - from).to_f/num.to_f
      (0..num-2).map do |i|
        f = (from+i*step).to_i
        t = (from+(i+1)*step-0.5).to_i
        @sensor.average(f, t)
      end << @sensor.average((from+(num-1)*step).to_i, to)
    end
    
    def normalize_data(data, min, max)
      data.map do |i|
        if i.nil?
          -1.0
        elsif i < min
          0.0
        elsif i > max
          100.0
        else
          v = (((i-min)/(max-min).to_f)*1000).round/10.0
        end
      end
    end
  end
end
