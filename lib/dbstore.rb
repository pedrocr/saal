require "mysql"

module SAAL
  class DBStore
    def initialize(conffile="/etc/saal/database.yml")
      @dbopts = YAML::load(File.new(conffile))
      @db = nil
      db_initialize
    end

    def db_initialize
      @db.query "CREATE TABLE IF NOT EXISTS sensor_reads
                   (sensor VARCHAR(100), 
                    date INT, 
                    value FLOAT)"
    end
    
    def db_wipe
      @db.query "DROP TABLE sensor_reads"
    end

    def write(sensor, date, value)
      @db.query "INSERT INTO sensor_reads VALUES
                  ('"+@db.quote(sensor.to_s)+"',"+date.to_s+","+value.to_s+")"
    end
    
    def average(sensor, from, to)     
      r = @db.query "SELECT AVG(value) AS average FROM sensor_reads
                       WHERE sensor = '#{@db.quote(sensor.to_s)}' 
                         AND date >= #{from.to_s} 
                         AND date <= #{to.to_s}"
      r.num_rows > 0 ? r.fetch_row[0] : nil
    end

    
    # Add database connection to methods
    [:db_initialize, :db_wipe, :write, :average].each do |m|
      old = instance_method(m)
      define_method(m) do |*args|
        ret = nil 
        begin
          # connect to the MySQL server
          @db = Mysql.new(@dbopts['host'],@dbopts['user'],@dbopts['pass'],
                          @dbopts['db'],@dbopts['port'],@dbopts['socket'],
                          @dbopts['flags'])
          ret = old.bind(self).call(*args)
        rescue Mysql::Error => e
          $stderr.puts "MySQL Error #{e.errno}: #{e.error}"
        ensure
          @db.close if @db
        end
        ret
      end
    end
  end
end
