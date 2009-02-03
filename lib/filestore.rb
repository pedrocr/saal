require 'sqlite3'

module SAAL
  class FileStore
    def initialize(opts = {:db => "sensor_reads.db"})
      @opts = opts
      @db = SQLite3::Database.new(@opts[:db])
      @db.type_translation = true
      @db.execute("create table if not exists sensor_reads
                    (sensor string, date integer, value real)")
      @db.execute("create index if not exists sensor_reads_sensor_index on
                    sensor_reads(sensor)")
      @db.execute("create index if not exists sensor_reads_date_index on
                    sensor_reads(date)")
      @mutex = Mutex.new
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
    
    # Guard operations that access the database with a lock
    [:write, :average, :close].each do |m|
    old = instance_method(m)
      define_method(m) do |*args|
        ret = nil 
        @mutex.synchronize do
          ret = old.bind(self).call(*args)
        end
        ret
      end
    end
  end
end
