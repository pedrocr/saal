require 'json'

module SAAL
  module Envoy
    class PowerEnergyUnderlying < SensorUnderlying
      def initialize(key, production)
        @key = key
        @production = production
      end

      def read(uncached = false)
        @production.read_val(@key)
      end
    end

    class PowerEnergy
      DEFAULT_HOST = "envoy.local"
      DEFAULT_TIMEOUT = 2
      DEFAULT_CACHE_TIMEOUT = 50
      DEFAULT_SOURCES = [
        "production_inverters",
        "production_phase1", "production_phase2", "production_phase3", "production_total",
        "net_consumption_phase1", "net_consumption_phase2", "net_consumption_phase3", "net_consumption_total",
        "total_consumption_phase1", "total_consumption_phase2", "total_consumption_phase3", "total_consumption_total",
      ]
      DEFAULT_TYPES = [
        "w_now", "wh_lifetime", "va_now", "vah_lifetime",
      ]
      DEFAULT_PREFIX = "pv"

      def initialize(defs, opts={})
        @host = defs[:host] || defs['host'] || DEFAULT_HOST
        @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
        @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
        @cache = nil
        @cachetime = nil
        @sources = defs[:sources] || defs['source'] || DEFAULT_SOURCES
        @types = defs[:types] || defs['types'] || DEFAULT_TYPES
        @prefix = defs[:prefix] || defs['prefix'] || DEFAULT_PREFIX
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
          key = "#{@prefix}_#{source}_#{type}"
          sensors[key] = PowerEnergyUnderlying.new(key, self)
        end
        sensors
      end

      private
      def save_vals(dest, name, source)
        {
         "wNow" => "w_now",
         "apprntPwr" => "va_now",
         "whLifetime" => "wh_lifetime",
         "vahLifetime" => "vah_lifetime",
        }.each do |type, label|
          dest["#{@prefix}_#{name}_#{label}"] = source[type]
        end

        # Hack around the fact that apprntPwr is broken on the total consumption
        # calculation for the three-phase sum at least
        # In those cases it seems to be missing a divide by three, so when the
        # calculation for voltage and current alone is close do the extra divide
        va_now = dest["#{@prefix}_#{name}_va_now"]
        if va_now && !name.include?("phase")
          voltage = source["rmsVoltage"]
          current = source["rmsCurrent"]
          if voltage && current
            va_alt = voltage * current
            if ((va_alt / va_now) - 1.0).abs < 0.05
              dest["#{@prefix}_#{name}_va_now"] = va_now / 3.0
            end
          end
        end
      end

      def read_all
        response = SAAL::do_http_get(@host, 80, "/production.json?details=1", nil, nil, @timeout)
        return nil if !response

        values = JSON.parse(response.body)
        outputs = {}

        values["production"].each do |source|
          type = source["type"]
          case type
          when "inverters"
            save_vals(outputs, "production_inverters", source)
          when "eim"
            if source["lines"]
              save_vals(outputs, "production_phase1", source["lines"][0])
              save_vals(outputs, "production_phase2", source["lines"][1])
              save_vals(outputs, "production_phase3", source["lines"][2])
            end
            save_vals(outputs, "production_total", source)
          else
            $stderr.puts "WARNING: ENVOY: don't know source type #{type}"
          end
        end

        values["consumption"].each do |source|
          type = {
            "total-consumption" => "total",
            "net-consumption" => "net",
          }[source["measurementType"]] || "unknown";

          if source["lines"]
            save_vals(outputs, "#{type}_consumption_phase1", source["lines"][0])
            save_vals(outputs, "#{type}_consumption_phase2", source["lines"][1])
            save_vals(outputs, "#{type}_consumption_phase3", source["lines"][2])
          end
          save_vals(outputs, "#{type}_consumption_total", source)
        end

        outputs
      end
    end

    class ACQualityUnderlying < SensorUnderlying
      def initialize(key, production)
        @key = key
        @production = production
      end

      def read(uncached = false)
        @production.read_val(@key)
      end
    end

    class ACQuality
      DEFAULT_HOST = "envoy.local"
      DEFAULT_TIMEOUT = 2
      DEFAULT_CACHE_TIMEOUT = 50
      DEFAULT_SOURCES = ["total","phase1","phase2","phase3",]
      DEFAULT_TYPES = ["frequency","voltage"]
      DEFAULT_PREFIX = "ac"

      def initialize(defs, opts={})
        @host = defs[:host] || defs['host'] || DEFAULT_HOST
        @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
        @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
        @cache = nil
        @cachetime = nil
        @sources = defs[:sources] || defs['source'] || DEFAULT_SOURCES
        @types = defs[:types] || defs['types'] || DEFAULT_TYPES
        @prefix = defs[:prefix] || defs['prefix'] || DEFAULT_PREFIX
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
          key = "#{@prefix}_#{source}_#{type}"
          sensors[key] = ACQualityUnderlying.new(key, self)
        end
        sensors
      end

      private
      def save_vals(dest, name, source)
        {
         "voltage" => "voltage",
         "freq" => "frequency",
        }.each do |type, label|
          dest["#{@prefix}_#{name}_#{label}"] = source[type]
        end
      end

      def read_all
        response = SAAL::do_http_get(@host, 80, "/ivp/meters/readings", nil, nil, @timeout)
        return nil if !response

        values = JSON.parse(response.body)
        outputs = {}
        source = values[0]
        save_vals(outputs, "total", source)
        if source["channels"]
          save_vals(outputs, "phase1", source["channels"][0])
          save_vals(outputs, "phase2", source["channels"][1])
          save_vals(outputs, "phase3", source["channels"][2])
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
      DEFAULT_TYPES = ["w_now"] # "last_report_date", "w_max"
      DEFAULT_USER = nil
      DEFAULT_PASSWORD = nil
      attr_reader :inverters

      def initialize(defs, opts={})
        @host = defs[:host] || defs['host'] || DEFAULT_HOST
        @user = defs[:user] || defs['user'] || DEFAULT_USER
        @password = defs[:password] || defs['password'] || DEFAULT_PASSWORD
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
        response = SAAL::do_http_get_digest(@host, 80, "/api/v1/production/inverters", @user, @password, @timeout)
        return nil if !response

        values = JSON.parse(response.body)
        inverters = {}
        values.each do |inverter|
          serial = inverter["serialNumber"]
          @inverters_list[serial] = true
          {"lastReportDate" => "last_report_date",
           "lastReportWatts" => "w_now",
           "maxReportWatts" => "w_max",
          }.each do |type, label|
            inverters["inverter_#{serial}_#{label}"] = inverter[type]
          end
        end

        inverters
      end
    end
  end
end
