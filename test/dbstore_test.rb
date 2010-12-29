require File.dirname(__FILE__)+'/test_helper.rb'

class TestFileStore < Test::Unit::TestCase
  def test_insert
    db_setup
    test_time = 1196024160
    test_value = 7.323
    
    @dbstore.write(:test_sensor, test_time, test_value)
    
    db_test_query("SELECT * FROM sensor_reads") do |res|
      assert_equal 1, res.num_rows
      assert_equal ["test_sensor", test_time.to_s, test_value.to_s], res.fetch_row
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
end
