require File.dirname(__FILE__)+'/test_helper.rb'

class TestCharts < Test::Unit::TestCase
  def setup
    @defs = YAML::load File.new(TEST_CHARTS_FILE)
    sensors = SAAL::Sensors.new(TEST_SENSORS_FILE, TEST_DBCONF)
    @charts = SAAL::Charts.new(TEST_CHARTS_FILE, :sensors => sensors)
  end

  def test_load
    @defs.each do |name, defs|
      chart = @charts.find(name)
      assert_instance_of SAAL::Chart, chart
      assert_equal name, chart.name
    end
  end

  def test_each
    i = 0
    @charts.each do |chart|
      defs = @defs[chart.name]
      assert_equal defs['last'], chart.num
      assert_equal defs['periods'], chart.periods
      assert_equal defs['description'], chart.description
      assert_equal defs['alt'], chart.alt
      assert_equal defs['sensors'], chart.sensors.map{|s| s.name.to_s}
      i += 1
    end
    assert_equal @defs.size, i, "Charts.each did not iterate correctly"
  end
end
