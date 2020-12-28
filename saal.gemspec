Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.platform = Gem::Platform::RUBY

  s.name              = 'saal'
  s.version           = '0.3.3'
  s.date              = '2020-12-28'

  s.summary     = "Thin abstraction layer for interfacing and recording sensors (currently onewire) and actuators (currently dinrelay)"
  s.description = <<EOF
A daemon and libraries to create an abstraction layer that interfaces with 
sensors and actuators, recording their state, responding to requests 
for current and historical values, and allowing changes of state.
EOF

  s.authors  = ["Pedro Côrte-Real"]
  s.email    = 'pedro@pedrocr.net'
  s.homepage = 'https://github.com/pedrocr/saal'
  s.licenses = 'LGPL-2.1'

  s.require_paths = %w[lib]

  s.has_rdoc = true
  s.rdoc_options = ['-S', '-w 2', '-N', '-c utf8']
  s.extra_rdoc_files = %w[README.rdoc LICENSE]

  s.executables = Dir.glob("bin/*").map{|f| f.gsub('bin/','')}

  s.add_runtime_dependency 'ownet', "~>0.2"
  s.add_runtime_dependency 'mysql2', "~>0.5"
  s.add_runtime_dependency 'nokogiri', '~>1.8'
  s.add_runtime_dependency 'net-http-digest_auth', '~>1.4'

  # = MANIFEST =
  s.files = %w[
    LICENSE
    README.rdoc
    Rakefile
    TODO
    bin/.gitignore
    bin/dinrelayset
    bin/dinrelaystatus
    bin/saal_chart
    bin/saal_daemon
    bin/saal_denkovi_relays
    bin/saal_dump_database
    bin/saal_envoy_generate_config
    bin/saal_envoy_read
    bin/saal_import_mysql
    bin/saal_readall
    lib/chart.rb
    lib/chart_data.rb
    lib/charts.rb
    lib/daemon.rb
    lib/dbstore.rb
    lib/denkovi.rb
    lib/dinrelay.rb
    lib/envoy.rb
    lib/http.rb
    lib/outliercache.rb
    lib/owsensor.rb
    lib/saal.rb
    lib/sensor.rb
    lib/sensors.rb
    saal.gemspec
    test/chart_data_test.rb
    test/chart_test.rb
    test/charts_test.rb
    test/daemon_test.rb
    test/dbstore_test.rb
    test/denkovi.json.erb
    test/denkovi_test.rb
    test/dinrelay.html.erb
    test/dinrelay_test.rb
    test/nonexistant_sensor.yml
    test/outliercache_test.rb
    test/sensor_test.rb
    test/sensors_test.rb
    test/test_charts.yml
    test/test_db.yml
    test/test_denkovi_sensors.yml
    test/test_dinrelay_sensors.yml
    test/test_helper.rb
    test/test_sensor_cleanups.yml
    test/test_sensors.yml
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/.*\.rb/ }
end
