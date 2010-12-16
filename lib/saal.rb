require 'rubygems'
require 'yaml'
require "mysql"
require 'ownet'
require 'nokogiri'
require 'erb'

$-w = true

module SAAL
    CONFDIR = "/etc/saal/"
    SENSORSCONF = CONFDIR+"sensors.yml"
    DBCONF = CONFDIR+"database.yml"
end

require File.dirname(__FILE__)+'/dbstore.rb'
require File.dirname(__FILE__)+'/sensors.rb'
require File.dirname(__FILE__)+'/sensor.rb'
require File.dirname(__FILE__)+'/owsensor.rb'
require File.dirname(__FILE__)+'/daemon.rb'
require File.dirname(__FILE__)+'/chart_data.rb'
require File.dirname(__FILE__)+'/outliercache.rb'
require File.dirname(__FILE__)+'/dinrelay.rb'
  
