require File.dirname(__FILE__)+'/test_helper.rb'

class TestSensors < Test::Unit::TestCase
  def setup
    @defs = YAML::load File.new(TEST_SENSORS_FILE)
    @sensors = SAAL::Sensors.new(TEST_SENSORS_FILE, TEST_DBCONF)
  end
    
  def test_get_sensor
    @defs.each do |name, value|
      s = @sensors.send name
      assert_equal s.description, value['name']
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
    assert_equal expected, @sensors.map {|name, sensor| [name, sensor.description]}
  end

  def test_average
    db_setup

    test_values = [[10, 7.323],[12, 5.432],[23, -2.125], [44, 0.123]]
    test_average = (5.432 - 2.125)/2.0
    test_values.each do |values|
      @dbstore.write(:fake_temp, *values)
    end
    
    assert_instance_of Float, @sensors.fake_temp.average(11, 25)
    assert_in_delta test_average, @sensors.fake_temp.average(11, 25), 0.001
    assert_in_delta test_average, @sensors.fake_temp.average(12, 25), 0.001
    assert_in_delta test_average, @sensors.fake_temp.average(11, 23), 0.001
    
    # when there are no points it's nil
    assert_nil @sensors.fake_temp.average(50, 60)
  end

  def test_store_value
    db_setup
    
    @sensors.fake_temp.store_value

    db_test_query("SELECT * FROM sensor_reads") do |res|
      assert_equal 1, res.num_rows
      row = res.fetch_row
      assert_equal "fake_temp", row[0]
      assert_in_delta Time.now.utc.to_i, row[1], 100
      assert_instance_of Float, row[2].to_f
    end
  end  
end
