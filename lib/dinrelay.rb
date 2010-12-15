require 'net/http'

module SAAL
  module DINRelay
    def self.parse_index_html(str)
      doc = Nokogiri::HTML(str)
      outlets = doc.css('tr[bgcolor="#F4F4F4"]')
      Hash[*((outlets.enum_for(:each_with_index).map do |el, index|
        [index+1, el.css('font[color="red"]')[0].content]
      end).flatten)]
    end

    class OutletGroup
      def initialize(host, opts={})
        @host = host
        @port = opts[:port] || 80
      end

      def state(num)
        html = Net::HTTP.get(@host, '/index.html', @port)
        parse_index_html(html)[num]
      end

      private
      def parse_index_html(str)
        doc = Nokogiri::HTML(str)
        outlets = doc.css('tr[bgcolor="#F4F4F4"]')
        Hash[*((outlets.enum_for(:each_with_index).map do |el, index|
          [index+1, el.css('font[color="red"]')[0].content]
        end).flatten)]
      end
    end
  end
end
