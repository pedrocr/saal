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
    c = SAAL::ChartData.new(:sensor => sensor)
    assert_equal MOCK_AVERAGES, c.get_data(0, 1000, 5)
    assert_equal([[0,199],[200,399],[400,599],[600,799],[800,1000]],
                 sensor.asked_averages)
  end
  
  def test_normalize_data
    sensor = MockSensor.new
    c = SAAL::ChartData.new(:sensor => sensor)
    d = c.get_data(0, 1000, 5)
    assert_equal NORMALIZED_MOCK_AVERAGES, 
                 c.normalize_data(d, MOCK_MIN, MOCK_MAX)
    assert_equal([[0,199],[200,399],[400,599],[600,799],[800,1000]],
                 sensor.asked_averages)    
  end
end
