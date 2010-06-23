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
    @fake2 = SAAL::Sensor.new(@dbstore, 'fake2', @defs['fake2'], @conn)
    @fake3 = SAAL::Sensor.new(@dbstore, 'fake3', @defs['fake3'], @conn)
    @max_value = @defs['fake2']['max_value']
    @max_correctable = @defs['fake2']['max_correctable']
    @min_value = @defs['fake2']['min_value']
    @min_correctable = @defs['fake2']['min_correctable']
  end

  def test_read_too_high_values
    @conn.value = @max_value+1
    assert_nil @fake.read
    assert_nil @fake.read_uncached
    @conn.value = @max_value
    assert_equal @max_value, @fake.read
    assert_equal @max_value, @fake.read_uncached
  end

  def test_read_too_high_but_correctable_values
    @conn.value = @max_correctable
    assert_equal @max_value, @fake2.read
    assert_equal @max_value, @fake2.read_uncached
    @conn.value = @max_correctable+1
    assert_nil @fake2.read
    assert_nil @fake2.read_uncached
  end

  def test_read_too_low_values
    @conn.value = @min_value-1
    assert_nil @fake.read
    assert_nil @fake.read_uncached
    @conn.value = @min_value
    assert_equal @min_value, @fake.read
    assert_equal @min_value, @fake.read_uncached
  end

  def test_read_too_low_but_correctable_values
    @conn.value = @min_correctable
    assert_equal @min_value, @fake2.read
    assert_equal @min_value, @fake2.read_uncached
    @conn.value = @min_correctable-1
    assert_nil @fake2.read
    assert_nil @fake2.read_uncached
  end

  def test_read_without_limits
    @conn.value = 200
    assert_equal 200, @fake3.read
    assert_equal 200, @fake3.read_uncached
  end
end
