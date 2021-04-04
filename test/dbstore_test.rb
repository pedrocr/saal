require File.dirname(__FILE__)+'/test_helper.rb'

class TestFileStore < Test::Unit::TestCase
  def test_insert
    db_setup
    test_time = 1196024160
    test_value = 7.323
    
    @dbstore.write(:test_sensor, test_time, test_value)
    
    db_test_query("SELECT * FROM sensor_reads") do |res|
      assert_equal 1, res.count
      row = res.first
      assert_equal "test_sensor", row["sensor"]
      assert_equal test_time, row["date"].to_i
      assert_equal test_value, row["value"].to_f
    end
  end

  def test_insert_nil
    db_setup
    
    assert_raise(ArgumentError) {@dbstore.write(:test_sensor, 1, nil)}
    assert_raise(ArgumentError) {@dbstore.write(:test_sensor, 0, 1)}
    assert_raise(ArgumentError) {@dbstore.write(:test_sensor, nil, 1)}
  end
  
  def test_average
    db_setup
    test_values = [[10, 7.323],[12, 5.432],[23, -2.125], [44, 0.123]]
    test_average = (5.432 - 2.125)/2.0
    test_values.each do |values|
      @dbstore.write(:test_sensor, *values)
    end
    
    assert_instance_of Float, @dbstore.average(:test_sensor, 11, 25)
    assert_in_delta test_average, @dbstore.average(:test_sensor, 11, 25), 0.001
    assert_in_delta test_average, @dbstore.average(:test_sensor, 12, 25), 0.001
    assert_in_delta test_average, @dbstore.average(:test_sensor, 12, 23), 0.001
    
    # when there are no points it's nil
    assert_nil @dbstore.average(:test_sensor, 50, 60)
  end

  def test_weighted_average
    db_setup
    test_values = [[10, 7.323],[12, 5.432],[23, -2.125], [44, 0.123]]
    test_average = ((12-10)*7.323+(23-12)*5.432+(44-23)*(-2.125)) / (44-10)
    test_values.each do |values|
      @dbstore.write(:test_sensor, *values)
    end

    assert_instance_of Float, @dbstore.average(:test_sensor, 10, 44)
    assert_in_delta test_average, @dbstore.weighted_average(:test_sensor, 10, 44), 0.001

    # when there are no points it's nil
    assert_nil @dbstore.weighted_average(:test_sensor, 50, 60)
  end

  def test_min_max
    db_setup
    test_values = [[10, 7.323],[12, 5.432],[23, -2.125], [44, 0.123]]
    test_values.each do |values|
      @dbstore.write(:test_sensor, *values)
    end

    [[:minimum, -2.125], [:maximum, 5.432]].each do |func, value|
      assert_instance_of Float, @dbstore.send(func, :test_sensor, 11, 25)
      assert_in_delta value, @dbstore.send(func,:test_sensor, 11, 25), 0.0001
      assert_in_delta value, @dbstore.send(func,:test_sensor, 12, 25), 0.0001
      assert_in_delta value, @dbstore.send(func,:test_sensor, 12, 23), 0.0001
      
      # when there are no points it's nil
      assert_nil @dbstore.send(func,:test_sensor, 50, 60)
    end
  end

  def test_enumerable
    db_setup
    test_time = 1196024160
    test_value = 7.323
    n = 5
    
    n.times {@dbstore.write(:test_sensor, test_time, test_value)}
    assert_equal [["test_sensor", test_time, test_value]]*n,
                 @dbstore.map{|sensor,time,value| [sensor,time,value]}   
  end

  def test_last_value
    db_setup
    now = Time.now.utc.to_i
    test_values = [[now-10, 105.0],[now-5, 95.0],[now-2, 100.0],[now, 100.5]]
    test_values.each do |values|
      @dbstore.write(:test_sensor, *values)
    end
    assert_equal 100.5, @dbstore.last_value(:test_sensor)
  end

  def test_last_value_stale
    db_setup
    now = Time.now.utc.to_i - SAAL::DBStore::MAX_LAST_VAL_AGE - 100
    test_values = [[now-10, 105.0],[now-5, 95.0],[now-2, 100.0],[now, 100.5]]
    test_values.each do |values|
      @dbstore.write(:test_sensor, *values)
    end
    assert_equal nil, @dbstore.last_value(:test_sensor)
  end
end
