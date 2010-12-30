class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end
end

class Date
  def to_gm_time
    to_time(new_offset, :gm)
  end

  def to_local_time
    to_time(new_offset(DateTime.now.offset-offset), :local)
  end

  private
  def to_time(dest, method)
    #Convert a fraction of a day to a number of microseconds
    usec = (dest.sec_fraction * 60 * 60 * 24 * (10**6)).to_i
    Time.send(method, dest.year, dest.month, dest.day, dest.hour, dest.min,
              dest.sec, usec)
  end
end

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

    def self.calc_alignment(num, periods, now=nil)
      # FIXME: reimplement using DateTime's features
      now ||= Time.now.utc

      if [:years, :year].include? periods
        # Calculate by date manipulation
        from = Time.utc(now.year - num + 1, 1, 1, 0, 0, 0).to_i
        to = Time.utc(now.year, 12, 31, 23, 59, 59).to_i
      elsif [:months, :month].include? periods
        newm = now.month%12 + 1
        newy = now.year + (now.month == 12 ? 1 : 0)
        to = Time.utc(newy, newm, 1, 0, 0, 0).to_i-1
        # FIXME: ugly ugly line to subtract X months from a date
        from = Time.at(to+1).to_datetime.<<(num).to_gm_time.to_i
      else
        # Calculate by elasped time
        args = [now.year, now.month, now.day, now.hour, now.min, now.sec]
        args = args[0..-(ALIGN[periods].size+1)]
        args += ALIGN[periods]
        to = Time.utc(*args).to_i
        to += (7-now.wday)*60*60*24 if [:weeks,:week].include?(periods)
        from = to - NUMHOURS[periods]*60*60*num+1
      end
      [from, to]
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
