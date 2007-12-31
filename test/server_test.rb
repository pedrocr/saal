require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

class TestServer < Test::Unit::TestCase
  TEST_PORT = 22500+rand(5000)

  def setup
    start_fake_owserver
    @daemon = SAAL::Daemon.new(:interval => 0.0001, :db => TEST_DBFILE, 
                               :conf => TEST_SENSOR_FILE1, :port => TEST_PORT)
    @daemonpid = @daemon.run
    sleep 0.5 # Possible timing bug if this isn't enough for startup
    @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    @socket.connect(Socket.pack_sockaddr_in(TEST_PORT, "localhost"))
  end  
  
  def test_good_read
    @socket.write("GET fake_temp\n")
    result = @socket.readline
    values = result.split
    assert_equal 2, values.size
    assert_equal "fake_temp", values[0]
    assert_in_delta 0, values[1].to_f, 200    
  end  
  
  def teardown
    @socket.close
    Process.kill("TERM", @daemonpid)
    Process.waitpid(@daemonpid)
    stop_fake_owserver
    FileUtils.rm_f TEST_DBFILE
  end
end
