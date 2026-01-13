# Cookbook:: rbmonitor
# Provider:: config

action :add do
  begin
    config_dir = new_resource.config_dir
    kafka_topic = new_resource.kafka_topic
    hostname = new_resource.name
    hostip = new_resource.hostip
    community = new_resource.community
    log_level = new_resource.log_level

    # TODO: this should be pass as resource
    user = 'redborder-monitor'

    device_nodes = new_resource.device_nodes
    snmp_nodes = new_resource.snmp_nodes
    redfish_nodes = new_resource.redfish_nodes
    ipmi_nodes = new_resource.ipmi_nodes
    flow_nodes = new_resource.flow_nodes
    proxy_flow_nodes = new_resource.proxy_flow_nodes
    proxy_device_nodes = new_resource.proxy_device_nodes
    proxy_snmp_nodes = new_resource.proxy_snmp_nodes
    proxy_redfish_nodes = new_resource.proxy_redfish_nodes
    proxy_ipmi_nodes = new_resource.proxy_ipmi_nodes
    managers = new_resource.managers
    proxy_nodes = new_resource.proxy_nodes
    cluster = new_resource.cluster

    dnf_package 'redborder-monitor' do
      action :upgrade
    end

    # TODO: Check if this go here or should be in Require in the spec file
    # Installation of required utilities
    utilities = %w(atop bc net-snmp-utils fping pcstat)
    utilities.each do |utility|
      dnf_package utility do
        action :upgrade
      end
    end

    execute 'create_user' do
      command "/usr/sbin/useradd #{user}"
      ignore_failure true
      not_if "getent passwd #{user}"
    end

    directory config_dir do
      owner 'root'
      group 'root'
      mode '755'
    end

    resource = {}
    resource['kafka_topic'] = kafka_topic
    resource['hostname'] = hostname
    resource['hostip'] = hostip
    resource['community'] = community
    resource['log_level'] = log_level
    resource['device_nodes'] = device_nodes
    resource['snmp_nodes'] = snmp_nodes
    resource['redfish_nodes'] = redfish_nodes
    resource['ipmi_nodes'] = ipmi_nodes
    resource['flow_nodes'] = flow_nodes # In proxy, flow_nodes turned to not be nodes
    resource['proxy_flow_nodes'] = proxy_flow_nodes
    resource['proxy_device_nodes'] = proxy_device_nodes
    resource['proxy_snmp_nodes'] = proxy_snmp_nodes
    resource['proxy_redfish_nodes'] = proxy_redfish_nodes
    resource['proxy_ipmi_nodes'] = proxy_ipmi_nodes
    resource['managers'] = managers
    resource['proxy_nodes'] = proxy_nodes
    resource['cluster'] = cluster

    template "#{config_dir}/config.json" do
      source 'config.json.erb'
      owner 'root'
      group 'root'
      cookbook 'rbmonitor'
      mode '0644'
      retries 2
      variables(resource: resource)
      helpers Rbmonitor::Helpers
      notifies :restart, 'service[redborder-monitor]', :delayed
    end

    service 'redborder-monitor' do
      service_name 'redborder-monitor'
      supports status: true, restart: true, start: true, enable: true
      action [:enable, :start]
    end
    Chef::Log.info('cookbook redborder-monitor has been processed.')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service 'redborder-monitor' do
      service_name 'redborder-monitor'
      supports status: true, restart: true, start: true, enable: true, disable: true
      action [:disable, :stop]
    end
    Chef::Log.info('cookbook redborder-monitor has been processed.')
  rescue => e
    Chef::Log.error(e.message)
  end
end
