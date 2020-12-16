require 'json'
require 'open-uri'

module SAAL
  class Envoy
    def initialize(defs, opts={})
      @server = defs['server']
    end
  
    def read_all
      begin
        json = URI.open("http://#{@server}/production.json").read
      rescue StandardError
        $stderr.puts "ERROR: ENVOY: Couldn't connect to `#{@server}`"
        return nil
      end

      values = JSON.parse(json)
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
  end
end
