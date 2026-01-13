# Cookbook:: rbmonitor
# Resource:: config

actions :add, :remove
default_action :add

attribute :config_dir, kind_of: String, default: '/etc/redborder-monitor'
attribute :kafka_topic, kind_of: String, default: 'rb_monitor'
attribute :name, kind_of: String, default: 'localhost'
attribute :hostip, kind_of: String, default: '127.0.0.1'
attribute :community, kind_of: String, default: 'redBorder'
attribute :log_level, kind_of: Integer, default: 3
attribute :device_nodes, kind_of: Array, default: []
attribute :snmp_nodes, kind_of: Array, default: []
attribute :redfish_nodes, kind_of: Array, default: []
attribute :ipmi_nodes, kind_of: Array, default: []
attribute :flow_nodes, kind_of: Array, default: []
attribute :proxy_flow_nodes, kind_of: Array, default: []
attribute :proxy_device_nodes, kind_of: Array, default: []
attribute :proxy_snmp_nodes, kind_of: Array, default: []
attribute :proxy_redfish_nodes, kind_of: Array, default: []
attribute :proxy_ipmi_nodes, kind_of: Array, default: []
attribute :managers, kind_of: Array, default: []
attribute :proxy_nodes, kind_of: Array, default: []
attribute :cluster, kind_of: Hash, default: {}
