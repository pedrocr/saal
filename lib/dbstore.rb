require "mysql"

module SAAL
  class DBStore
    def initialize(dbopts, initialize=false)
      @dbopts = dbopts
      initialize_db if initialize
    end

    def initialize_db
      db.query("CREATE TABLE IF NOT EXISTS sensor_reads
                  (sensor VARCHAR(100) INDEX, 
                   date TIMESTAMP INDEX, 
                   value FLOAT)")
    end
    
    def write(sensor, date, value)
      db.query("INSERT INTO sensor_reads VALUES"+
                 "("+db.quote(sensor.to_s)+","+date.to_s+","+value.to_s+")"
    end
    
    def average(sensor, from, to)     
      r = db.query("SELECT AVG(value) AS average FROM sensor_reads
                      WHERE sensor = #{db.quote(sensor.to_s)} 
                        AND date >= #{from.to_s} 
                        AND date <= #{to.to_s}")
      r.num_rows > 0 ? r.fetch_row[0] : nil
    end
    
    # Add database connection to methods
    [:initialize_db, :write, :average].each do |m|
      old = instance_method(m)
      define_method(m) do |*args|
        ret = nil 
        begin
          # connect to the MySQL server
          db = Mysql.new(@dbopts[:host],@dbopts[:user],@dbopts[:pass],
                         @dbopts[:db],@dbopts[:port],@dbopts[:socket],
                         @dbopts[:flags])
          ret = old.bind(self).call(db,*args)
        rescue Mysql::Error => e
          puts "Error code: #{e.errno}"
          puts "Error message: #{e.error}"
          puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
        ensure
          db.close if dbh
        end
        ret
      end
    end
  end
end
