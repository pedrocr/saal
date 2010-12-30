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
             :hours => [59,59],
             :year => [12,31,23,59,59],
             :month => [31,23,59,59],
             :day => [23,59,59],
             :week => [23,59,59],
             :hour => [59,59]}

    NUMHOURS = {:hours => 1, :hour => 1, :days => 24, :day => 24, 
                :weeks => 24*7, :week => 24*7}

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

    private
    def self.calc_alignment(num, periods, now=nil)
      now ||= Time.now.utc

      if [:years, :year].include? periods
        # Calculate by date manipulation
        from = Time.utc(now.year - num + 1, 1, 1, 0, 0, 0)
        to = Time.utc(now.year, 12, 31, 23, 59, 59)
      elsif [:months, :month].include? periods
        # advance to the 1st of the next month and then subtract 1 second
        newm = now.month%12 + 1
        newy = now.year + (now.month == 12 ? 1 : 0)
        to = Time.utc(newy, newm, 1, 0, 0, 0) - 1
        # subtract num months from a date
        newm = now.month-1 - (num-1)%12 + 1
        newy = now.year - (num-1)/12
        from = Time.utc(newy, newm, 1, 0, 0, 0, 0)
        #from = (to+1).to_datetime.<<(num).to_gm_time
      else
        # Calculate by elasped time
        args = [now.year, now.month, now.day, now.hour, now.min, now.sec]
        args = args[0..-(ALIGN[periods].size+1)]
        args += ALIGN[periods]
        to = Time.utc(*args)
        to += (7-now.wday)*60*60*24 if [:weeks,:week].include?(periods)
        from = to - NUMHOURS[periods]*60*60*num+1
      end
      [from.to_i, to.to_i]
    end

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
