require 'net/http'

module SAAL
  module DINRelay
    class Outlet < SensorUnderlying
      writeable!

      def initialize(num, outletgroup)
        @num = num
        @og = outletgroup
      end

      def read(uncached = false)
        {'ON' => 1.0, 'OFF' => 0.0}[@og.state(@num)]
      end

      def set(value)
        newstate = {1.0 => 'ON', 0.0 => 'OFF'}[value]
        if newstate
          @og.set_state(@num,newstate)
          value 
        end
      end
    end

    class OutletGroup
      def initialize(opts={})
        @host = opts[:host] || opts['host'] || 'localhost'
        @port = opts[:port] || opts['port'] || 80
        @user = opts[:user] || opts['user'] || 'admin'
        @pass = opts[:pass] || opts['pass'] || '1234'
      end

      def state(num)
        response = do_get('/index.htm')
        return parse_index_html(response.body)[num]
      end

      def set_state(num, state)
        response = do_get("/outlet?#{num}=#{state}")
        response.code == "200"
      end

      private
      def do_get(path)
        Net::HTTP.start(@host,@port) do |http|
          req = Net::HTTP::Get.new(path)
          req.basic_auth @user, @pass
          response = http.request(req)
          if response.code != "200"
            $stderr.puts "ERROR: Code #{response.code}"
            $stderr.puts response.body
          end
          return response
        end
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
