module Rbmonitor
  module Helpers
    def debug(str="/* Break point reached*/")#_line
      node.default['redborder']['monitor']['config']['sensors'].push(str)
    end

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

            # disperse sensors to each manager
            if (findex % manager_list.length) == manager_index && fnode['redborder'] && !fnode['redborder']['monitors'].empty?
              # Title of sensor
              node.default['redborder']['monitor']['config']['sensors'].push("/* Node: #{fnode_name}    Monitors: #{fnode_count}  */")

              # Variables SNMP y sensor
              timeout = 5
              sensor_name = fnode['rbname'].nil? ? fnode.name : fnode['rbname'] rescue 'Error'
              sensor_ip = fnode['ipaddress'] rescue 'Error'

              community = fnode.dig('redborder', 'snmp_community').to_s rescue 'Error'
              community = 'public' if community.empty? rescue 'Error'

              snmp_version = fnode.dig('redborder', 'snmp_version').to_s rescue 'Error'
              snmp_version = '2c' if snmp_version.empty? rescue 'Error'

              snmp_username = fnode.dig('redborder', 'snmp_username').to_s rescue 'Error'
              snmp_security_level = fnode.dig('redborder', 'snmp_security_level').to_s rescue 'Error'
              snmp_auth_protocol = fnode.dig('redborder', 'snmp_auth_protocol').to_s rescue 'Error'
              snmp_auth_password = fnode.dig('redborder', 'snmp_auth_password').to_s rescue 'Error'
              snmp_priv_protocol = fnode.dig('redborder', 'snmp_priv_protocol').to_s rescue 'Error'
              snmp_priv_password = fnode.dig('redborder', 'snmp_priv_password').to_s rescue 'Error'

              # Enrichment y monitors
              enrichment_value = enrich(fnode) rescue 'Error'
              monitors_value = monitors(fnode) rescue 'Error'

              # Debug de todos los parámetros
              debug "/*timeout = #{timeout}*/"
              debug "/*sensor_name = #{sensor_name}*/"
              debug "/*sensor_ip = #{sensor_ip}*/"
              debug "/*community = #{community}*/"
              debug "/*snmp_version = #{snmp_version}*/"
              debug "/*snmp_username = #{snmp_username}*/"
              debug "/*snmp_security_level = #{snmp_security_level}*/"
              debug "/*snmp_auth_protocol = #{snmp_auth_protocol}*/"
              debug "/*snmp_auth_password = #{snmp_auth_password}*/"
              debug "/*snmp_priv_protocol = #{snmp_priv_protocol}*/"
              debug "/*snmp_priv_password = #{snmp_priv_password}*/"
              debug "/*enrichment = #{enrichment_value}*/"
              debug "/*monitors = #{monitors_value}*/"

              begin
                sensor = {
                  'timeout': 5,
                  'sensor_name': fnode['rbname'].nil? ? fnode.name : fnode['rbname'],
                  'sensor_ip': fnode['ipaddress'],
                  'community': (fnode['redborder']['snmp_community'].nil? || fnode['redborder']['snmp_community'] == '') ? 'public' : fnode['redborder']['snmp_community'].to_s,
                  'snmp_version': (fnode['redborder']['snmp_version'].nil? || fnode['redborder']['snmp_version'] == '') ? '2c' : fnode['redborder']['snmp_version'].to_s,
                  'snmp_username': (fnode['redborder']['snmp_username'].nil? || fnode['redborder']['snmp_username'] == '') ? '' : fnode['redborder']['snmp_username'].to_s,
                  'snmp_security_level': (fnode['redborder']['snmp_security_level'].nil? || fnode['redborder']['snmp_security_level'] == '') ? '' : fnode['redborder']['snmp_security_level'].to_s,
                  'snmp_auth_protocol': (fnode['redborder']['snmp_auth_protocol'].nil? || fnode['redborder']['snmp_auth_protocol'] == '') ? '' : fnode['redborder']['snmp_auth_protocol'].to_s,
                  'snmp_auth_password': (fnode['redborder']['snmp_auth_password'].nil? || fnode['redborder']['snmp_auth_password'] == '') ? '' : fnode['redborder']['snmp_auth_password'].to_s,
                  'snmp_priv_protocol': (fnode['redborder']['snmp_priv_protocol'].nil? || fnode['redborder']['snmp_priv_protocol'] == '') ? '' : fnode['redborder']['snmp_priv_protocol'].to_s,
                  'snmp_priv_password': (fnode['redborder']['snmp_priv_password'].nil? || fnode['redborder']['snmp_priv_password'] == '') ? '' : fnode['redborder']['snmp_priv_password'].to_s,
                  'enrichment': enrich(fnode),
                  'monitors': monitors(fnode),
                }
                node.default['redborder']['monitor']['count'] = node.default['redborder']['monitor']['count'] + fnode['redborder']['monitors'].length
                node.default['redborder']['monitor']['config']['sensors'].push(sensor)
              rescue
                node.default['redborder']['monitor']['config']['sensors'].push('*/Error pushing sensor with monitors*/')
              end
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
                'snmp_username': (dnode['redborder']['snmp_username'].nil? || dnode['redborder']['snmp_username'] == '') ? '' : dnode['redborder']['snmp_username'].to_s,
                'snmp_security_level': (dnode['redborder']['snmp_security_level'].nil? || dnode['redborder']['snmp_security_level'] == '') ? '' : dnode['redborder']['snmp_security_level'].to_s,
                'snmp_auth_protocol': (dnode['redborder']['snmp_auth_protocol'].nil? || dnode['redborder']['snmp_auth_protocol'] == '') ? '' : dnode['redborder']['snmp_auth_protocol'].to_s,
                'snmp_auth_password': (dnode['redborder']['snmp_auth_password'].nil? || dnode['redborder']['snmp_auth_password'] == '') ? '' : dnode['redborder']['snmp_auth_password'].to_s,
                'snmp_priv_protocol': (dnode['redborder']['snmp_priv_protocol'].nil? || dnode['redborder']['snmp_priv_protocol'] == '') ? '' : dnode['redborder']['snmp_priv_protocol'].to_s,
                'snmp_priv_password': (dnode['redborder']['snmp_priv_password'].nil? || dnode['redborder']['snmp_priv_password'] == '') ? '' : dnode['redborder']['snmp_priv_password'].to_s,
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
