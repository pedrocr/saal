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
    chart = @charts.find(name)    
    assert_equal ['Fri','Sat','Sun','Mon','Tue','Wed','Thu'], chart.periodnames
    chart.sensors.each {|s| s.mock_set(:average => 1)}
    assert_equal({:fake_temp => [1], :non_existant => [1]}, chart.average(1))
  end

  def test_from_to
    chart = @charts.find('day')
    assert_equal Time.utc(2010, 12, 29, 16, 0, 0).to_i, chart.from
    assert_equal Time.utc(2010, 12, 30, 15, 59, 59).to_i, chart.to
  end

  def test_min_max_avg_1arity
    name = 'week'
    chart = @charts.find(name)    
    assert_equal ['Fri','Sat','Sun','Mon','Tue','Wed','Thu'], chart.periodnames
    v = {:minimum => 1.0, :maximum => 2.0, :average => 1.5}
    [:minimum,:maximum,:average].each do |method|
      chart.sensors.each {|s| s.mock_set(method => v[method])}
      assert_equal({:fake_temp => [v[method]], :non_existant => [v[method]]}, chart.send(method,1))
    end
  end
  
  def test_min_max_0arity
    name = 'week'
    chart = @charts.find(name)    
    assert_equal ['Fri','Sat','Sun','Mon','Tue','Wed','Thu'], chart.periodnames
    v = {:minimum => 1.0, :maximum => 2.0, :average => 1.5}
    [:minimum,:maximum,:average].each do |method|
      chart.sensors.each {|s| s.mock_set(method => v[method])}
      assert_equal({:fake_temp => v[method], :non_existant => v[method]}, chart.send(method))
    end
  end
end
