# Cookbook:: rbmonitor
# Recipe:: default
# Copyright:: 2024, redborder
# License:: Affero General Public License, Version 3

rbmonitor_config 'config' do
  name node['hostname']
  log_level 7
  action :add
end
