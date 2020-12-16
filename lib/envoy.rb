require 'json'

module SAAL
  module Envoy
    class ProductionUnderlying < SensorUnderlying
      def initialize(key, production)
        @key = key
        @production = production
      end

      def read(uncached = false)
        @production.read_val(@key)
      end
    end

    class Production
      DEFAULT_HOST = "envoy.local"
      DEFAULT_TIMEOUT = 2
      DEFAULT_CACHE_TIMEOUT = 50
      DEFAULT_SOURCES = [
        "production_inverters",
        "production_phase1", "production_phase2", "production_phase3", "production",
        "consumption_net_phase1", "consumption_net_phase2", "consumption_net_phase3", "consumption_net",
        "consumption_total_phase1", "consumption_total_phase2", "consumption_total_phase3", "consumption_total",
      ]
      DEFAULT_TYPES = [
        "rms_voltage", "watts_now", "watt_hours_lifetime", "power_factor",
      ]

      def initialize(defs, opts={})
        @host = defs[:host] || defs['host'] || DEFAULT_HOST
        @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
        @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
        @cache = nil
        @cachetime = nil
        @sources = defs[:sources] || defs['source'] || DEFAULT_SOURCES
        @types = defs[:types] || defs['types'] || DEFAULT_TYPES
      end

      def read_val(name)
        if !@cachetime or @cachetime < Time.now - @cache_timeout
          @cache = read_all()
          @cachetime = Time.now
        end
        return @cache ? @cache[name] : nil
      end

      def create_sensors
        sensors = {}
        @sources.product(@types).each do |source, type|
          key = "#{source}_#{type}"
          sensors[key] = ProductionUnderlying.new(key, self)
        end
        sensors
      end

      private
      def save_vals(dest, name, source)
        {"rmsVoltage" => "rms_voltage",
         "wNow" => "watts_now",
         "whLifetime" => "watt_hours_lifetime",
         "pwrFactor" => "power_factor",
        }.each do |type, label|
          dest["#{name}_#{label}"] = source[type]
        end
      end

      def read_all
        response = SAAL::do_http_get(@host, 80, "/production.json", nil, nil, @timeout)
        return nil if !response

        values = JSON.parse(response.body)
        outputs = {}

        values["production"].each do |source|
          type = source["type"]
          case type
          when "inverters"
            save_vals(outputs, "production_inverters", source)
          when "eim"
            save_vals(outputs, "production_phase1", source["lines"][0])
            save_vals(outputs, "production_phase2", source["lines"][1])
            save_vals(outputs, "production_phase3", source["lines"][2])
            save_vals(outputs, "production", source)
          else
            $stderr.puts "WARNING: ENVOY: don't know source type #{'%10.0f' %type}"
          end
        end

        values["consumption"].each do |source|
          type = {
            "total-consumption" => "total",
            "net-consumption" => "net",
          }[source["measurementType"]] || "unknown";

          save_vals(outputs, "consumption_#{type}_phase1", source["lines"][0])
          save_vals(outputs, "consumption_#{type}_phase2", source["lines"][1])
          save_vals(outputs, "consumption_#{type}_phase3", source["lines"][2])
          save_vals(outputs, "consumption_#{type}", source)
        end

        outputs
      end
    end

    class InverterUnderlying < SensorUnderlying
      def initialize(key, inverters)
        @key = key
        @inverters = inverters
      end

      def read(uncached = false)
        @inverters.read_val(@key)
      end
    end

    class Inverters
      DEFAULT_TIMEOUT = 2
      DEFAULT_CACHE_TIMEOUT = 50
      DEFAULT_SOURCES = []
      DEFAULT_TYPES = ["last_report_date", "watts_now", "watts_max"]
      attr_reader :inverters

      def initialize(defs, opts={})
        @host = defs[:host] || defs['host'] || DEFAULT_HOST
        @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
        @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
        @cache = nil
        @cachetime = nil
        @inverters_list = {}
        @inverters = defs[:inverters] || defs['inverters'] || DEFAULT_SOURCES
        @types = defs[:types] || defs['types'] || DEFAULT_TYPES
      end

      def read_val(name)
        if !@cachetime or @cachetime < Time.now - @cache_timeout
          @cache = read_all()
          @cachetime = Time.now
        end
        return @cache ? @cache[name] : nil
      end

      def enumerate
        read_val("foo") # Force a read to make sure the inverter serials are stored
        @inverters_list.keys
      end

      def set_all_inverters!
        @inverters = self.enumerate
      end

      def create_sensors
        sensors = {}
        @inverters.product(@types).each do |source, type|
          key = "inverter_#{source}_#{type}"
          sensors[key] = InverterUnderlying.new(key, self)
        end
        sensors
      end

      private
      def read_all
        response = SAAL::do_http_get(@host, 80, "/api/v1/production/inverters", nil, nil, @timeout)
        return nil if !response

        values = JSON.parse(response.body)
        inverters = {}
        values.each do |inverter|
          {"lastReportDate" => "last_report_date",
           "lastReportWatts" => "watts_now",
           "maxReportWatts" => "watts_max",
          }.each do |type, label|
            inverters["inverter_#{inverter["serialNumber"]}_#{label}"] = inverter[type]
            @inverters_list[inverter["serialNumber"]] = true
          end
        end

        inverters
      end
    end
  end
end
