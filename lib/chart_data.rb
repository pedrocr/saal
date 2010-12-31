module SAAL
  class ChartDataRange
    ALIGN = {:years => [12,31,23,59,59],
             :months => [31,23,59,59],
             :days => [23,59,59],
             :weeks => [23,59,59],
             :hours => [59,59]}

    NUMHOURS = {:hours => 1, :days => 24, :weeks => 24*7}
    DAYNAMES = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
    MONTHNAMES = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

    attr_reader :num, :periods
    def initialize(opts={})
      last = opts[:last] || opts['last'].to_i
      periods = opts[:periods] || (opts['periods'] ? opts['periods'].to_sym : nil)
      @now = opts[:now] || Time.now.utc
      if last && periods
        @num = last
        @periods = periods
        calc_alignment
      else
        @from = opts[:from] || 0
        @to = opts[:to] || @now
      end
    end

    def from
      @from.to_i
    end

    def to
      @to.to_i
    end

    def get_data(method, sensor, num)
      step = (@to - @from).to_i/num
      t = @from - 1
      (0..num-2).map do |i|
        f = t + 1
        t = (f+step)
        v = sensor.send(method, f.to_i, t.to_i)
      end << sensor.send(method, (t+1).to_i, to.to_i)
    end

    def periodnames
      if !@num
        raise RuntimeError, 
              "Trying to get periodnames without a :last & :periods definition" 
      end

      case @periods
      when :hours
        (0...@num).map{|i| ((@now.hour - i)%24).to_s}.reverse
      when :days
        (1..@num).map{|i| (@now.wday - i)%7}.map{|w| DAYNAMES[w]}.reverse
      when :weeks
        initial = @now - (@now.wday-1)*24*60*60
        (0...@num).map do |i| 
          time = Time.at(initial - i*24*60*60*7)
          time.day.to_s+" "+ MONTHNAMES[time.month-1]
        end.reverse
      when :months
        (1..@num).map{|i| (@now.month - i)%12}.map{|m| MONTHNAMES[m]}.reverse
      when :years
        (0...@num).map{|i| (@now.year - i).to_s}.reverse
      else
        raise RuntimeError, "No such period type #{@periods}" 
      end
    end

    private
    def calc_alignment
      if [:years, :year].include? periods
        # Calculate by date manipulation
        from = Time.utc(@now.year - num + 1, 1, 1, 0, 0, 0)
        to = Time.utc(@now.year, 12, 31, 23, 59, 59)
      elsif [:months, :month].include? periods
        # advance to the 1st of the next month and then subtract 1 second
        newm = @now.month%12 + 1
        newy = @now.year + (@now.month == 12 ? 1 : 0)
        to = Time.utc(newy, newm, 1, 0, 0, 0) - 1
        # subtract num months from a date
        newm = @now.month-1 - (num-1)%12 + 1
        newy = @now.year - (num-1)/12
        from = Time.utc(newy, newm, 1, 0, 0, 0, 0)
        #from = (to+1).to_datetime.<<(num).to_gm_time
      else
        # Calculate by elasped time
        args = [@now.year, @now.month, @now.day, @now.hour, @now.min, @now.sec]
        args = args[0..-(ALIGN[periods].size+1)]
        args += ALIGN[periods]
        to = Time.utc(*args)
        to += (7-@now.wday)*60*60*24 if [:weeks,:week].include?(periods)
        from = to - NUMHOURS[periods]*60*60*num+1
      end
      @from = from
      @to = to
    end
  end
end
