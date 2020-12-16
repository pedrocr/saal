require 'net/http'

module SAAL
  module DINRelay
    class Outlet < SensorUnderlying
      writeable!

      def initialize(num, outletgroup)
        @num = num
        @og = outletgroup
      end

      def sensor_type
        :onoff
      end

      def read(uncached = false)
        {'ON' => 1.0, 'OFF' => 0.0}[@og.state(@num)]
      end

      def write(value)
        newstate = {1.0 => 'ON', 0.0 => 'OFF'}[value]
        if newstate
          @og.set_state(@num,newstate)
          value 
        end
      end
    end

    class OutletGroup
      DEFAULT_TIMEOUT = 2
      DEFAULT_CACHE_TIMEOUT = 60

      attr_accessor :host, :port, :user, :pass, :timeout, :cache_timeout

      def initialize(opts={})
        @host = opts[:host] || opts['host'] || 'localhost'
        @port = opts[:port] || opts['port'] || 80
        @user = opts[:user] || opts['user'] || 'admin'
        @pass = opts[:pass] || opts['pass'] || '1234'
        @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
        @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
        @cache = nil
        @cachehit = nil
        @cachetime = nil
      end

      def state(num)
        if !@cachetime or @cachetime < Time.now - @cache_timeout
          @cache = do_get('/index.htm')
          @cachetime = Time.now
        end
        return @cache ? parse_index_html(@cache.body)[num] : nil
      end

      def set_state(num, state)
        @cachetime = nil
        response = do_get("/outlet?#{num}=#{state}")
        response != nil
      end

      private
      def do_get(path)
        SAAL::do_http_get(@host, @port, path, @user, @pass, @timeout)
      end
      def parse_index_html(str)
        doc = Nokogiri::HTML(str)
        outlets = doc.css('tr[bgcolor="#F4F4F4"]')
        Hash[*((outlets.enum_for(:each_with_index).map do |el, index|
          [index+1, el.css('font')[0].content]
        end).flatten)]
      end
    end
  end
end
