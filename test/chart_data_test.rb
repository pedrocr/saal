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
    range = SAAL::ChartDataRange.new(sensor, :from => 1, :to => 1000)
    assert_equal MOCK_AVERAGES, range.average(5)
    assert_equal([[1,200],[201,400],[401,600],[601,800],[801,1000]],
                 sensor.asked_averages)
  end

  def test_interval_range
    sensor = MockSensor.new
    now = Time.utc(2010, 12, 30, 15, 38, 19)
    ranges = [[1293638400,1293655679],[1293655680,1293672959],
              [1293672960,1293690239],[1293690240,1293707519],
              [1293707520,1293724799]]
    range = SAAL::ChartDataRange.new(sensor, :last => 24, :periods => :hours, :now => now)
    assert_equal MOCK_AVERAGES, range.average(5)
    assert_equal ranges, sensor.asked_averages
  end
  
  
  # Test all the alignment functions underlying :last, :periods
  def self.assert_alignment_interval(num,periods,from,to, now = nil, extra=nil)
    define_method("test_alignment_#{num}#{periods}#{extra.to_s}") do
      o = SAAL::ChartDataRange.new(nil)
      now = now || Time.utc(2010, 12, 30, 15, 38, 19)
      gotfrom, gotto = o.send(:calc_alignment, num,periods,now) 
      assert_equal [from.to_i, to.to_i], [gotfrom, gotto],
                   "Expecting #{from.utc} - #{to.utc}\n"+
                   "Got #{Time.at(gotfrom).utc} - #{Time.at(gotto).utc}"
    end
  end
  assert_alignment_interval(24, :hours, Time.utc(2010, 12, 29, 16, 0, 0),
                                        Time.utc(2010, 12, 30, 15, 59, 59))
  assert_alignment_interval(1, :day, Time.utc(2010, 12, 30, 0, 0, 0),
                                        Time.utc(2010, 12, 30, 23, 59, 59))
  assert_alignment_interval(12, :hours, Time.utc(2010, 12, 30, 4, 0, 0),
                                        Time.utc(2010, 12, 30, 15, 59, 59))
  assert_alignment_interval(1, :week, Time.utc(2010, 12, 27, 0, 0, 0),
                                      Time.utc(2011, 1, 2, 23, 59, 59))
  assert_alignment_interval(1, :year, Time.utc(2010, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
  assert_alignment_interval(2, :years, Time.utc(2009, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
  assert_alignment_interval(1, :month, Time.utc(2010, 12, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
  assert_alignment_interval(1, :month, Time.utc(2010, 4, 1, 0, 0, 0),
                                       Time.utc(2010, 4, 30, 23, 59, 59),
                                       Time.utc(2010, 4, 30, 12, 50, 30), 
                                       "_30day_month")
  assert_alignment_interval(12, :months, Time.utc(2010, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
  assert_alignment_interval(13, :months, Time.utc(2009, 12, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
  assert_alignment_interval(24, :months, Time.utc(2009, 1, 1, 0, 0, 0),
                                        Time.utc(2010, 12, 31, 23, 59, 59))
end
