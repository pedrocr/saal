require File.dirname(__FILE__)+'/test_helper.rb'

class TestSensors < Test::Unit::TestCase
  def setup
    @defs = YAML::load File.new(TEST_SENSOR_FILE1)
    @sensors = SAAL::Sensors.new(:conf => TEST_SENSOR_FILE1)
  end
    
  def test_get_sensor
    @defs.each do |name, value|
      s = @sensors.send name
      assert_equal s.name, value['name']
    end
  end
  
  def test_read
    with_fake_owserver do
      assert_instance_of Float, @sensors.fake_temp.read
      assert_nil @sensors.non_existant.read
      assert_raise(NoMethodError) { @sensors.no_such_name.read }
    end
  end

  def test_read_uncached
    with_fake_owserver do
      assert_instance_of Float, @sensors.fake_temp.read_uncached
      assert_nil @sensors.non_existant.read_uncached
      assert_raise(NoMethodError) { @sensors.no_such_name.read_uncached }
    end
  end
    
  def test_each
    expected = @defs.map{ |name, value| [name, value['name']]}
    assert_equal expected, @sensors.map {|name, sensor| [name, sensor.name]}
  end
end
