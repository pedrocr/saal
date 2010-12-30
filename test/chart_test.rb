require File.dirname(__FILE__)+'/test_helper.rb'

class TestChart < Test::Unit::TestCase
  def setup
    @defs = YAML::load File.new(TEST_CHARTS_FILE)
    sensors = SAAL::Sensors.new(TEST_SENSORS_FILE, TEST_DBCONF)
    @charts = SAAL::Charts.new(TEST_CHARTS_FILE, 
                               :sensors => sensors, 
                               :now => Time.utc(2010, 12, 30, 15, 38, 19))
  end

  def test_each
    name = 'week'
    defs = @defs[name]
    chart = @charts.find(name)
    assert_instance_of SAAL::Chart, chart
    assert_equal defs['last'], chart.num
    assert_equal defs['periods'], chart.periods
    assert_equal defs['sensors'], chart.sensors.map{|s| s.name.to_s}
    
    assert_equal ['Fri','Sat','Sun','Mon','Tue','Wed','Thu'], chart.periodnames
    chart.sensors.each {|s| s.mock_set(:average => 1)}
    assert_equal({:fake_temp => [1], :non_existant => [1]}, chart.average(1))
  end
end
