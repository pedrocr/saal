require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

class TestDaemon < Test::Unit::TestCase
  include TestWithDB
  def test_working_daemon
    nsecs = 0.5
    interval = 0.00001
    with_fake_owserver do
      d = SAAL::Daemon.new(:keep_stdin => true,
                           :interval => interval, 
                           :dbconf => TEST_DBCONF, 
                           :sensorconf => TEST_SENSORS_FILE)
      pid = d.run
      sleep nsecs # Potential timing bug when the system is under load
      Process.kill("TERM", pid)
      Process.waitpid(pid)
    end

    db_test_query("SELECT * FROM sensor_reads") do |res|
      assert res.num_rows > 0
    end
  end

  def test_empty_reads_daemon
    nsecs = 0.5
    interval = 0.00001
    with_fake_owserver do
      d = SAAL::Daemon.new(:keep_stdin => true,
                           :interval => interval, 
                           :dbconf => TEST_DBCONF, 
                           :sensorconf => TEST_NONEXIST_SENSOR_FILE)
      pid = d.run
      sleep nsecs # Potential timing bug when the system is under load
      Process.kill("TERM", pid)
      Process.waitpid(pid)
    end

    db_test_query("SELECT * FROM sensor_reads") do |res|
      assert res.num_rows == 0
    end
  end
end
