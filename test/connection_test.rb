require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

class TestConnection < Test::Unit::TestCase
  TEST_PORT = 22500+rand(5000)
  
  def mock_server(expect_receive, response)
    @servpid = SAAL::ForkedRunner.run_as_fork(:keep_stdin => true) do |fr|
      serv = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0 )
      sockaddr = Socket.pack_sockaddr_in(TEST_PORT, 'localhost')
      serv.bind sockaddr
      serv.listen 5
      socket, client_addr = serv.accept
      assert_equal expect_receive, socket.readline
      socket.write response
      socket.close
      serv.close
    end
  end
    
  def test_read
    mock_server("GET fake_temp\n", "fake_temp 20\n")
    sleep 1
    assert_equal 20, SAAL::Connection.new(:port => TEST_PORT).read('fake_temp')
  end  
  
  def teardown
    Process.waitpid(@servpid)
  end
end
