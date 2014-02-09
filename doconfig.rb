#!/usr/bin/ruby
#
# Author: Sarn Wattanasri
# Date: 4/3/12
# Program: doconfig.rb
# Purpose: This program uses YAML to create a config file.
#          It also provides a function to read the 
#          config file created.

require 'yaml'

#****************************create_config()*****************************
def create_config()
    config = {
              'duration'=>10080,
              'frequency'=> 300000,
              'show_ip_address' => 'Y',
              'page_size' => 24, 
              'period' => 5 
             }
    open('monitor.conf','w'){|f| YAML.dump(config,f)}
end

#*****************************read_config()******************************
def read_config()
    config_back = {}
    open('monitor.conf') {|f| config_back = YAML.load(f) }
    config_back
end
