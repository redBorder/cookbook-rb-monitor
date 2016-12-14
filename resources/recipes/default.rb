#
# Cookbook Name:: rbmonitor
# Recipe:: default
#
# redborder
#
#  AFFERO GENERAL PUBLIC LICENSE, Version 3
#

rbmonitor_config "config" do
  name node["hostname"]
  log_level 7
  action :add
end
