module Rbmonitor
  module Helpers
    def update_sensor_config(resource)
      # SENSOR MONITORIZATION

      # cluster = resource["cluster"]
      # managers_index = cluster.map{|x| x.name}.index(node.name)

      # FLOW SENSORS
      flow_nodes = resource['flow_nodes']
      manager_list = resource['managers']

      begin
        if flow_nodes && !manager_list.empty?
          # Title of section
          node.default['redborder']['monitor']['config']['sensors'].push('/* REMOTE SENSORS, MONITORED ON ANY MANAGER */')
          manager_index = manager_list.find_index(resource['hostname'])

          flow_nodes.each_with_index do |fnode, findex|
            next unless !fnode['redborder']['monitors'].empty? && fnode['ipaddress'] && fnode['redborder']['parent_id'].nil?

            fnode_name = fnode['rbname'].nil? ? fnode.name : fnode['rbname']
            fnode_count = fnode['redborder']['monitors'].size

            if findex % manager_list.length == manager_index && fnode['redborder'] && !fnode['redborder']['monitors'].empty?
              # Title of sensor
              node.default['redborder']['monitor']['config']['sensors'].push("/* Node: #{fnode_name}    Monitors: #{fnode_count}  */")
              sensor = {
                'timeout': 5,
                'sensor_name': fnode['rbname'].nil? ? fnode.name : fnode['rbname'],
                'sensor_ip': fnode['ipaddress'],
                'community': (fnode['redborder']['snmp_community'].nil? || fnode['redborder']['snmp_community'] == '') ? 'public' : fnode['redborder']['snmp_community'].to_s,
                'snmp_version' => (fnode['redborder']['snmp_version'].nil? || fnode['redborder']['snmp_version'] == '') ? '2c' : fnode['redborder']['snmp_version'].to_s,
                'enrichment' => enrich(flow_nodes[findex]),
                'monitors' => monitors(flow_nodes[findex]),
              }
              node.default['redborder']['monitor']['count'] = node.default['redborder']['monitor']['count'] + fnode['redborder']['monitors'].length
              node.default['redborder']['monitor']['config']['sensors'].push(sensor)
            else
              # The sensor is registered in another manager
              node.default['redborder']['monitor']['config']['sensors'].push("/* Node: #{fnode_name}    Monitors: #{fnode_count} (not in this manager) */")
            end
          end
        end
      rescue
        puts 'Cant access to flow sensor, skipping...'
      end

      # DEVICES SENSORS
      device_nodes = resource['device_nodes']
      manager_list = node['redborder']['managers_list']

      begin
        if device_nodes && !manager_list.empty?
          # Title of section
          node.default['redborder']['monitor']['config']['sensors'].push('/* DEVICE SENSORS */')
          manager_index = manager_list.find_index(resource['hostname'])

          device_nodes.each_with_index do |dnode, dindex|
            next unless !dnode['redborder']['monitors'].empty? && dnode['ipaddress'] && dnode['redborder']['parent_id'].nil?

            dnode_name = dnode['rbname'].nil? ? dnode.name : dnode['rbname']
            dnode_count = dnode['redborder']['monitors'].size

            if dindex % manager_list.length == manager_index && dnode['redborder'] && !dnode['redborder']['monitors'].empty?
              # Title of sensor
              node.default['redborder']['monitor']['config']['sensors'].push("/* Node: #{dnode_name}    Monitors: #{dnode_count}  */")
              sensor = {
                'timeout': 5,
                'sensor_name': dnode['rbname'].nil? ? dnode.name : dnode['rbname'],
                'sensor_ip': dnode['ipaddress'],
                'community': (dnode['redborder']['snmp_community'].nil? || dnode['redborder']['snmp_community'] == '') ? 'public' : dnode['redborder']['snmp_community'].to_s,
                'snmp_version': (dnode['redborder']['snmp_version'].nil? || dnode['redborder']['snmp_version'] == '') ? '2c' : dnode['redborder']['snmp_version'].to_s,
                'enrichment' => enrich(device_nodes[dindex]),
                'monitors' => monitors(device_nodes[dindex]),
              }
              node.default['redborder']['monitor']['count'] = node.default['redborder']['monitor']['count'] + dnode['redborder']['monitors'].length
              node.default['redborder']['monitor']['config']['sensors'].push(sensor)
            else
              # The sensor is registered in another manager
              node.default['redborder']['monitor']['config']['sensors'].push("/* Node: #{dnode_name}    Monitors: #{dnode_count} (not in this manager) */")
            end
          end
        end
      rescue
        puts 'Cant access to device sensor, skipping...'
      end
    end
  end
end
