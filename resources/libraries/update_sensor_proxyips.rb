module Rbmonitor
  module Helpers
    def update_sensor_proxyips(resource)
      # SENSOR MONITORIZATION FOR PROXY AND IPS

      # TODO: Refactor
      # FLOW SENSORS
      flow_nodes = resource['flow_nodes']
      begin
        if flow_nodes
          # Title of section
          node.default['redborder']['monitor']['config']['sensors'].push('/* REMOTE SENSORS */')

          flow_nodes.each do |fnode|
            next unless !fnode['redborder']['monitors'].empty? && fnode['ipaddress']

            fnode_name = fnode['rbname'] || fnode.name
            fnode_count = fnode['redborder']['monitors']&.size || 0

            if fnode['redborder'] && !fnode['redborder']['monitors'].empty?
              # Title of sensor
              node.default['redborder']['monitor']['config']['sensors'].push("/* Node: #{fnode_name}    Monitors: #{fnode_count}  */")
              sensor = {
                'timeout': 5,
                'sensor_name': fnode_name,
                'sensor_ip': fnode['ipaddress'],
                'community': (fnode['redborder']['snmp_community'].nil? || fnode['redborder']['snmp_community'] == '') ? 'public' : fnode['redborder']['snmp_community'].to_s,
                'snmp_version' => (fnode['redborder']['snmp_version'].nil? || fnode['redborder']['snmp_version'] == '') ? '2c' : fnode['redborder']['snmp_version'].to_s,
                'enrichment' => enrich(fnode),
                'monitors' => monitors(fnode),
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
      begin
        if device_nodes
          # Title of section
          node.default['redborder']['monitor']['config']['sensors'].push('/* DEVICE SENSORS */')

          device_nodes.each do |dnode|
            next unless !dnode['redborder']['monitors'].empty? && dnode['ipaddress']

            dnode_name = dnode['rbname'] || dnode.name
            dnode_count = dnode['redborder']['monitors'].size

            if dnode['redborder'] && !dnode['redborder']['monitors'].empty?
              # Title of sensor
              node.default['redborder']['monitor']['config']['sensors'].push("/* Node: #{dnode_name}    Monitors: #{dnode_count}  */")
              sensor = {
                'timeout': 5,
                'sensor_name': dnode_name,
                'sensor_ip': dnode['ipaddress'],
                'community': (dnode['redborder']['snmp_community'].nil? || dnode['redborder']['snmp_community'] == '') ? 'public' : dnode['redborder']['snmp_community'].to_s,
                'snmp_version': (dnode['redborder']['snmp_version'].nil? || dnode['redborder']['snmp_version'] == '') ? '2c' : dnode['redborder']['snmp_version'].to_s,
                'enrichment' => enrich(dnode),
                'monitors' => monitors(dnode),
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
