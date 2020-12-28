require File.dirname(__FILE__)+'/test_helper.rb'
require 'webrick'
require 'benchmark'

class TestDenkoviRelay < Test::Unit::TestCase
  def setup
    @@serv_num ||= 0
    @@serv_num += 1

    @og=SAAL::Denkovi::OutletGroup.new(service_opts)
    @vals={1=>"OFF",2=>"OFF",3=>"ON",4=>"OFF",5=>"ON",6=>"ON",7=>"ON",8=>"OFF",
           9=>"OFF",10=>"OFF",11=>"ON",12=>"OFF",13=>"ON",14=>"ON",15=>"ON",16=>"OFF"}
    @rvals={1=>"ON",2=>"ON",3=>"OFF",4=>"ON",5=>"OFF",6=>"OFF",7=>"OFF",8=>"ON",
            9=>"ON",10=>"ON",11=>"OFF",12=>"ON",13=>"OFF",14=>"OFF",15=>"OFF",16=>"ON"}

    defs = YAML::load(File.new(TEST_SENSORS_DENKOVI_FILE))
    @pass = defs["group1"]["denkovi"]["pass"]
    defs['group1']['denkovi']['port'] = service_opts[:port]
    tempfile = Tempfile.new('denkovi_test_yml')
    File.open(tempfile.path,'w') {|f| f.write(YAML::dump defs)}
    @test_sensors_denkovi_file = tempfile.path
  end

  def service_opts
    base_opts = {:host => 'localhost', :pass =>"somepass"}
    base_opts.merge(:port => 3333+@@serv_num)
  end

  class BasicServing < WEBrick::HTTPServlet::AbstractServlet
    def self.get_instance(config, opts)
      new(opts)
    end
    def initialize(opts)
      @html = opts[:html]
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

  def create_current_state_json(hash)
    outlets = hash
    erb = ERB.new(File.open(File.dirname(__FILE__)+'/denkovi.json.erb').read)
    erb.result(binding)
  end

  def assert_path(path, uri)
    assert_equal "http://localhost:#{service_opts[:port]}"+path, uri
  end

  def test_read_state
    with_webrick(:html=>create_current_state_json(@vals)) do |feedback|
      @vals.each do |num, state|
        assert_equal state, @og.state(num)
        assert_path "/current_state.json?pw=#{@pass}", feedback[:uri]
      end
    end
  end

  def test_set_state
    with_webrick(:html=>create_current_state_json(@rvals)) do |feedback|
      @vals.each do |num, state|
        newstate = state == "ON" ? "OFF" : "ON"
        val = {"ON" => "1", "OFF" => "0"}[newstate]
        assert @og.set_state(num,newstate), "State change not working"
        assert_path "/current_state.json?pw=#{@pass}&Relay#{num}=#{val}", feedback[:uri]
      end
    end
  end

  def test_enumerate_sensors
    sensors = SAAL::Sensors.new(@test_sensors_denkovi_file, TEST_DBCONF)
    assert_equal((1..16).map{|i| "name#{i.to_s.rjust(2, "0")}"}, sensors.map{|s| s.name}.sort)
    assert_equal((1..16).map{|i| "description#{i.to_s.rjust(2, "0")}"}, sensors.map{|s| s.description}.sort)
  end

  def test_sensor_type
    SAAL::Sensors.new(TEST_SENSORS_DENKOVI_FILE, TEST_DBCONF).each do |s|
      assert_equal :onoff, s.sensor_type
    end
  end

  def test_read_sensors
    sensors = SAAL::Sensors.new(@test_sensors_denkovi_file, TEST_DBCONF)
    with_webrick(:html=>create_current_state_json(@vals)) do |feedback|
      @vals.each do |num, state|
        value = state == "ON" ? 1.0 : 0.0
        assert_equal value, sensors.send('name'+num.to_s.rjust(2, "0")).read
        assert_path "/current_state.json?pw=#{@pass}", feedback[:uri]
      end
      assert_equal 1, feedback[:nrequests], "denkovi request caching not working"
    end
  end

  def test_set_sensors
    sensors = SAAL::Sensors.new(@test_sensors_denkovi_file, TEST_DBCONF)
    with_webrick(:html=>create_current_state_json(@rvals)) do |feedback|
      @vals.each do |num, state|
        newval = state == "ON" ? 0.0 : 1.0
        newstate = state == "ON" ? "OFF" : "ON"
        assert_equal newval, sensors.send('name'+num.to_s.rjust(2, "0")).write(newval), 
                     "State change not working"
        val = {"ON" => "1", "OFF" => "0"}[newstate]
        assert_path "/current_state.json?pw=#{@pass}&Relay#{num}=#{val}", feedback[:uris][-2]
        assert_path "/current_state.json?pw=#{@pass}", feedback[:uris][-1]
      end
    end
  end

  # Test that write invalidates any caching
  def test_write_read_sensors
    sensors = SAAL::Sensors.new(@test_sensors_denkovi_file, TEST_DBCONF)
    with_webrick(:html=>create_current_state_json(@vals)) do |feedback|
      @vals.each do |num, state|
        sensors.send('name'+num.to_s.rjust(2, "0")).write(0.0)
        sensors.send('name'+num.to_s.rjust(2, "0")).read
      end
      assert_equal 32, feedback[:nrequests], "denkovi caching too much"
    end
  end

  # Test that the cache times out
  def test_cache_invalidation
    _sensors = SAAL::Sensors.new(@test_sensors_denkovi_file, TEST_DBCONF)
    @og.cache_timeout = 0.1
    with_webrick(:html=>create_current_state_json(@vals)) do |feedback|
      @og.state(1)
      sleep 0.2
      @og.state(1)
      assert_equal 2, feedback[:nrequests], "denkovi caching not invalidating"
    end
  end

  def test_failed_connection
    @vals.each do |num, state|
      assert_equal nil, @og.state(num)
      assert !@og.set_state(num,"ON"), "State change working without a server?!"
    end
  end

  def test_failed_request
    with_webrick(:html=>create_current_state_json(@vals),:status=>404) do |feedback|
      @vals.each do |num, state|
        assert_equal nil, @og.state(num)
        assert !@og.set_state(num,"ON"), "State change working without a server?!"
      end
    end
  end

  def test_fast_open_timeout
    #FIXME: Find a way to make this test address more generic
    @og=SAAL::Denkovi::OutletGroup.new(service_opts.merge(:host => "10.254.254.254", 
                                                           :timeout=>0.1))
    with_webrick(:html=>create_current_state_json(@vals)) do |feedback|
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
    @og=SAAL::Denkovi::OutletGroup.new(service_opts.merge(:timeout=>0.1))
    with_webrick(:html=>create_current_state_json(@vals),:sleep=>10) do |feedback|
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
