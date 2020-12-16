require 'json'

module SAAL
  class Envoy
    DEFAULT_TIMEOUT = 2

    def initialize(defs, opts={})
      @server = defs['server']
      @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
    end
  
    def read_production
      response = SAAL::do_http_get(@server, 80, "/production.json", nil, nil, @timeout)
      return nil if !response

      values = JSON.parse(response.body)
      outputs = {}

      values["production"].each do |source|
        type = source["type"]
        case type
        when "inverters"
          outputs["production-inverters"] = source
        when "eim"
          outputs["production-phase1"] = source["lines"][0]
          outputs["production-phase2"] = source["lines"][1]
          outputs["production-phase3"] = source["lines"][2]
          source["lines"] = nil
          outputs["production-total"] = source
        else
          $stderr.puts "WARNING: ENVOY: don't know source type #{'%10.0f' %type}"
        end
      end

      values["consumption"].each do |source|
        type = {
          "total-consumption" => "total",
          "net-consumption" => "net",
        }[source["measurementType"]] || "unknown";

        outputs["consumption-#{type}-phase1"] = source["lines"][0]
        outputs["consumption-#{type}-phase2"] = source["lines"][1]
        outputs["consumption-#{type}-phase3"] = source["lines"][2]
        source["lines"] = nil
        outputs["consumption-#{type}"] = source
      end
      
      outputs
    end

    def read_inverters
      response = SAAL::do_http_get(@server, 80, "/api/v1/production/inverters", nil, nil, @timeout)
      return nil if !response

      values = JSON.parse(response.body)
      inverters = {}
      values.each do |inverter|
        inverters[inverter["serialNumber"]] = inverter
      end

      inverters
    end
  end
end
