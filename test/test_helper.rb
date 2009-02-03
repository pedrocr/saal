require 'test/unit'
require 'yaml'
require 'fileutils'
require File.dirname(__FILE__)+'/../lib/saal.rb'

class Test::Unit::TestCase
  TEST_DBFILE = File.dirname(__FILE__)+'/test.db'
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
