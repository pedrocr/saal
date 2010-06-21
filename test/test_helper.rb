require 'test/unit'
require 'yaml'
require 'fileutils'
require File.dirname(__FILE__)+'/../lib/saal.rb'

class Test::Unit::TestCase
  TEST_SENSOR_FILE1 = File.dirname(__FILE__)+'/sample_sensors.yml'
  TEST_SENSOR_FILE2 = File.dirname(__FILE__)+'/sample_sensors2.yml'

  def with_fake_owserver
    start_fake_owserver
    yield
    stop_fake_owserver
  end
  
  def start_fake_owserver
    @owserver_pid = fork do 
      exec("owserver", "--fake", "1F,10", "--foreground")
    end
    sleep 1 # Potential timing bug when the system is under load
  end
  
  def stop_fake_owserver
    Process.kill("TERM", @owserver_pid)
    Process.waitpid(@owserver_pid)
  end
end

module TestWithDB
  TEST_DBOPTS = {:host => 'localhost',
                 :user => 'sensor_reads',
                 :pass => 'abcd',
                 :db => 'sensor_reads_test'}

  def setup
    @dbstore = SAAL::DBStore.new(TEST_DBOPTS, true)
    @dbstore.db_wipe
    @dbstore.db_initialize
  end

  def db_test_query(query)  
    db = Mysql.new(TEST_DBOPTS[:host],TEST_DBOPTS[:user],
                   TEST_DBOPTS[:pass],TEST_DBOPTS[:db])
    res = db.query(query)
    yield res
    db.close
  end
end
