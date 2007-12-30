require 'sqlite3'

module SAAL
  class FileStore
    def initialize(opts = {:db => "sensor_reads.db"})
      @opts = opts
      @db = SQLite3::Database.new(@opts[:db])
      @db.type_translation = true
      @db.execute("create table if not exists sensor_reads
                    (sensor string, date integer, value real)")
    end
    
    def write(sensor, date, value)
      @db.execute("insert into sensor_reads values (?,?,?)", 
                  sensor.to_s, date, value)
    end
    
    def average(sensor, from, to)
      r = @db.execute("select avg(value) as average from sensor_reads
                        where sensor = ? and date >= ? and date <= ?",
                       sensor.to_s, from, to)
      if r[0][0]
        Float(r[0][0])
      else
        nil
      end
    end
    
    def close
      @db.close
    end
    
    # HACK: disable warnings when running any of the methods to work around
    #       buggy sqlite
    [:initialize, :write, :average, :close].each do |m|
    old = instance_method(m)
      define_method(m) do |*args| 
        $-w = false
        ret = old.bind(self).call(*args)
        $-w = true
        return ret
      end
    end

  end
end
