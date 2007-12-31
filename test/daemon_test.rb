require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

class TestDaemon < Test::Unit::TestCase
  TEST_PORT = 22500+rand(5000)
  
  def test_daemon
    nsecs = 0.5
    interval = 0.00001
    with_fake_owserver do
      d = SAAL::Daemon.new(:interval => interval, :db => TEST_DBFILE, 
                           :conf => TEST_SENSOR_FILE1, :port => TEST_PORT)
      pid = d.run
      sleep nsecs # Potential timing bug when the system is under load
      Process.kill("TERM", pid)
      Process.waitpid(pid)
    end

    $-w = false # disable sqlite warning messages    
    db = SQLite3::Database.new(TEST_DBFILE)
    db.type_translation = true
    rows = db.execute("select * from sensor_reads")
    assert rows.size > 0
    $-w = true
  end
    
  def teardown
    FileUtils.rm_f TEST_DBFILE
  end
end
