# Cookbook Name:: rb-monitor
#
# Provider:: config
#

action :add do
  begin
     # ... your code here ...
     Chef::Log.info("rb-monitor has been configured correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
     # ... your code here ...
     Chef::Log.info("rb-monitor has been deleted correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end
