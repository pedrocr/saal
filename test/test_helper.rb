require 'test/unit'
require 'yaml'
require 'fileutils'
require File.dirname(__FILE__)+'/../lib/saal.rb'

class Test::Unit::TestCase
  TEST_SENSORS_FILE = File.dirname(__FILE__)+'/test_sensors.yml'
  TEST_SENSORS_DINRELAY_FILE = File.dirname(__FILE__)+'/test_dinrelay_sensors.yml'
  TEST_SENSORS_DENKOVI_FILE = File.dirname(__FILE__)+'/test_denkovi_sensors.yml'
  TEST_SENSOR_CLEANUPS_FILE = File.dirname(__FILE__)+'/test_sensor_cleanups.yml'
  TEST_NONEXIST_SENSOR_FILE = File.dirname(__FILE__)+'/nonexistant_sensor.yml'
  TEST_CHARTS_FILE = File.dirname(__FILE__)+'/test_charts.yml'
  TEST_DBCONF = File.dirname(__FILE__)+'/test_db.yml'
  TEST_DBOPTS = YAML::load(File.new(TEST_DBCONF))

  def with_fake_owserver
    pid = fork do 
      exec("owserver", "--fake", "1F,10", "--foreground")
    end
    sleep 1 # Potential timing bug when the system is under load
    yield
    Process.kill("KILL", pid)
    Process.waitpid(pid)
  end

  def db_setup
    @dbstore = SAAL::DBStore.new(TEST_DBCONF)
    @dbstore.db_wipe
    @dbstore.db_initialize
  end

  def db_test_query(query)  
    db = Mysql2::Client.new(TEST_DBOPTS)
    res = db.query(query)
    yield res
    db.close
  end
end
