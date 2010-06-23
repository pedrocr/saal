require 'test/unit'
require 'yaml'
require 'fileutils'
require File.dirname(__FILE__)+'/../lib/saal.rb'

class Test::Unit::TestCase
  TEST_SENSORS_FILE = File.dirname(__FILE__)+'/test_sensors.yml'
  TEST_NONEXIST_SENSOR_FILE = File.dirname(__FILE__)+'/nonexistant_sensor.yml'
  TEST_DBCONF = File.dirname(__FILE__)+'/test_db.yml'
  TEST_DBOPTS = YAML::load(File.new(TEST_DBCONF))

  def with_fake_owserver
    pid = fork do 
      exec("owserver", "--fake", "1F,10", "--foreground")
    end
    sleep 1 # Potential timing bug when the system is under load
    yield
    Process.kill("TERM", pid)
    Process.waitpid(pid)
  end

  def db_setup
    @dbstore = SAAL::DBStore.new(TEST_DBCONF)
    @dbstore.db_wipe
    @dbstore.db_initialize
  end

  def db_test_query(query)  
    db = Mysql.new(TEST_DBOPTS['host'],TEST_DBOPTS['user'],
                   TEST_DBOPTS['pass'],TEST_DBOPTS['db'])
    res = db.query(query)
    yield res
    db.close
  end
end
