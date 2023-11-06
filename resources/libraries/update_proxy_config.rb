module Rbmonitor
  module Helpers
    
    def update_proxy_config(resource, inserted)
      
      #########################
      # PROXY MONITORIZATION
      #########################
      
      # FLOW SENSORS
      flow_nodes = resource["flow_nodes"]
      begin
        if !flow_nodes.nil?
          # Title of section
          node.default["redborder"]["monitor"]["config"][:sensors].push("/* PROXY FLOW SENSORS */")
          flow_nodes.each do |fnode|
            if fnode["redborder"]["monitors"].size > 0 and !fnode["ipaddress"].nil? and !fnode["redborder"]["sensor_uuid"].nil? 
              fnode_name = fnode["rbname"].nil? ? fnode.name : fnode["rbname"]
              fnode_count = fnode["redborder"]["monitors"].size
              # Title of sensor
              node.default["redborder"]["monitor"]["config"][:sensors].push("/* Node: #{fnode_name}    Monitors: #{fnode_count}  */")
              sensor = {
                "timeout" => 5,
                "sensor_name" => fnode_name,
                "sensor_ip" => fnode["ipaddress"],
                "community" => ((fnode["snmp_community"].nil? and fnode["snmp_community"].empty? ) ? "public" : fnode["snmp_community"]),
                "snmp_version" => "2c",
                "enrichment" => enrich(fnode),
                "monitors" => monitors(fnode,inserted).concat(
                [
                  {"name" => "latency"  , "system" => "nice -n 19 fping -q -s = #{fnode[:ipaddress]}  2>&1| grep 'avg round trip time'|awk '{print $1}'", "unit" => "ms"},
                  {"name" => "pkts_lost", "system" => "sudo /bin/nice -n 19 /usr/sbin/fping -p 1 -c 10 = #{fnode[:ipaddress]}  2>&1 | tail -n 1 | awk '{print $5}' | sed 's/%.*$//' | tr '/' ' ' | awk '{print $3}'", "unit" => "%"},
                  {"name" => "pkts_percent_rcv", "op" => "100 - pkts_lost", "unit" => "%"}
                ])
              }
              node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
              node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 3 + fnode["redborder"]["monitors"].length
            end
          end
        end
      rescue
        puts "Can't access to flow sensors, skipping..."
      end

      # DEVICES SENSORS
      device_nodes = resource["device_nodes"]
      begin
        if !device_nodes.nil?
          # Title of section
          node.default["redborder"]["monitor"]["config"][:sensors].push("/* DEVICE SENSORS */")
          device_nodes.each do |dnode|
            if dnode["redborder"]["monitors"].size > 0 and !dnode["ipaddress"].nil? and !dnode["redborder"]["sensor_uuid"].nil?
              dnode_name = dnode["rbname"].nil? ? dnode.name : dnode["rbname"]
              dnode_count = dnode["redborder"]["monitors"].size
              # Title of sensor
              node.default["redborder"]["monitor"]["config"][:sensors].push("/* Node: #{dnode_name}    Monitors: #{dnode_count}  */")
              sensor = {
                "timeout" => 5,
                "sensor_name" => dnode_name,
                "sensor_ip" => dnode["ipaddress"],
                "community" => (dnode["snmp_community"].nil? or dnode["snmp_community"]=="") ? "public" : dnode["snmp_community"].to_s,
                "snmp_version" => (dnode["snmp_version"].nil? or dnode["snmp_version"]=="") ? "2c" : dnode["snmp_version"].to_s,
                "enrichment" => enrich(dnode),
                "monitors" => monitors(dnode, inserted)
              }
              node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
              node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + dnode["redborder"]["monitors"].length
            end
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