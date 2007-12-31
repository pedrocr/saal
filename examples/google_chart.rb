#!/usr/bin/env ruby

$: << File.dirname(__FILE__)+"/../lib/"
require 'saal'

if ARGV.size != 1
  $stderr.puts("Usage: gooogle_chart.rb <chart_file.png>")
  exit (2)
end

NUM_VALUES = 48
@c = SAAL::ChartData.new
@time = Time.now.utc
@to = @time.to_i
@from = @to - 60*60*24

@pad = if @time.min < 20
  2
elsif @time.min < 40
  1
else
  0
end
@num_values = NUM_VALUES - @pad


def create_data(sensor, min, max)
  d = @c.get_data(sensor, @from, @to, @num_values)
  d = @c.normalize_data(d,min,max)
  @pad.times {d << -1.0}
  d
end

@data = [create_data('temp_exterior', -15, 45),
         create_data('temp_estufa', -15, 45),
         create_data('hum_exterior', 0, 100),
         create_data('pressao', 950, 1075)]



@dataurl = @data.map {|values| values.join(",")}.join('|')
@hoursurl = (0..23).map{|i| (@time.hour - i)%24}.reverse.join('|')


system "wget \"http://chart.apis.google.com/chart?chs=700x305&chco=00ff00,ff0000,0000ff,ffff00&cht=lc&chxt=x,y,y,r&chxl=0:|#{@hoursurl}|1:|-15ºC||0||15||30||45ºC|2:|0%|25|50|75|100%|3:|950||975||1000||1025||1075 hPa&chxp=0,2,6,10,14.5,18.6,22.7,26.9,31.1,35.3,39.5,43.7,47.9,52.1,56.3,60.5,64.7,68.9,73.1,77.3,81.5,85.7,89.9,94,98.2&chg=4.1666,12.5,1,5&chd=t:#{@dataurl}\" -O #{ARGV[0]}"
