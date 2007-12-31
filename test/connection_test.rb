require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

class TestConnection < Test::Unit::TestCase
  def mock_server(expect_receive, response)
    test_port = 22500+rand(5000)
    @servpid = SAAL::ForkedRunner.run_as_fork(:keep_stdin => true) do |fr|
      serv = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0 )
      sockaddr = Socket.pack_sockaddr_in(test_port, 'localhost')
      serv.bind sockaddr
      serv.listen 5
      socket, client_addr = serv.accept
      assert_equal expect_receive, socket.readline
      socket.write response
      socket.close
      serv.close
    end
    test_port
  end
    
  def test_read
    test_port = mock_server("GET fake_temp\n", "fake_temp 20\n")
    sleep 1
    assert_equal 20, SAAL::Connection.new(:port => test_port).read('fake_temp')
  end 
  
  def test_average
    test_port = mock_server("AVERAGE fake_temp 10 20\n", "fake_temp 20\n")
    sleep 1
    avg = SAAL::Connection.new(:port => test_port).average('fake_temp', 10, 20)
    assert_equal 20, avg
  end  
  
  def teardown
    Process.waitpid(@servpid)
  end
end
