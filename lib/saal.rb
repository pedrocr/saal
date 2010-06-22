require 'rubygems'
require 'ownet'

module SAAL
  CONFDIR = "/etc/saal/"
  SENSORCONF = CONFDIR+"sensors.yml"
  DBCONF = CONFDIR+"database.yml"
end

require File.dirname(__FILE__)+'/dbstore.rb'
require File.dirname(__FILE__)+'/sensors.rb'
require File.dirname(__FILE__)+'/daemon.rb'
require File.dirname(__FILE__)+'/chart_data.rb'
  
