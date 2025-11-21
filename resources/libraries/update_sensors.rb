module Rbmonitor
  module Helpers

    NODE_TYPES = {
      device: ['device_nodes', 'proxy_device_nodes'],
      flow:   ['flow_nodes',   'proxy_flow_nodes']
    }.freeze

    # ======================================================
    # Método principal
    # ======================================================
    def update_sensors(resource)
      NODE_TYPES.each do |type, (normal_key, proxy_key)|
        # IDs de sensores proxy para filtrar hijos
        proxy_nodes_array = resource["proxy_nodes"] || []

        # Solo sacamos los sensor_id de cada proxy
        proxy_sensor_ids = proxy_nodes_array.map do |proxy_node|
          proxy_node['redborder'] && proxy_node['redborder']['sensor_id']
        end.compact

        Chef::Log.info("Proxy array: #{proxy_nodes_array.map(&:name)}")
        Chef::Log.info("Proxies ids: #{proxy_sensor_ids}")

        # Manager procesa sensores normales, excluyendo hijos de proxies
        update_sensor_group(
          title: "/* #{type.to_s.upcase} SENSORS (MANAGER) */",
          nodes: resource[normal_key],
          manager_list: resource['managers'],
          hostname: resource['hostname'],
          exclude_parent_ids: proxy_sensor_ids
        )

        # Proxy SOLO procesa sensores proxy
        if node['redborder']['is_proxy']
          update_sensor_group(
            title: "/* #{type.to_s.upcase} SENSORS (PROXY) */",
            nodes: resource[proxy_key],
            manager_list: nil,
            hostname: nil,
            exclude_parent_ids: nil
          )
        end
      end
    end

    # ======================================================
    # Motor genérico
    # ======================================================
    def update_sensor_group(title:, nodes:, manager_list:, hostname:, exclude_parent_ids:)
      return if nodes.nil? || nodes.empty?

      Chef::Log.info("Nodes: #{nodes}")
      Chef::Log.info("Parents: #{exclude_parent_ids}")


      node.default['redborder']['monitor']['config']['sensors'] << title
      manager_index = manager_list && hostname ? manager_list.find_index(hostname) : nil

      nodes.each_with_index do |snode, index|
        next unless snode['redborder']
        next unless snode['redborder']['monitors'] && !snode['redborder']['monitors'].empty?
        next unless snode['ipaddress']

        # Saltar nodos que son hijos de proxies
        parent_id = snode.dig('redborder','parent_id')
        next if parent_id && exclude_parent_ids&.include?(parent_id)

        name  = snode['rbname'] || snode.name
        count = snode['redborder']['monitors'].size

        handle = manager_list && manager_index ? index % manager_list.length == manager_index : true

        if handle
          node.default['redborder']['monitor']['config']['sensors'] << "/* Node: #{name}    Monitors: #{count} */"
          sensor = build_sensor_hash(snode)
          node.default['redborder']['monitor']['count'] += count
          node.default['redborder']['monitor']['config']['sensors'] << sensor
        else
          node.default['redborder']['monitor']['config']['sensors'] << "/* Node: #{name}    Monitors: #{count} (not in this manager) */"
        end
      end
    end

    # ======================================================
    # Construcción del hash de sensor
    # ======================================================
    def build_sensor_hash(snode)
      {
        'timeout': 5,
        'sensor_name': snode['rbname'] || snode.name,
        'sensor_ip': snode['ipaddress'],
        'community': (snode['redborder']['snmp_community'].to_s.empty? ? 'public' : snode['redborder']['snmp_community'].to_s),
        'snmp_version': (snode['redborder']['snmp_version'].to_s.empty? ? '2c' : snode['redborder']['snmp_version'].to_s),
        'snmp_username': snode['redborder']['snmp_username'].to_s,
        'snmp_security_level': snode['redborder']['snmp_security_level'].to_s,
        'snmp_auth_protocol': snode['redborder']['snmp_auth_protocol'].to_s,
        'snmp_auth_password': snode['redborder']['snmp_auth_password'].to_s,
        'snmp_priv_protocol': snode['redborder']['snmp_priv_protocol'].to_s,
        'snmp_priv_password': snode['redborder']['snmp_priv_password'].to_s,
        'enrichment' => enrich(snode),
        'monitors' => monitors(snode)
      }
    end

  end
end
