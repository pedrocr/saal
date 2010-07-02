module SAAL
  class DBStore
    include Enumerable
    def initialize(conffile=SAAL::DBCONF)
      @dbopts = YAML::load(File.new(conffile))
      @db = nil
      db_initialize
    end

    def db_initialize
      @db.query "CREATE TABLE IF NOT EXISTS sensor_reads
                   (sensor VARCHAR(100), 
                    date INT, 
                    value FLOAT,
                    INDEX USING HASH (sensor),
                    INDEX USING BTREE (date))"
    end
    
    def db_wipe
      @db.query "DROP TABLE sensor_reads"
    end

    def write(sensor, date, value)
      raise ArgumentError, "Trying to store an empty sensor read" if !value
      raise ArgumentError, "Trying to store an empty timestamp" if !date
      raise ArgumentError, "Trying to store a timestamp <= 0" if date <= 0
      @db.query "INSERT INTO sensor_reads VALUES
                  ('"+@db.quote(sensor.to_s)+"',"+date.to_s+","+value.to_s+")"
    end
    
    def average(sensor, from, to)     
      r = @db.query "SELECT AVG(value) AS average FROM sensor_reads
                       WHERE sensor = '#{@db.quote(sensor.to_s)}' 
                         AND date >= #{from.to_s} 
                         AND date <= #{to.to_s}"
      if r.num_rows == 0 
        nil
      else
        row = r.fetch_row
        row[0] ? row[0].to_f : nil
      end
    end

    def each
      r = @db.query "SELECT sensor,date,value FROM sensor_reads"  
      r.num_rows.times do
        row = r.fetch_row
        yield [row[0],row[1].to_i, row[2].to_f]
      end
    end
    
    # Add database connection to methods
    [:db_initialize, :db_wipe, :write, :average, :each].each do |m|
      alias_method "orig_"+m.to_s, m
      class_eval %{
        def #{m} (*args, &block)
          ret = nil 
          begin
            \# connect to the MySQL server
            @db = Mysql.new(@dbopts['host'],@dbopts['user'],@dbopts['pass'],
                            @dbopts['db'],@dbopts['port'],@dbopts['socket'],
                            @dbopts['flags'])
            ret = orig_#{m}(*args,&block)
          rescue Mysql::Error => e
            $stderr.puts "MySQL Error \#{e.errno}: \#{e.error}"
          ensure
            @db.close if @db
          end
          ret
        end      
      }
    end
  end
end
