require File.dirname(__FILE__)+'/test_helper.rb'

class TestFileStore < Test::Unit::TestCase
  TEST_DBOPTS = {:host => 'localhost',
                 :user => 'sensor_reads',
                 :pass => 'abcd',
                 :db => 'sensor_reads_test'}
  TEST_DBARGS = [TEST_DBOPTS[:host],TEST_DBOPTS[:user],
                 TEST_DBOPTS[:pass],TEST_DBOPTS[:db]]


  def setup
    @dbstore = SAAL::DBStore.new(TEST_DBOPTS, true)
    @dbstore.db_wipe
    @dbstore.db_initialize
  end

  def test_insert
    test_time = 1196024160
    test_value = 7.323
    
    @dbstore.write(:test_sensor, test_time, test_value)
    
    db = Mysql.new(*TEST_DBARGS)
    res = db.query("SELECT * FROM sensor_reads")
    assert_equal 1, res.num_rows
    assert_equal ["test_sensor", test_time.to_s, test_value.to_s], res.fetch_row
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
