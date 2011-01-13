require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

MOCK_AVERAGES = [40.001,30.002,nil,60.004,300.005]
MOCK_MAX = 215.3
MOCK_MIN = 35.2
NORMALIZED_MOCK_AVERAGES = [2.7,0.0,-1.0,13.8,100.0]

class MockSensor
  attr_reader :asked_averages
  def initialize
    @averages = MOCK_AVERAGES.dup
    @asked_averages = []
  end
  def average(from, to) 
    @asked_averages << [from,to]; 
    @averages.shift
  end
end

class TestChartData < Test::Unit::TestCase  
  def test_basic_range
    sensor = MockSensor.new
    range = SAAL::ChartDataRange.new(:from => 1, :to => 1000)
    assert_equal MOCK_AVERAGES, range.get_data(:average, sensor, 5)
    assert_equal([[1,200],[201,400],[401,600],[601,800],[801,1000]],
                 sensor.asked_averages)
  end

  def test_interval_range
    sensor = MockSensor.new
    now = Time.utc(2010, 12, 30, 15, 38, 19)
    ranges = [[1293638400,1293655679],[1293655680,1293672959],
              [1293672960,1293690239],[1293690240,1293707519],
              [1293707520,1293724799]]
    range = SAAL::ChartDataRange.new(:last => 24, :periods => :hours, :now => now)
    assert_equal MOCK_AVERAGES, range.get_data(:average, sensor, 5)
    assert_equal ranges, sensor.asked_averages
  end

  def test_correct_time_use
    sensor = MockSensor.new
    range = SAAL::ChartDataRange.new(:last => 24, :periods => :hours)
    now = Time.now.utc
    to = Time.utc(now.year,now.month,now.day,now.hour,59,59).to_i
    from = to - 24*60*60 + 1
    assert_equal MOCK_AVERAGES[0..0], range.get_data(:average, sensor, 1)
    assert_equal [[from,to]], sensor.asked_averages
  end
  
  # Test all the alignment functions underlying :last, :periods
  def self.assert_alignment_interval(num,periods,from,to, periodnames=nil, 
                                     now = nil, extra=nil)
    define_method("test_alignment_#{num}#{periods}#{extra.to_s}") do
      now = now || Time.utc(2010, 12, 30, 15, 38, 19)
      o = SAAL::ChartDataRange.new(:last => num, :periods => periods, :now => now)
      assert_equal [from.to_i, to.to_i], [o.from, o.to],
                   "Expecting #{from.utc} - #{to.utc}\n"+
                   "Got #{Time.at(o.from).utc} - #{Time.at(o.to).utc}"
      assert_equal periodnames, o.periodnames if periodnames
    end
  end
  assert_alignment_interval(24, :hours, Time.utc(2010, 12, 29, 16, 0, 0),
                                        Time.utc(2010, 12, 30, 15, 59, 59),
                            (16..23).map{|s| s.to_s}+(0..15).map{|s| s.to_s})

  assert_alignment_interval(22, :hours, Time.utc(2010, 12, 29, 18, 0, 0),
                                        Time.utc(2010, 12, 30, 15, 59, 59),
                            (18..23).map{|s| s.to_s}+(0..15).map{|s| s.to_s})

  assert_alignment_interval(1, :days, Time.utc(2010, 12, 30, 0, 0, 0),
                                      Time.utc(2010, 12, 30, 23, 59, 59),
                            ["Thu"])

  assert_alignment_interval(12, :hours, Time.utc(2010, 12, 30, 4, 0, 0),
                                        Time.utc(2010, 12, 30, 15, 59, 59),
                            (4..15).map{|s| s.to_s})

  assert_alignment_interval(1, :weeks,Time.utc(2010, 12, 27, 0, 0, 0),
                                      Time.utc(2011, 1, 2, 23, 59, 59),
                            ["27 Dec"])

  assert_alignment_interval(2, :weeks,Time.utc(2010, 12, 20, 0, 0, 0),
                                      Time.utc(2011, 1, 2, 23, 59, 59),
                            ["20 Dec","27 Dec"])

  assert_alignment_interval(1, :years, Time.utc(2010, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59),
                            ["2010"])

  assert_alignment_interval(2, :years, Time.utc(2009, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59),
                            ["2009","2010"])

  assert_alignment_interval(1, :months, Time.utc(2010, 12, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59),
                            ["Dec"])
  assert_alignment_interval(1, :months, Time.utc(2010, 4, 1, 0, 0, 0),
                                        Time.utc(2010, 4, 30, 23, 59, 59),
                            ["Apr"],    Time.utc(2010, 4, 30, 12, 50, 30), 
                                       "_30day_month")

  assert_alignment_interval(12, :months, Time.utc(2010, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59),
                            ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug",
                             "Sep","Oct","Nov","Dec"])

  assert_alignment_interval(13, :months, Time.utc(2009, 12, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
  assert_alignment_interval(24, :months, Time.utc(2009, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
  assert_alignment_interval(12, :months, Time.utc(2010, 2, 1, 0, 0, 0),
                                       Time.utc(2011, 1, 31, 23, 59, 59),
                            ["Feb","Mar","Apr","May","Jun","Jul","Aug",
                             "Sep","Oct","Nov","Dec","Jan"],
                                       Time.utc(2011, 1, 1, 14, 15, 10),
                            "_midyear")

  def self.assert_dec_months(num, from, to)
    define_method("test_dec_#{num}months_from#{from.join('-')}_to#{to.join('-')}") do
      o = SAAL::ChartDataRange.new
      assert_equal Time.utc(to[0], to[1], 1, 0, 0, 0),
                   o.send(:dec_months, num, Time.utc(from[0],from[1],1,0,0,0))
    end
  end

  assert_dec_months 2, [2010,12],[2010,10]
  assert_dec_months 12, [2011,1],[2010,1]
  assert_dec_months 24, [2011,1],[2009,1]
  assert_dec_months 2, [2011,1],[2010,11]
  assert_dec_months 14, [2011,1],[2009,11]
end
