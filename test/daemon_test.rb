require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

class TestDaemon < Test::Unit::TestCase
  include TestWithDB
  def test_daemon
    nsecs = 0.5
    interval = 0.00001
    with_fake_owserver do
      d = SAAL::Daemon.new(:interval => interval, 
                           :db => TEST_DBOPTS, 
                           :sensors => {:conf => TEST_SENSOR_FILE1})
      pid = d.run
      sleep nsecs # Potential timing bug when the system is under load
      Process.kill("TERM", pid)
      Process.waitpid(pid)
    end

    db_test_query("SELECT * FROM sensor_reads") do |res|
      assert res.num_rows > 0
    end
  end
end
