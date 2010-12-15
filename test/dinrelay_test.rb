require File.dirname(__FILE__)+'/test_helper.rb'
require 'webrick'

class TestDINRelay < Test::Unit::TestCase
  class BasicServing < WEBrick::HTTPServlet::AbstractServlet
    def self.get_instance(config, html)
      new(html)
    end
    def initialize(html)
      @html = html
    end
    def do_GET(req, res)
      res.body = @html
      res['Content-Type'] = "text/xml"
    end
  end

  def with_webrick(path,html,port)
    Socket.do_not_reverse_lookup = true # Speed up startup
    log = WEBrick::Log.new($stderr, WEBrick::Log::FATAL)
    s = WEBrick::HTTPServer.new(:Port => port, 
                                :Logger => log,
                                :AccessLog => log)
    s.mount(path, BasicServing, html)
    
    thread = Thread.new do
      s.start
    end
    while s.status != :Running; sleep 0.1; end # Make sure the server is up
    yield
    s.shutdown
    thread.exit
  end

  def create_index_html(hash)
    outlets = hash
    erb = ERB.new(File.open(File.dirname(__FILE__)+'/dinrelay.html.erb').read)
    erb.result(binding)
  end

  def test_html_parse
    hash = {1=>"OFF",2=>"OFF",3=>"ON",4=>"OFF",5=>"ON",6=>"ON",7=>"ON",8=>"OFF"}
    assert_equal hash, SAAL::DINRelay.parse_index_html(create_index_html(hash))
  end

  def test_read_values
    port = 33333
    vals = {1=>"OFF",2=>"OFF",3=>"ON",4=>"OFF",5=>"ON",6=>"ON",7=>"ON",8=>"OFF"}
    index_html = create_index_html(vals)
    with_webrick("/index.html", index_html, port) do
      og = SAAL::DINRelay::OutletGroup.new("localhost", :port => port)
      vals.each do |num, state|
        assert_equal state, og.state(num)
      end
    end
  end
end
