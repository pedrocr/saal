require File.dirname(__FILE__)+'/test_helper.rb'

class MockConnection
  attr_accessor :value, :values, :stored_value
  def initialize
    @value = @values = nil
  end
  def read(serial)
    @value ? @value : @values.shift 
  end
  def write(serial, value)
    @stored_value = value
  end
end

class MockOWUnderlying
  attr_accessor :value
  def initialize(opts={})
    @value = opts[:value]
  end
  def read(cached)
    @value
  end
  def write(value)
    @value = value
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
  def last_value(sensor)
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
    @fake = fake_sensor('fake')
  end

  def test_last_value
    @dbstore.value = 55.3
    assert_equal 55.3, @fake.last_value
  end

  def test_write_causes_store
    @fake.underlying = MockOWUnderlying.new(:value => 5)
    assert_equal 5, @fake.read
    @fake.write(10)
    assert_equal 10, @dbstore.stored_value
    assert_equal 10, @fake.underlying.value
  end

  def test_outlier_removal
    sensor = fake_sensor('fake')
    @conn.values = [1000.0,1.0,1.0]
    assert_equal 1.0, sensor.read
  end

  def test_outlier_removal_with_nils
    sensor = fake_sensor('fake')
    @conn.values = [1000.0,nil,1.0]
    assert_equal 1000.0, sensor.read
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

  def test_sensor_type
    [:pressure, :humidity, :temperature].each do |type|
      assert_equal type, fake_sensor(type.to_s).sensor_type
    end
  end

  def test_mocked
    @mockable = fake_sensor('fake')
    @conn.value = 1.0
    assert_equal 1.0, @mockable.read
    @mockable.mock_set(:value => 2.0)
    assert_equal 2.0, @mockable.read
    @mockable.write(3.0)
    assert_equal 3.0, @mockable.read
    @mockable.mock_set(:minimum => 1.0, :average => 2.0, :maximum => 3.0, :last_value => 5.0)
    assert_equal 1.0, @mockable.minimum(0,100)
    assert_equal 2.0, @mockable.average(0,100)
    assert_equal 3.0, @mockable.maximum(0,100)
    assert_equal 5.0, @mockable.last_value
    assert_equal 3.0, @mockable.read
  end
end
