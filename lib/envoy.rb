require 'json'

module SAAL
  class EnvoyProduction
    DEFAULT_TIMEOUT = 2
    DEFAULT_CACHE_TIMEOUT = 50

    def initialize(defs, opts={})
      @server = defs['server']
      @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
      @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
      @cache = nil
      @cachetime = nil
    end

    def read_val(name)
      if !@cachetime or @cachetime < Time.now - @cache_timeout
        @cache = read_all()
        @cachetime = Time.now
      end
      return @cache ? @cache[name] : nil
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
      response = SAAL::do_http_get(@server, 80, "/production.json", nil, nil, @timeout)
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
          save_vals(outputs, "production_total", source)
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

  class EnvoyInverters
    DEFAULT_TIMEOUT = 2
    DEFAULT_CACHE_TIMEOUT = 50

    def initialize(defs, opts={})
      @server = defs['server']
      @timeout = opts[:timeout] || opts['timeout'] || DEFAULT_TIMEOUT
      @cache_timeout = opts[:cache_timeout] || opts['cache_timeout'] || DEFAULT_CACHE_TIMEOUT
      @cache = nil
      @cachetime = nil
      @inverters_list = {}
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

    private
    def read_all
      response = SAAL::do_http_get(@server, 80, "/api/v1/production/inverters", nil, nil, @timeout)
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
