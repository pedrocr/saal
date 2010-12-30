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
  def test_get_data
    sensor = MockSensor.new
    c = SAAL::ChartData.new(sensor)
    assert_equal MOCK_AVERAGES, c.get_data(0, 1000, 5)
    assert_equal([[0,199],[200,399],[400,599],[600,799],[800,1000]],
                 sensor.asked_averages)
  end
  
  def test_normalize_data
    sensor = MockSensor.new
    c = SAAL::ChartData.new(sensor)
    d = c.get_data(0, 1000, 5)
    assert_equal NORMALIZED_MOCK_AVERAGES, 
                 c.normalize_data(d, MOCK_MIN, MOCK_MAX)
    assert_equal([[0,199],[200,399],[400,599],[600,799],[800,1000]],
                 sensor.asked_averages)    
  end

  def test_basic_range
    sensor = MockSensor.new
    range = SAAL::ChartDataRange.new(sensor, :from => 0, :to => 1000)
    assert_equal MOCK_AVERAGES, range.average(5)
    assert_equal([[0,199],[200,399],[400,599],[600,799],[800,1000]],
                 sensor.asked_averages)
  end

  def self.assert_alignment_interval(num,periods,from,to)
    define_method("test_alignment_#{num}#{periods}") do
      now = Time.utc(2010, 12, 30, 15, 38, 19)
      gotfrom, gotto = SAAL::ChartDataRange.calc_alignment(:now => now, 
                                                           :periods => periods, 
                                                           :last => num)
      assert_equal [from.to_i, to.to_i], [gotfrom, gotto],
                   "Expecting #{from} - #{to}\n"+
                   "Got #{Time.at(gotfrom)} - #{Time.at(gotto)}"
    end
  end
  assert_alignment_interval(24, :hours, Time.utc(2010, 12, 29, 16, 0, 0),
                                        Time.utc(2010, 12, 30, 15, 59, 59))
end
