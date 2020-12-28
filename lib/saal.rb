require 'yaml'
require "mysql2"
require 'ownet'
require 'nokogiri'
require 'erb'

module SAAL
    CONFDIR = "/etc/saal/"
    SENSORSCONF = CONFDIR+"sensors.yml"
    DBCONF = CONFDIR+"database.yml"
    CHARTSCONF = CONFDIR+"charts.yml"

    VERSION = '0.3.2'
end

require File.dirname(__FILE__)+'/dbstore.rb'
require File.dirname(__FILE__)+'/sensors.rb'
require File.dirname(__FILE__)+'/sensor.rb'
require File.dirname(__FILE__)+'/owsensor.rb'
require File.dirname(__FILE__)+'/daemon.rb'
require File.dirname(__FILE__)+'/charts.rb'
require File.dirname(__FILE__)+'/chart.rb'
require File.dirname(__FILE__)+'/chart_data.rb'
require File.dirname(__FILE__)+'/outliercache.rb'
require File.dirname(__FILE__)+'/dinrelay.rb'
require File.dirname(__FILE__)+'/envoy.rb'
require File.dirname(__FILE__)+'/http.rb'
require File.dirname(__FILE__)+'/denkovi.rb'
  
