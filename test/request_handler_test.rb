require File.dirname(__FILE__) + '/test_helper.rb'
require 'time'

MOCK_TEMP = 50
class MockForkedRunner; end
class MockFstore; end
class MockSensors;
  def fake_temp; MockFakeTemp.new; end 
  def non_existat; MockNonExistant.new; end
end
class MockFakeTemp; def read; 50; end; end
class MockNonExistant; def read; nil; end; end

class MockSocket
  def initialize; @content = []; end
  def read; @content.pop; end
  def readline; read end
  def write(value); @content.push(value); end
end

class TestRequestHandler < Test::Unit::TestCase
  def setup
    @s = MockSocket.new
    @fstore = MockFstore.new
    @sensors = MockSensors.new
    @fr = MockForkedRunner.new
    @rhandler = SAAL::RequestHandler.new(@s, @fstore, @sensors, @fr)
  end  
    
  def test_get
    @rhandler.handle_command("GET fake_temp\n")
    values = @s.readline.split
    assert_equal 2, values.size
    assert_in_delta Time.now.utc.to_i, values[0].to_i, 100
    assert_equal MOCK_TEMP, values[1].to_f
  end
  
  def test_wrong_command
    @rhandler.handle_command("WRONG_COMMAND fake_temp\n")
    assert_equal "No such command\n", @s.readline
  end
  
  def test_run
    @s.write("GET fake_temp\n")
    @rhandler.run
    values = @s.readline.split
    assert_equal 2, values.size
    assert_in_delta Time.now.utc.to_i, values[0].to_i, 100
    assert_equal MOCK_TEMP, values[1].to_f 
  end
end
