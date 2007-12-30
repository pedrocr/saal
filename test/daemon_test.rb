require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

class TestSensors < Test::Unit::TestCase
  def test_daemon
    ["TERM", "INT"].each do |signal|
      nsecs = 0.1
      interval = 0.00001
      with_fake_owserver do
        d = SAAL::Daemon.new(:interval => interval, :db => TEST_DBFILE, 
                            :conf => TEST_SENSOR_FILE2)
        pid = d.run
        sleep nsecs # Potential timing bug when the system is under load
        Process.kill(signal, pid)
        Process.waitpid(pid)
      end

      $-w = false # disable sqlite warning messages    
      db = SQLite3::Database.new(TEST_DBFILE)
      db.type_translation = true
      rows = db.execute("select * from sensor_reads")
      assert rows.size > 0
      $-w = true
    end
  end
  
  def teardown
    FileUtils.rm_f TEST_DBFILE
  end
end
