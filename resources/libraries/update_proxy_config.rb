module Rbmonitor
  module Helpers
    
    def update_proxy_config(resource, inserted)
      
      #########################
      # PROXY MONITORIZATION
      #########################
      
      # INICIO
      begin
        if node["redborder"] and node["redborder"]["sensors_mapping"] and node["redborder"]["sensors_mapping"]["flow"] and node["redborder"]["sensors_mapping"]["flow"].size>0 
          flow_ips = []
          node["redborder"]["sensors_mapping"]["flow"].each do |rbname, flow_node|
            fnode_name = fnode["rbname"].nil? ? fnode.name : fnode["rbname"]
            fnode_count = fnode["redborder"]["monitors"].size
            if !flow_node["ipaddress"].nil? and !flow_ips.include?flow_node["ipaddress"] and !flow_node["sensor_uuid"].nil? 
              # Title of sensor
              node.default["redborder"]["monitor"]["config"][:sensors].push("/* Node: #{fnode_name}    Monitors: #{fnode_count}  */")
              sensor = {
                "timeout" => 5,
                "sensor_name" => rbname.nil? ? fnode.name : rbname,
                "sensor_ip" => flow_node[ipaddress],
                "community" => ((!flow_node[snmp_community].nil? and !flow_node[snmp_community].empty? ) ? flow_node[snmp_community] : "redborder" ),
                "snmp_version" => "2c",
                "enrichment" => enrich(flow_node),
                "monitors" =>
                [
                  {"name" => "latency"  , "system" => "nice -n 19 fping -q -s = #{flow_node[:ipaddress]}  2>&1| grep 'avg round trip time'|awk '{print $1}'", "unit" => "ms"},
                  {"name" => "pkts_lost", "system" => "sudo /bin/nice -n 19 /usr/sbin/fping -p 1 -c 10 = #{flow_node[:ipaddress]}  2>&1 | tail -n 1 | awk '{print $5}' | sed 's/%.*$//' | tr '/' ' ' | awk '{print $3}'", "unit" => "%"},
                  {"name" => "pkts_percent_rcv", "op" => "100 - pkts_lost", "unit" => "%"}
                ]
              },
              node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
              node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 3
            end
          end
        end
      rescue
        puts "Can't access to flow sensors, skipping..."
      end

      #-----------------------------------------------------
      
      begin
        if node["redborder"] and node["redborder"]["sensors_mapping"] and node["redborder"]["sensors_mapping"]["device"] and node["redborder"]["sensors_mapping"]["device"].size>0
          node["redborder"]["sensors_mapping"]["device"].each do |rbname, device_node|
            dnode_name = fnode["rbname"].nil? ? fnode.name : fnode["rbname"]
            dnode_count = fnode["redborder"]["monitors"].size
            # Title of sensor
            node.default["redborder"]["monitor"]["config"][:sensors].push("/* Node: #{dnode_name}    Monitors: #{dnode_count}  */")
            sensor = {
              "timeout" => 5,
              "sensor_name" => rbname.nil? ? device_node.name : rbname,
              "sensor_ip" => device_node["ipaddress"],
              "community" => (device_node["snmp_community"].nil? or device_node["snmp_community"]=="") ? "public" : device_node["snmp_community"].to_s,
              "snmp_version" => (device_node["snmp_version"].nil? or device_node["snmp_version"]=="") ? "2c" : device_node["snmp_version"].to_s,
              "enrichment" => enrich(device_node),
              "monitors" => monitors(device_node, inserted)
            },
            node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + device_node["redborder"]["monitors"].length
          end
        end
      rescue
        puts "Can't access to device sensors, skipping..."
      end
      
      #-----------------------------------------------------
      
      #if !node["redborder"].nil? and !node["redborder"]["sensors_mapping"].nil? and !node["redborder"]["sensors_mapping"]["flow"].nil? and node["redborder"]["sensors_mapping"]["flow"].size > 0 
      #  node["redborder"]["sensors_mapping"]["flow"].each do |rbname, fnode| 
      #    if !fnode["monitors"].nil? and fnode["monitors"].size>0 
      #      # Title of sensor
      #      node.default["redborder"]["monitor"]["config"][:sensors].push("/* Node: #{fnode_name}    Monitors: #{fnode_count}  */")
      #      sensor = {
      #        "timeout" => 5,
      #        "sensor_name" => rbname.nil? ? fnode.name : rbname,
      #        "sensor_ip" => fnode["ipaddress"],
      #        "community" => (fnode["snmp_community"].nil? or fnode["snmp_community"]=="") ? "public" : fnode["snmp_community"].to_s,
      #        "snmp_version" => (fnode["snmp_version"].nil? or fnode["snmp_version"]=="") ? "2c" : fnode["snmp_version"].to_s,
      #        "enrichment" => enrich(fnode)# Enrich function in helper
      #        "monitors" => monitors(fnode) # Monitors function in helper
      #      },
      #      node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + fnode["redborder"]["monitors"].length
      #      node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
      #    end
      #  end 
      #end # FINAL
 
    end

  end
end