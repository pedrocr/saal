module SAAL
  class OWSensor < SensorUnderlying
    attr_reader :serial, :sensor_type
    def initialize(defs, opts={})
      @serial = defs['serial']
      @connect_opts = {}
      @connect_opts[:server] = defs['server'] if defs['server']
      @connect_opts[:port] = defs['port'] if defs['port']
      @owconn = opts[:owconn]

      basename = File.basename(@serial)
      @sensor_type = basename.to_sym if ['pressure','temperature','humidity'].include?(basename)
    end

    def read(uncached = false)
      @owconn ||= OWNet::Connection.new(@connect_opts)
      begin
        @owconn.read((uncached ? '/uncached' : '')+@serial)
      rescue Exception
        nil
      end
    end
  end
end
