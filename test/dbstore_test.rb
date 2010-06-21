require File.dirname(__FILE__)+'/test_helper.rb'

class TestFileStore < Test::Unit::TestCase
  include TestWithDB
  def test_insert
    test_time = 1196024160
    test_value = 7.323
    
    @dbstore.write(:test_sensor, test_time, test_value)
    
    db_test_query("SELECT * FROM sensor_reads") do |res|
      assert_equal 1, res.num_rows
      assert_equal ["test_sensor", test_time.to_s, test_value.to_s], res.fetch_row
    end
  end
  
  def test_average
    test_values = [[10, 7.323],[12, 5.432],[23, -2.125], [44, 0.123]]
    test_average = (5.432 - 2.125)/2.0
    test_values.each do |values|
      @dbstore.write(:test_sensor, *values)
    end
    
    assert_in_delta test_average, @dbstore.average(:test_sensor, 11, 25), 0.001
    assert_in_delta test_average, @dbstore.average(:test_sensor, 12, 25), 0.001
    assert_in_delta test_average, @dbstore.average(:test_sensor, 12, 23), 0.001
    
    # when there are no points it's nil
    assert_nil @dbstore.average(:test_sensor, 50, 60)
  end
end
