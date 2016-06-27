# Cookbook Name:: rb-monitor
#
# Resource:: config
#

actions :add, :remove
default_action :add

attribute :mystring, :kind_of => String, :default => "string example"
attribute :myinteger, :kind_of => Fixnum, :default => 1
attribute :myarray, :kind_of => Array, :default => ["val1"]
attribute :myhash, :kind_of => Object, :default => {"val1" => "1"}

