require File.dirname(__FILE__)+'/test_helper.rb'

class TestChart < Test::Unit::TestCase
  def setup
    @defs = YAML::load File.new(TEST_CHARTS_FILE)
    sensors = SAAL::Sensors.new(TEST_SENSORS_FILE, TEST_DBCONF)
    @charts = SAAL::Charts.new(TEST_CHARTS_FILE, 
                               :sensors => sensors, 
                               :now => Time.utc(2010, 12, 30, 15, 38, 19))
  end

  def test_alignlabels
    assert_equal :center, @charts.find('week').alignlabels
    assert_equal :left, @charts.find('4week').alignlabels
  end

  def test_average
    name = 'week'
    defs = @defs[name]
    chart = @charts.find(name)    
    assert_equal ['Fri','Sat','Sun','Mon','Tue','Wed','Thu'], chart.periodnames
    chart.sensors.each {|s| s.mock_set(:average => 1)}
    assert_equal({:fake_temp => [1], :non_existant => [1]}, chart.average(1))
  end

  def test_min_max_1arity
    name = 'week'
    defs = @defs[name]
    chart = @charts.find(name)    
    assert_equal ['Fri','Sat','Sun','Mon','Tue','Wed','Thu'], chart.periodnames
    [:minimum,:maximum].each do |method|
      chart.sensors.each {|s| s.mock_set(method => 1)}
      assert_equal({:fake_temp => [1], :non_existant => [1]}, chart.send(method,1))
    end
  end
  
  def test_min_max_0arity
    name = 'week'
    defs = @defs[name]
    chart = @charts.find(name)    
    assert_equal ['Fri','Sat','Sun','Mon','Tue','Wed','Thu'], chart.periodnames
    [:minimum,:maximum].each do |method|
      chart.sensors.each {|s| s.mock_set(method => 1)}
      assert_equal({:fake_temp => 1, :non_existant => 1}, chart.send(method))
    end
  end
end
