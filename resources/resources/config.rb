# Cookbook Name:: rbmonitor
#
# Resource:: config
#
actions :add, :remove
default_action :add

attribute :config_dir, :kind_of => String, :default => "/etc/redborder-monitor"
attribute :kafka_topic, :kind_of => String, :default => "rb_monitor"
attribute :name, :kind_of => String, :default => "localhost"
attribute :ip, :kind_of => String, :default => "127.0.0.1"
attribute :community, :kind_of => String, :default => "redborder"
attribute :log_level, :kind_of => Integer, :default => 3
attribute :device_nodes, :kind_of => Array, :default => []
attribute :flow_nodes, :kind_of => Array, :default => []
attribute :ipsync, :kind_of => Array, :default => []
attribute :managers, :kind_of => Array, :default => ["localhost"]
attribute :manager_index, :kind_of => Integer, :default => 1
attribute :monitors, :kind_of => String, :default => ""
attribute :manager_services, :kind_of => Integer, :default => ""
attribute :kafka_managers, :kind_of => Array, :default => ["localhost"]