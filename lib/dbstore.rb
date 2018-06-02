module SAAL
  class DBStore
    # Only give out last_value if it's less than 5 min old
    MAX_LAST_VAL_AGE = 5*60 

    include Enumerable
    def initialize(conffile=SAAL::DBCONF)
      @dbopts = YAML::load(File.new(conffile))
      @db = nil
      db_initialize
    end

    def db_initialize
      db_query "CREATE TABLE IF NOT EXISTS sensor_reads
                   (sensor VARCHAR(100), 
                    date INT, 
                    value FLOAT) ENGINE=InnoDB"
      db_query "ALTER TABLE sensor_reads ADD INDEX sensor_date_value (sensor,date,value) USING BTREE",
               :ignoreerr => 1061
    end
    
    def db_wipe
      db_query "DROP TABLE sensor_reads"
    end

    def write(sensor, date, value)
      raise ArgumentError, "Trying to store an empty sensor read" if !value
      raise ArgumentError, "Trying to store an empty timestamp" if !date
      raise ArgumentError, "Trying to store a timestamp <= 0" if date <= 0
      db_query "INSERT INTO sensor_reads VALUES
                  ('"+db_quote(sensor.to_s)+"',"+date.to_s+","+value.to_s+")"
    end
    
    def average(sensor, from, to)     
      db_range("AVG", sensor, from, to)
    end

    def minimum(sensor, from, to)     
      db_range("MIN", sensor, from, to)
    end
    def maximum(sensor, from, to)     
      db_range("MAX", sensor, from, to)
    end
    def last_value(sensor)
      db_query "SELECT date,value FROM sensor_reads 
                  WHERE sensor = '#{db_quote(sensor.to_s)}'
                  AND date > '#{Time.now.utc.to_i - MAX_LAST_VAL_AGE}'
                  ORDER BY date DESC LIMIT 1" do |r|
        row = r.first
        if row
          _date, value = [row["date"].to_i, row["value"].to_f]
          value
        else
          nil
        end
      end
    end

    def each
      db_query "SELECT sensor,date,value FROM sensor_reads" do |r|
        r.each do |row|
          yield [row["sensor"],row["date"].to_i, row["value"].to_f]
        end
      end
    end
    
    private
    def db_range(function, sensor, from, to)
      db_query "SELECT #{function}(value) AS func FROM sensor_reads
                       WHERE sensor = '#{db_quote(sensor.to_s)}' 
                         AND date >= #{from.to_s} 
                         AND date <= #{to.to_s}" do |r|
        row = r.first
        if row && row["func"]
          row["func"].to_f
        else
          nil
        end
      end
    end

    def db_quote(text)
      Mysql2::Client.escape(text)
    end

    def db_query(query, opts={})
      db = nil
      begin
        # connect to the MySQL server
        db = Mysql2::Client.new(@dbopts)
        res = db.query(query)
        yield res if block_given?
      rescue Mysql2::Error => e
        $stderr.puts "MySQL Error #{e.errno}: #{e.error}" if !(e.errno == opts[:ignoreerr])
      ensure
        db.close if db
      end
    end      
  end
end
