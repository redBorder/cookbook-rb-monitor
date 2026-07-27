module Rbmonitor
  module Helpers
    NODE_TYPES = {
      device: %w(device_nodes proxy_device_nodes),
      snmp: %w(snmp_nodes proxy_snmp_nodes),
      redfish: %w(redfish_nodes proxy_redfish_nodes),
      ipmi: %w(ipmi_nodes proxy_ipmi_nodes),
      flow: %w(flow_nodes proxy_flow_nodes),
      http_agent: %w(http_agent_nodes proxy_http_agent_nodes),
      vmware_exsi: %w(vmware_exsi_nodes proxy_vmware_exsi_nodes),
      vmware_exsi_vm: %w(vmware_exsi_vm_nodes proxy_vmware_exsi_vm_nodes),
    }.freeze

    # ======================================================
    # Main
    # ======================================================
    def update_sensors(resource)
      node.default['redborder']['monitor']['config']['sensors'] << '/* Remote sensors */'

      NODE_TYPES.each do |type, (manager_key, proxy_key)|
        # Proxy sensor IDs to filter children
        proxy_nodes_array = resource['proxy_nodes'] || []

        proxy_sensor_ids = proxy_nodes_array.map do |proxy_node|
          proxy_node['redborder'] && proxy_node['redborder']['sensor_id']
        end.compact

        # Manager sensors
        update_sensor_group(
          title: "/* #{type.to_s.upcase} SENSORS */",
          nodes: resource[manager_key],
          manager_list: resource['managers'],
          hostname: resource['hostname'],
          exclude_parent_ids: proxy_sensor_ids,
          resource: resource
        )

        # Proxy sensors
        next unless node['redborder']['is_proxy']

        update_sensor_group(
          title: "/* #{type.to_s.upcase} SENSORS */",
          nodes: resource[proxy_key],
          manager_list: nil,
          hostname: nil,
          exclude_parent_ids: nil,
          resource: resource
        )
      end
    end

    # ======================================================
    # Generic engine
    # ======================================================
    def update_sensor_group(title:, nodes:, manager_list:, hostname:, exclude_parent_ids:, resource: {})
      return if nodes.nil? || nodes.empty?

      node.default['redborder']['monitor']['config']['sensors'] << title
      manager_index = manager_list && hostname ? manager_list.find_index(hostname) : nil

      nodes.each_with_index do |snode, index|
        next unless snode['redborder']

        is_vmware_exsi_vm = snode.primary_runlist.roles.include?('vmware-exsi-vm-sensor')

        next unless snode['redborder']['monitors'] && !snode['redborder']['monitors'].empty?

        is_http_agent = snode.primary_runlist.run_list_items.any? { |item| item.name == 'http_agent-sensor' }
        next if !snode['ipaddress'] && !is_http_agent && !is_vmware_exsi_vm

        # Exclude nodes that are children of proxies
        parent_id = snode['redborder'] && snode['redborder']['parent_id']
        if is_vmware_exsi_vm
          all_hosts = (resource['vmware_exsi_nodes'] || []) + (resource['proxy_vmware_exsi_nodes'] || [])
          parent_node = all_hosts.find { |n| n.name == "rbvmware-exsi-#{parent_id}" }
          host_parent_id = parent_node && parent_node['redborder'] && parent_node['redborder']['parent_id']
          next if exclude_parent_ids&.include?(host_parent_id)
        elsif exclude_parent_ids&.include?(parent_id)
          next
        end

        name  = snode['rbname'] || snode.name
        count = snode['redborder']['monitors'].size

        handle =
          if manager_list && manager_index
            index % manager_list.length == manager_index
          else
            true
          end

        if handle
          node.default['redborder']['monitor']['config']['sensors'] << "/* Node: #{name}    Monitors: #{count} */"
          sensor = build_sensor_hash(snode, resource)
          node.default['redborder']['monitor']['count'] += count
          node.default['redborder']['monitor']['config']['sensors'] << sensor
        else
          node.default['redborder']['monitor']['config']['sensors'] << "/* Node: #{name}    Monitors: #{count} (not in this manager) */"
        end
      end
    end

    # ======================================================
    # Sensor hash construction
    # ======================================================
    def build_sensor_hash(snode, resource = {})
      is_vmware_exsi = snode.primary_runlist.roles.include?('vmware-exsi-sensor')
      is_vmware_exsi_vm = snode.primary_runlist.roles.include?('vmware-exsi-vm-sensor')

      govc_username = ''
      govc_password = ''
      sensor_ip = snode['ipaddress']

      if is_vmware_exsi
        govc_username = snode['redborder']['vmware_username'].to_s
        govc_password = snode['redborder']['vmware_password'].to_s
      elsif is_vmware_exsi_vm
        parent_id = snode.dig('redborder', 'parent_id')
        all_hosts = (resource['vmware_exsi_nodes'] || []) + (resource['proxy_vmware_exsi_nodes'] || [])
        parent_node = all_hosts.find { |n| n.name == "rbvmware-exsi-#{parent_id}" }

        if parent_node
          govc_username = parent_node['redborder']['vmware_username'].to_s
          govc_password = parent_node['redborder']['vmware_password'].to_s
          sensor_ip = parent_node['ipaddress']
        end
      end

      {
        timeout: 5,
        sensor_name: snode['rbname'] || snode.name,
        sensor_ip: sensor_ip,
        community: (snode['redborder']['snmp_community'].to_s.empty? ? 'public' : snode['redborder']['snmp_community'].to_s),
        snmp_version: (snode['redborder']['snmp_version'].to_s.empty? ? '2c' : snode['redborder']['snmp_version'].to_s),
        snmp_username: snode['redborder']['snmp_username'].to_s,
        snmp_security_level: snode['redborder']['snmp_security_level'].to_s,
        snmp_auth_protocol: snode['redborder']['snmp_auth_protocol'].to_s,
        snmp_auth_password: snode['redborder']['snmp_auth_password'].to_s,
        snmp_priv_protocol: snode['redborder']['snmp_priv_protocol'].to_s,
        snmp_priv_password: snode['redborder']['snmp_priv_password'].to_s,
        govc_username: govc_username,
        govc_password: govc_password,
        enrichment: enrich(snode),
        monitors: monitors(snode),
      }
    end
  end
end
