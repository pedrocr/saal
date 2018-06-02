require File.dirname(__FILE__)+'/test_helper.rb'
require 'webrick'
require 'benchmark'

class TestDINRelay < Test::Unit::TestCase
  def setup
    @@serv_num ||= 0
    @@serv_num += 1

    @og=SAAL::DINRelay::OutletGroup.new(service_opts)
    @vals={1=>"OFF",2=>"OFF",3=>"ON",4=>"OFF",5=>"ON",6=>"ON",7=>"ON",8=>"OFF"}
    @rvals={1=>"ON",2=>"ON",3=>"OFF",4=>"ON",5=>"OFF",6=>"OFF",7=>"OFF",8=>"ON"}

    defs = YAML::load(File.new(TEST_SENSORS_DINRELAY_FILE))
    defs['group1']['dinrelay']['port'] = service_opts[:port]
    tempfile = Tempfile.new('dinrelay_test_yml')
    File.open(tempfile.path,'w') {|f| f.write(YAML::dump defs)}
    @test_sensors_dinrelay_file = tempfile.path
  end

  def service_opts
    base_opts = {:host => 'localhost', :user => "someuser", :pass =>"somepass"}
    base_opts.merge(:port => 3333+@@serv_num)
  end

  class BasicServing < WEBrick::HTTPServlet::AbstractServlet
    def self.get_instance(config, opts)
      new(opts)
    end
    def initialize(opts)
      @html = opts[:html]
      @user = opts[:user]
      @pass = opts[:pass]
      @status = opts[:status] || 200
      @feedback = opts[:feedback] || {}
      @sleep = opts[:sleep] || 0
    end
    def do_GET(req, res)
      sleep @sleep
      @feedback[:uris] ||= []
      @feedback[:uris] << req.request_uri.to_s
      @feedback[:uri] = req.request_uri.to_s
      @feedback[:nrequests] = (@feedback[:nrequests]||0)+1
      WEBrick::HTTPAuth.basic_auth(req, res, "My Realm") {|user, pass|
        user == @user && pass == @pass
      }
      res.body = @html
      res.status = @status
      res['Content-Type'] = "text/html"
    end
  end

  def with_webrick(opts)
    opts = service_opts.merge(opts)  

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

  def assert_path(path, uri)
    assert_equal "http://localhost:#{service_opts[:port]}"+path, uri
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
    sensors = SAAL::Sensors.new(@test_sensors_dinrelay_file, TEST_DBCONF)
    assert_equal((1..8).map{|i| "name#{i}"}, sensors.map{|s| s.name}.sort)
    assert_equal((1..8).map{|i| "description#{i}"}, sensors.map{|s| s.description}.sort)
  end

  def test_sensor_type
    SAAL::Sensors.new(TEST_SENSORS_DINRELAY_FILE, TEST_DBCONF).each do |s|
      assert_equal :onoff, s.sensor_type
    end
  end

  def test_read_sensors
    sensors = SAAL::Sensors.new(@test_sensors_dinrelay_file, TEST_DBCONF)
    with_webrick(:html=>create_index_html(@vals)) do |feedback|
      @vals.each do |num, state|
        value = state == "ON" ? 1.0 : 0.0
        assert_equal value, sensors.send('name'+num.to_s).read
        assert_path '/index.htm', feedback[:uri]
      end
      assert_equal 1, feedback[:nrequests], "dinrelay request caching not working"
    end
  end

  def test_set_sensors
    sensors = SAAL::Sensors.new(@test_sensors_dinrelay_file, TEST_DBCONF)
    with_webrick(:html=>create_index_html(@rvals)) do |feedback|
      @vals.each do |num, state|
        newval = state == "ON" ? 0.0 : 1.0
        newstate = state == "ON" ? "OFF" : "ON"
        assert_equal newval, sensors.send('name'+num.to_s).write(newval), 
                     "State change not working"
        assert_path "/outlet?#{num}=#{newstate}", feedback[:uris][-2]
        assert_path "/index.htm", feedback[:uris][-1]
      end
    end
  end

  # Test that write invalidates any caching
  def test_write_read_sensors
    sensors = SAAL::Sensors.new(@test_sensors_dinrelay_file, TEST_DBCONF)
    with_webrick(:html=>create_index_html(@vals)) do |feedback|
      @vals.each do |num, state|
        sensors.send('name'+num.to_s).write(0.0)
        sensors.send('name'+num.to_s).read
      end
      assert_equal 16, feedback[:nrequests], "dinrelay caching too much"
    end
  end

  # Test that the cache times out
  def test_cache_invalidation
    _sensors = SAAL::Sensors.new(@test_sensors_dinrelay_file, TEST_DBCONF)
    @og.cache_timeout = 0.1
    with_webrick(:html=>create_index_html(@vals)) do |feedback|
      @og.state(1)
      sleep 0.2
      @og.state(1)
      assert_equal 2, feedback[:nrequests], "dinrelay caching not invalidating"
    end
  end

  def test_failed_connection
    @vals.each do |num, state|
      assert_equal nil, @og.state(num)
      assert !@og.set_state(num,"ON"), "State change working without a server?!"
    end
  end

  def test_failed_request
    with_webrick(:html=>create_index_html(@vals),:status=>404) do |feedback|
      @vals.each do |num, state|
        assert_equal nil, @og.state(num)
        assert !@og.set_state(num,"ON"), "State change working without a server?!"
      end
    end
  end

  def test_fast_open_timeout
    #FIXME: Find a way to make this test address more generic
    @og=SAAL::DINRelay::OutletGroup.new(service_opts.merge(:host => "10.254.254.254", 
                                                           :timeout=>0.1))
    with_webrick(:html=>create_index_html(@vals)) do |feedback|
      time = Benchmark.measure do
        @vals.each do |num, state|
          assert_equal nil, @og.state(num), "Read not timing out?"
          assert !@og.set_state(num,"ON"), "State change not timing out?"
        end
      end
      total_time = @og.timeout*2*@vals.keys.size
      assert time.total < total_time
             "Doing the reads took too long, are we really timing out?"
    end
  end

  def test_fast_read_timeout
    @og=SAAL::DINRelay::OutletGroup.new(service_opts.merge(:timeout=>0.1))
    with_webrick(:html=>create_index_html(@vals),:sleep=>10) do |feedback|
      time = Benchmark.measure do
        @vals.each do |num, state|
          assert_equal nil, @og.state(num), "Read not timing out?"
          assert !@og.set_state(num,"ON"), "State change not timing out?"
        end
      end
      total_time = @og.timeout*2*@vals.keys.size
      assert time.total < total_time
             "Doing the reads took too long, are we really timing out?"
    end
  end
end
