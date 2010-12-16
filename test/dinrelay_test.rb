require File.dirname(__FILE__)+'/test_helper.rb'
require 'webrick'
#require 'webrick/accesslog'

class TestDINRelay < Test::Unit::TestCase
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
      @feedback[:path] = req.path
      WEBrick::HTTPAuth.basic_auth(req, res, "My Realm") {|user, pass|
        user == @user && pass == @pass
      }
      res.body = @html
      res['Content-Type'] = "text/xml"
    end
  end

  def with_webrick(opts)
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

  def test_read_values
    opts = {:port => 33333, :user => "someuser", :pass =>"somepass"}
    vals = {1=>"OFF",2=>"OFF",3=>"ON",4=>"OFF",5=>"ON",6=>"ON",7=>"ON",8=>"OFF"}
    with_webrick(opts.merge(:html=>create_index_html(vals))) do |feedback|
      og = SAAL::DINRelay::OutletGroup.new("localhost", opts)
      vals.each do |num, state|
        assert_equal state, og.state(num)
        assert_equal '/index.htm', feedback[:path]
      end
    end
  end
end
