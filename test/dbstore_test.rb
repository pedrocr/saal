require File.dirname(__FILE__)+'/test_helper.rb'

class TestFileStore < Test::Unit::TestCase
  def setup
    @fstore = SAAL::FileStore.new(:db => TEST_DBFILE)
  end

  def test_insert
    test_time = 1196024160
    test_value = 7.323
    
    @fstore.write(:test_sensor, test_time, test_value)
    @fstore.close
    
    db = SQLite3::Database.new(TEST_DBFILE)
    db.type_translation = true
    $-w = false # disable sqlite warning message
    rows = db.execute("select * from sensor_reads")
    $-w = true
    assert_equal [["test_sensor", test_time, test_value]], rows
  end
  
  def test_average
    test_values = [[10, 7.323],[12, 5.432],[23, -2.125], [44, 0.123]]
    test_average = (5.432 - 2.125)/2.0
    test_values.each do |values|
      @fstore.write(:test_sensor, *values)
    end
    
    assert_in_delta test_average, @fstore.average(:test_sensor, 11, 25), 0.001
    assert_in_delta test_average, @fstore.average(:test_sensor, 12, 25), 0.001
    assert_in_delta test_average, @fstore.average(:test_sensor, 12, 23), 0.001
    
    # when there are no points it's nil
    assert_nil @fstore.average(:test_sensor, 50, 60)
  end
  
  def teardown
    FileUtils.rm_f TEST_DBFILE
  end
end
