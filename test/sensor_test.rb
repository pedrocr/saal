require File.dirname(__FILE__)+'/test_helper.rb'

class MockConnection
  attr_accessor :value
  def read(serial)
    @value
  end
end

class TestSensor < Test::Unit::TestCase
  def setup
    @defs = YAML::load File.new(TEST_SENSOR_CLEANUPS_FILE)
    @conn = MockConnection.new
  end

  def test_read_too_high_values
    @conn.value = 1000
    @sensor = SAAL::Sensor.new(nil, 'fake', @defs['fake'], @conn)
    assert_nil @sensor.read
    assert_nil @sensor.read_uncached
    @conn.value = 200
    assert_equal 200, @sensor.read
    assert_equal 200, @sensor.read_uncached
  end

  def test_read_too_low_values
    @conn.value = 0
    @sensor = SAAL::Sensor.new(nil, 'fake', @defs['fake'], @conn)
    assert_nil @sensor.read
    assert_nil @sensor.read_uncached
    @conn.value = 200
    assert_equal 200, @sensor.read
    assert_equal 200, @sensor.read_uncached
  end

  def test_read_without_limits
    @conn.value = 200
    @sensor = SAAL::Sensor.new(nil, 'fake', @defs['fake2'], @conn)
    assert_equal 200, @sensor.read
    assert_equal 200, @sensor.read_uncached
  end
end
