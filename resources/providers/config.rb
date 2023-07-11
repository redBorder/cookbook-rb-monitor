# Cookbook Name:: rbmonitor
#
# Provider:: config
#

action :add do
  begin    
    config_dir = new_resource.config_dir
    kafka_topic = new_resource.kafka_topic
    hostname = new_resource.name
    hostip = new_resource.hostip
    community = new_resource.community
    log_level = new_resource.log_level
    user = "redborder-monitor"
    device_nodes = new_resource.device_nodes
    flow_nodes = new_resource.flow_nodes
    managers = new_resource.managers
    cluster = new_resource.cluster
    yum_package "redborder-monitor" do
      action :upgrade
    end


    #Installation of required utilities
    utilities = [ "atop", "bc", "net-snmp-utils", "fping", "pcstat" ]
    utilities.each { |utility|
      yum_package utility do
        action :upgrade
      end
    }
  
    user user do
      action :create
    end
    
    directory config_dir do
      owner "root"
      group "root"
      mode 755
    end

    resource = {}
    resource["kafka_topic"] = kafka_topic
    resource["hostname"] = hostname
    resource["hostip"] = hostip
    resource["community"] = community
    resource["log_level"] = log_level
    resource["device_nodes"] = device_nodes
    resource["flow_nodes"] = flow_nodes
    resource["managers"] = managers
    resource["cluster"] = cluster

    template "#{config_dir}/config.json" do
      source "config.json.erb"
      owner "root"
      group "root"
      cookbook "rbmonitor"
      mode 0644
      retries 2
      variables(:resource => resource)
      helpers Rbmonitor::Helpers
      notifies :restart, "service[redborder-monitor]", :delayed
    end

    service "redborder-monitor" do
      service_name "redborder-monitor"
      supports :status => true, :restart => true, :start => true, :enable => true
      action [:enable, :start]
    end

    Chef::Log.info("cookbook redborder-monitor has been processed.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service "redborder-monitor" do
      service_name "redborder-monitor"
      supports :status => true, :restart => true, :start => true, :enable => true, :disable => true
      action [:disable, :stop]
    end
    Chef::Log.info("cookbook redborder-monitor has been processed.")
  rescue => e
    Chef::Log.error(e.message)
  end
end
