require 'net/http'

module SAAL
  module DINRelay
    class OutletGroup
      def initialize(host, opts={})
        @host = host
        @port = opts[:port] || 80
        @user = opts[:user] || "admin"
        @pass = opts[:pass] || "1234"
      end

      def state(num)
        Net::HTTP.start(@host,@port) do |http|
          req = Net::HTTP::Get.new('/index.htm')
          req.basic_auth @user, @pass
          response = http.request(req)
          if response.code != "200"
            $stderr.puts "ERROR: Code #{response.code}"
            $stderr.puts response.body
          end
          return parse_index_html(response.body)[num]
        end
      end

      private
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
