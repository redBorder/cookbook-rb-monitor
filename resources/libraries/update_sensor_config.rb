module Rbmonitor
  module Helpers
  
    def update_sensor_config(resource, inserted)
    
      #####################################
      # SENSOR MONITORIZATION
      #####################################

      #cluster = resource["cluster"]
      #managers_index = cluster.map{|x| x.name}.index(node.name)

      # FLOW SENSORS
      flow_nodes = resource["flow_nodes"]
      manager_list = resource["managers"]
      begin
        if !flow_nodes.nil? and manager_list.length>0
          manager_index = manager_list.find_index(resource["hostname"])
          flow_nodes.each_with_index do |fnode, findex|
            if !fnode["redborder"]["monitors"].nil? and !fnode["ipaddress"].nil? and fnode["redborder"]["parent_id"].nil?
              if !fnode["redborder"].nil? and fnode["redborder"]["monitors"].size > 0
                sensor = {
                  "timeout" => 5,
                  "sensor_name" => fnode["rbname"].nil? ? fnode.name : fnode["rbname"],
                  "sensor_ip" => fnode["ipaddress"],
                  "community" => (fnode["redborder"]["snmp_community"].nil? or fnode["redborder"]["snmp_community"]=="") ? "public" : fnode["redborder"]["snmp_community"].to_s,
                  "snmp_version" => (fnode["redborder"]["snmp_version"].nil? or fnode["redborder"]["snmp_version"]=="") ? "2c" : fnode["redborder"]["snmp_version"].to_s,
                  "enrichment" => enrich(flow_nodes[findex]),
                  "monitors" => monitors(flow_nodes[findex],inserted)
                }
                node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + fnode["redborder"]["monitors"].length
                node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
              end
            end
          end
        end
      rescue
        puts "Can't access to flow sensor, skipping..."
      end

      # DEVICES SENSORS
      device_nodes = resource["device_nodes"]
      manager_list = node["redborder"]["managers_list"]
      begin
        if !device_nodes.nil? and manager_list.length>0
          manager_index = manager_list.find_index(resource["hostname"])
          device_nodes.each_with_index do |dnode, dindex|
            if !dnode["redborder"]["monitors"].nil? and !dnode["ipaddress"].nil? and dnode["redborder"]["parent_id"].nil?
              if !dnode["redborder"].nil? and dnode["redborder"]["monitors"].length > 0
                sensor = {
                  "timeout" => 5,
                  "sensor_name" => dnode["rbname"].nil? ? dnode.name : dnode["rbname"],
                  "sensor_ip" => dnode["ipaddress"],
                  "community" => (dnode["redborder"]["snmp_community"].nil? or dnode["redborder"]["snmp_community"]=="") ? "public" : dnode["redborder"]["snmp_community"].to_s,
                  "snmp_version" => (dnode["redborder"]["snmp_version"].nil? or dnode["redborder"]["snmp_version"]=="") ? "2c" : dnode["redborder"]["snmp_version"].to_s,
                  "enrichment" => enrich(device_nodes[dindex]),
                  "monitors" => monitors(device_nodes[dindex],inserted)
                }
                node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + dnode["redborder"]["monitors"].length
                node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
              end
            end
          end
        end
      rescue
        puts "Can't access to device sensor, skipping..."
      end

    end

  end
end