module SAAL
  class DBStore
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
                    value FLOAT,
                    INDEX USING HASH (sensor),
                    INDEX USING BTREE (date))"
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

    def each
      db_query "SELECT sensor,date,value FROM sensor_reads" do |r|
        r.num_rows.times do
          row = r.fetch_row
          yield [row[0],row[1].to_i, row[2].to_f]
        end
      end
    end
    
    private
    def db_range(function, sensor, from, to)
      db_query "SELECT #{function}(value) AS average FROM sensor_reads
                       WHERE sensor = '#{db_quote(sensor.to_s)}' 
                         AND date >= #{from.to_s} 
                         AND date <= #{to.to_s}" do |r|
        if r.num_rows == 0 
          nil
        else
          row = r.fetch_row
          row[0] ? row[0].to_f : nil
        end
      end
    end

    def db_quote(text)
      Mysql.quote(text)
    end

    def db_query(query, opts={})
      db = nil
      begin
        # connect to the MySQL server
        db = Mysql.new(@dbopts['host'],@dbopts['user'],@dbopts['pass'],
                       @dbopts['db'],@dbopts['port'],@dbopts['socket'],
                       @dbopts['flags'])
        res = db.query(query)
        yield res if block_given?
      rescue Mysql::Error => e
        $stderr.puts "MySQL Error #{e.errno}: #{e.error}" if !(e.errno == opts[:ignoreerr])
      ensure
        db.close if db
      end
    end      
  end
end
