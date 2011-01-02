require File.dirname(__FILE__)+'/test_helper.rb'

class MockConnection
  attr_accessor :value, :values
  def initialize
    @value = @values = nil
  end
  def read(serial)
    @value ? @value : @values.shift 
  end
end

class MockDBStore
  attr_accessor :value, :stored_value
  def average(sensor, from, to)
    @value
  end
  def minimum(sensor, from, to)
    @value
  end
  def maximum(sensor, from, to)
    @value
  end
  def write(sensor,date,value)
    @stored_value = value
  end
end

class TestSensor < Test::Unit::TestCase
  def fake_sensor(name, opts={})
    SAAL::Sensors.sensors_from_defs(@dbstore, name, @defs[name], 
                                    opts.merge(:owconn => @conn))[0]
  end

  def setup
    @defs = YAML::load File.new(TEST_SENSOR_CLEANUPS_FILE)
    @conn = MockConnection.new
    @dbstore = MockDBStore.new
    @fake = fake_sensor('fake', :no_outliercache => true)
    @fake2 = fake_sensor('fake2', :no_outliercache => true)
    @fake3 = fake_sensor('fake3')
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

  def test_eliminate_outliers
    @conn.values = [200]*20 + [1000,200]
    assert_equal [200]*21, (1..21).map{@fake3.read}
    @conn.values = [200]*20 + [1000,200,1000,200]
    assert_equal [200]*21, (1..21).map{@fake3.read_uncached}
  end

  def test_eliminate_outliers_zeroes
    @conn.values = [0]*20 + [1000,0]
    assert_equal [0]*20+[1000], (1..21).map{@fake3.read}
    @conn.values = [0]*20 + [1000,0]
    assert_equal [0]*20+[1000], (1..21).map{@fake3.read_uncached}
  end

  def test_sealevel_correction
    sensor = fake_sensor('pressure')
    @conn.value = @dbstore.value = 1000
    corrected = 1000+@defs['pressure']['altitude'].to_f/9.2
    assert_equal corrected, sensor.read
    sensor.store_value
    assert_equal 1000, @dbstore.stored_value
    assert_equal corrected, sensor.minimum(0,100)
    assert_equal corrected, sensor.maximum(0,100)
    assert_equal corrected, sensor.average(0,100)
  end

  def test_mocked
    @mockable = fake_sensor('fake3')
    @conn.value = 1.0
    assert_equal 1.0, @mockable.read
    @mockable.mock_set(:value => 2.0)
    assert_equal 2.0, @mockable.read
    @mockable.write(3.0)
    assert_equal 3.0, @mockable.read
    @mockable.mock_set(:minimum => 1.0, :average => 2.0, :maximum => 3.0)
    assert_equal 1.0, @mockable.minimum(0,100)
    assert_equal 2.0, @mockable.average(0,100)
    assert_equal 3.0, @mockable.maximum(0,100)
    assert_equal 3.0, @mockable.read
  end
end
