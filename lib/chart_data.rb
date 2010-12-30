module SAAL
  class ChartData
    def initialize(sensor)
      @sensor = sensor
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

  class ChartDataRange
    ALIGN = {:years => [12,31,23,59,59],
             :months => [31,23,59,59],
             :days => [23,59,59],
             :weeks => [23,59,59],
             :hours => [59,59]}

    NUMHOURS = {:hours => 1, :days => 24, :weeks => 24*7}

    def initialize(sensor, opts={})
      @sensor = sensor
      if opts[:alignment]
      else
        @from = opts[:from] || 0
        @to = opts[:to] || Time.now.utc.to_i
      end
    end

    def average(num)
      get_data(:average, num)
    end

    def self.calc_alignment(opts={})
      now = opts[:now] || Time.now.utc
      periods = opts[:periods]
      num = opts[:last]

      # Align end of period
      args = [now.year, now.month, now.day, now.hour, now.min, now.sec]
      args = args[0..-(ALIGN[periods].size+1)]
      args += ALIGN[periods]
      to = Time.utc(*args).to_i
      to += (6-now.wday)*60*60*24 if periods == :weeks
      
      if [:years, :months].include? periods
        # we decrement in the date
        from = to
      else
        # we decrement by elapsed time
        from = to - NUMHOURS[periods]*60*60*num
      end

      [from+1, to]
    end

    private
    def get_data(method, num)
      step = (@to - @from).to_f/num.to_f
      (0..num-2).map do |i|
        f = (@from+i*step).to_i
        t = (@from+(i+1)*step-0.5).to_i
        @sensor.send(method, f, t)
      end << @sensor.send(method, (@from+(num-1)*step).to_i, @to)
    end
  end
end
