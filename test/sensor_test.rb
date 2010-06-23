require File.dirname(__FILE__)+'/test_helper.rb'

class MockConnection
  attr_accessor :value
  def read(serial)
    @value
  end
end

class MockDBStore
  attr_accessor :value
  def average(sensor, from, to)
    @value
  end
end

class TestSensor < Test::Unit::TestCase
  def setup
    @defs = YAML::load File.new(TEST_SENSOR_CLEANUPS_FILE)
    @conn = MockConnection.new
    @dbstore = MockDBStore.new
    @fake = SAAL::Sensor.new(@dbstore, 'fake', @defs['fake'], @conn)
    @fake2 = SAAL::Sensor.new(@dbstore, 'fake', @defs['fake2'], @conn)
  end

  def test_read_too_high_values
    @conn.value = 1000
    assert_nil @fake.read
    assert_nil @fake.read_uncached
    @conn.value = 200
    assert_equal 200, @fake.read
    assert_equal 200, @fake.read_uncached
  end

  def test_read_too_low_values
    @conn.value = 0
    assert_nil @fake.read
    assert_nil @fake.read_uncached
    @conn.value = 200
    assert_equal 200, @fake.read
    assert_equal 200, @fake.read_uncached
  end

  def test_read_without_limits
    @conn.value = 200
    assert_equal 200, @fake2.read
    assert_equal 200, @fake2.read_uncached
  end
end
