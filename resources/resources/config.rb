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