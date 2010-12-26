require File.dirname(__FILE__)+'/test_helper.rb'
require 'webrick'
#require 'webrick/accesslog'

class TestDINRelay < Test::Unit::TestCase
  SERVICE_OPTS = {:host => 'localhost', :port => 33333, 
                  :user => "someuser", :pass =>"somepass"}

  class BasicServing < WEBrick::HTTPServlet::AbstractServlet
    def self.get_instance(config, opts)
      new(opts)
    end
    def initialize(opts)
      @html = opts[:html]
      @user = opts[:user]
      @pass = opts[:pass]
      @feedback = opts[:feedback] || {}
    end
    def do_GET(req, res)
      @feedback[:uri] = req.request_uri.to_s
      WEBrick::HTTPAuth.basic_auth(req, res, "My Realm") {|user, pass|
        user == @user && pass == @pass
      }
      res.body = @html
      res['Content-Type'] = "text/xml"
    end
  end

  def with_webrick(opts)
    opts = SERVICE_OPTS.merge(opts)

    Socket.do_not_reverse_lookup = true # Speed up startup
    log = WEBrick::Log.new($stderr, WEBrick::Log::ERROR)
    access_log = [[log, WEBrick::AccessLog::COMBINED_LOG_FORMAT]]
    s = WEBrick::HTTPServer.new(:Port => opts[:port], 
                                :Logger => log,
                                :AccessLog => access_log)
    s.mount('/', BasicServing, opts.merge(:feedback => (f = {})))
    
    thread = Thread.new do
      s.start
    end
    while s.status != :Running; sleep 0.1; end # Make sure the server is up
    yield f
    s.shutdown
    thread.exit
  end

  def create_index_html(hash)
    outlets = hash
    erb = ERB.new(File.open(File.dirname(__FILE__)+'/dinrelay.html.erb').read)
    erb.result(binding)
  end

  def setup
    @og=SAAL::DINRelay::OutletGroup.new(SERVICE_OPTS)
    @vals={1=>"OFF",2=>"OFF",3=>"ON",4=>"OFF",5=>"ON",6=>"ON",7=>"ON",8=>"OFF"}
    @rvals={1=>"ON",2=>"ON",3=>"OFF",4=>"ON",5=>"OFF",6=>"OFF",7=>"OFF",8=>"ON"}
  end

  def assert_path(path, uri)
    assert_equal "http://localhost:#{SERVICE_OPTS[:port]}"+path, uri
  end

  def test_read_state
    with_webrick(:html=>create_index_html(@vals)) do |feedback|
      @vals.each do |num, state|
        assert_equal state, @og.state(num)
        assert_path '/index.htm', feedback[:uri]
      end
    end
  end

  def test_set_state
    with_webrick(:html=>create_index_html(@rvals)) do |feedback|
      @vals.each do |num, state|
        newstate = state == "ON" ? "OFF" : "ON"
        assert @og.set_state(num,newstate), "State change not working"
        assert_path "/outlet?#{num}=#{newstate}", feedback[:uri]
      end
    end
  end

  def test_enumerate_sensors
    sensors = SAAL::Sensors.new(TEST_SENSORS_DINRELAY_FILE, TEST_DBCONF)
    assert_equal((1..8).map{|i| "name#{i}"}, sensors.map{|s| s.name}.sort)
  end

  def test_read_sensors
    sensors = SAAL::Sensors.new(TEST_SENSORS_DINRELAY_FILE, TEST_DBCONF)
    with_webrick(:html=>create_index_html(@vals)) do |feedback|
      @vals.each do |num, state|
        value = state == "ON" ? 1.0 : 0.0
        assert_equal value, sensors.send('name'+num.to_s).read
        assert_path '/index.htm', feedback[:uri]
      end
    end
  end

  def test_set_sensors
    sensors = SAAL::Sensors.new(TEST_SENSORS_DINRELAY_FILE, TEST_DBCONF)
    with_webrick(:html=>create_index_html(@rvals)) do |feedback|
      @vals.each do |num, state|
        newval = state == "ON" ? 0.0 : 1.0
        newstate = state == "ON" ? "OFF" : "ON"
        assert_equal newval, sensors.send('name'+num.to_s).set(newval), 
                     "State change not working"
        assert_path "/outlet?#{num}=#{newstate}", feedback[:uri]
      end
    end
  end
end
