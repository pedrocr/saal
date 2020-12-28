require 'net/http'
require 'json'

module SAAL
  module Denkovi
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
        newstate = {1.0 => '1', 0.0 => '0'}[value]
        if newstate
          @og.set_state(@num,newstate)
          value
        end
      end
    end

    class OutletGroup
      DEFAULT_TIMEOUT = 2
      DEFAULT_CACHE_TIMEOUT = 60

      attr_accessor :host, :port, :pass, :timeout, :cache_timeout

      def initialize(opts={})
        @host = opts[:host] || opts['host'] || 'localhost'
        @port = opts[:port] || opts['port'] || 80
        @pass = opts[:pass] || opts['pass'] || 'admin'
        @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
        @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
        @cache = nil
        @cachehit = nil
        @cachetime = nil
      end

      def state(num)
        if !@cachetime or @cachetime < Time.now - @cache_timeout
          @cache = do_get("/current_state.json?pw=#{@pass}")
          @cachetime = Time.now
        end
        return nil if !@cache
        json = JSON.parse(@cache.body)
        num = num - 1
        if json &&
           json["CurrentState"] &&
           json["CurrentState"]["Output"] &&
           json["CurrentState"]["Output"][num] &&
           json["CurrentState"]["Output"][num]["Value"]
           val = json["CurrentState"]["Output"][num]["Value"]
           {"1" => 1.0, "0" => 0.0}[val]
        else
          nil
        end
      end

      def set_state(num, state)
        @cachetime = nil
        val = {1.0 => "1", 0.0 => "0"}[state]
        if val
          response = do_get("/current_state.json?pw=#{@pass}&Relay#{num}=#{val}")
          response != nil
        else
          false
        end
      end

      private
      def do_get(path)
        SAAL::do_http_get(@host, @port, path, nil, nil, @timeout)
      end
    end
  end
end
