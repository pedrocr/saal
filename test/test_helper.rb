require 'test/unit'
require 'yaml'
require 'fileutils'
require File.dirname(__FILE__)+'/../lib/saal.rb'

class Test::Unit::TestCase
  TEST_DBFILE = File.dirname(__FILE__)+'/test.db'
  TEST_SENSOR_FILE1 = File.dirname(__FILE__)+'/sample_sensors.yml'
  TEST_SENSOR_FILE2 = File.dirname(__FILE__)+'/sample_sensors2.yml'
  
  def with_fake_owserver
    pid = fork do 
      exec("/opt/bin/owserver", "--fake", "1F,10", "--foreground")
    end
    sleep 1 # Potential timing bug when the system is under load
    yield
    Process.kill("TERM", pid)
    Process.waitpid(pid)
  end
end
