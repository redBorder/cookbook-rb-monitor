module Rbmonitor
  module Helpers

    def enrich(resource_node)
      node={}
      node[:name] = resource_node["rbname"] if resource_node["rbname"]
      node[:uuid] = resource_node["redborder"]["sensor_uuid"] if resource_node["redborder"] and resource_node["redborder"]["sensor_uuid"]
      node[:service_provider] = resource_node["redborder"]["service_provider"] if resource_node["redborder"] and resource_node["redborder"]["service_provider"]
      node[:service_provider_uuid] = resource_node["redborder"]["service_provider_uuid"] if resource_node["redborder"] and resource_node["redborder"]["service_provider_uuid"]
      node[:namespace] = resource_node["redborder"]["namespace"] if resource_node["redborder"] and resource_node["redborder"]["namespace"]
      node[:namespace_uuid] = resource_node["redborder"]["namespace_uuid"] if resource_node["redborder"] and resource_node["redborder"]["namespace_uuid"]
      node[:organization] = resource_node["redborder"]["organization"] if resource_node["redborder"] and resource_node["redborder"]["organization"]
      node[:organization_uuid] = resource_node["redborder"]["organization_uuid"] if resource_node["redborder"] and resource_node["redborder"]["organization_uuid"]
      node[:building] = resource_node["redborder"]["building"] if resource_node["redborder"] and resource_node["redborder"]["building"]
      node[:building_uuid] = resource_node["redborder"]["building_uuid"] if resource_node["redborder"] and resource_node["redborder"]["building_uuid"]
      result = node
    end

    def config_hash(resource)
      config = {}

      #CONF SECTION
      kafka_topic = resource["kafka_topic"]
      log_level = resource["log_level"]
      config["conf"] = {
        "debug" => log_level,
        "stdout" => 1,
        "syslog" => 0,
        "threads" => 1,
        "timeout" => 40,
        "max_snmp_fails" => 2,
        "max_kafka_fails" => 2,
        "sleep_main_thread" => 40,
        "sleep_worker_thread" => 5,
        "kafka_broker" => "kafka.service",
        "kafka_timeout" => 2,
        "kafka_topic" => kafka_topic
      }

      #SENSORS SECTION
      config["sensors"] = []

      #Ping and packet statistics between managers
      hostname = resource["hostname"]
      hostip = resource["hostip"]
      community = resource["community"]

      ##########################
      # MANAGER MONITORIZATION
      ##########################

      # SNMP MONITORS FOR MANAGERS
      # OID extracted from http://www.debianadmin.com/linux-snmp-oids-for-cpumemory-and-disk-statistics.html
      snmp_monitors = [
        { "name" => "load_1",               "oid" => "UCD-SNMP-MIB::laLoad.1",        "unit" => "%" },
        { "name" => "cpu_idle",             "oid" => "UCD-SNMP-MIB::ssCpuIdle.0",     "unit" => "%",    "send" => 0 },
        { "name" => "cpu",                  "op"  => "100-cpu_idle",                  "unit" => "%" },
        { "name" => "memory_total",         "oid" => "UCD-SNMP-MIB::memTotalReal.0",  "unit" => "kB",   "send" => 0 },
        { "name" => "memory_free",          "oid" => "UCD-SNMP-MIB::memAvailReal.0",  "unit" => "kB",   "send" => 0 },
        { "name" => "memory_total_buffer",  "oid" => "UCD-SNMP-MIB::memBuffer.0",     "unit" => "kB",   "send" => 0 },
        { "name" => "memory_total_cache",   "oid" => "UCD-SNMP-MIB::memCached.0",     "unit" => "kB",   "send" => 0 },
        { "name" => "memory",                                                         "unit" => "%",
          "op" => "100*(memory_total-memory_free-memory_total_buffer-memory_total_cache)/memory_total" },
        { "name" => "memory_buffer",                                                  "unit" => "%",
          "op" => "100*memory_total_buffer/memory_total" },
        { "name" => "memory_cache",                                                   "unit" => "%",
          "op" => "100*memory_total_cache/memory_total" },
        { "name" => "swap_total",           "oid" => "UCD-SNMP-MIB::memTotalSwap.0",  "unit" => "kB",   "send" => 0,  "integer" => 1 },
        { "name" => "swap_free",            "oid" => "UCD-SNMP-MIB::memAvailSwap.0",  "unit" => "kB",   "send" => 0,  "integer" => 1 },
        { "name" => "swap",                                                           "unit" => "%",
          "op" => "100*(swap_total-swap_free)/swap_total" },
        { "name" => "avio",                                                           "unit" => "ms",
          "system" => "atop 2 2 |grep avio |  awk '{print $15}' | paste -s -d'+' | sed 's/^/scale=3; (/' | sed 's|$|)/2|' | bc" },
        { "name" => "disk",                 "oid" => "UCD-SNMP-MIB::dskPercent.1",    "unit" => "%" },
        { "name" => "disk_load",                                                      "unit" => "%",
          "system" => "snmptable -v 2c -c #{community} #{hostip} diskIOTable|grep ' dm-0 ' | awk '{print $7}'" }
      ]

      #Calculate used memory per service
      #TODO: script dependencies
      memory_monitors = []
      #begin
      #  enabled_services = node["redborder"]["services"].map { |service|
      #    service.keys[0] if service.values[0]
      #  }
      #  enabled_services.delete_if { |service| service == nil }
      #  enabled_services.each do |service|
      #    memory_monitors.push({ "name" => "memory_total_#{service}", "unit" => "kB", "integer" => 1, "send" => 0,
      #                            "system" => "sudo /opt/rb/bin/rb_mem.sh -f /opt/rb/var/sv/<%= x%>/supervise/pid 2>/dev/null" } )
      #    memory_monitors.push({ "name" => "memory_#{service}", "op" => "100*(memory_total_#{service})/memory_total", "unit" => "%"} )
      #  end
      #rescue
      #  puts "Can't access to redborder service list, skipping memory services monitorization"
      #end

      #Create monitors array
      manager_monitors = []
      manager_monitors.concat(snmp_monitors)
      manager_monitors.concat(memory_monitors)

      # TODO: script dependencies
      #if node["redborder"]["services"]["druid-middlemanager"]
      #  manager_monitors.push({ "name" => "running_tasks", "system" => "/opt/rb/bin/rb_get_tasks.sh -u -n 2>/dev/null", "unit" => "tasks", "integer" => 1})
      #end

      manager_sensor = {
        "timeout" => 5,
        "sensor_name" => hostname,
        "sensor_ip" => hostip,
        "community" => community,
        "snmp_version" => "2c",
        "monitors" => manager_monitors
      }
      #Finally, add manager sensor tu sensors array in config
      config["sensors"].push(manager_sensor)

      #########################
      # BETWEEN MANAGERS (Latency, pkts_lost and pkts_percent_rcv)
      #########################
      begin
        #Calculate next manager to calculate metrics with it
        manager_list = node["redborder"]["managers_list"]
        if manager_list.length > 1
          next_manager = manager_list.at(manager_list.index(hostname)+1 % manager_list.length)
          next_manager_ip = node["redborder"]["cluster_info"][next_manager]["ip"]
          sensor = {
            "timeout" => 5,
            "sensor_name" => next_manager,
            "sensor_ip" => next_manager_ip,
            "community" => community,
            "snmp_version" => "2c",
            "monitors" => [
              { "name" => "latency", "unit" => "ms",
                "system" => "nice -n 19 fping -q -s #{next_manager}.node 2>&1| grep 'avg round trip time'|awk '{print $1}'" },
              { "name" => "pkts_lost", "unit" => "%",
                "system" => "nice -n 19 fping -p 1 -c 10 #{next_manager}.node 2>&1 | tail -n 1 | awk '{print $5}' | sed 's/%.*$//' | tr '/' ' ' | awk '{print $3}'" },
              { "name" => "pkts_percent_rcv", "op" => "100 - pkts_lost", "unit" => "%" }
            ]
          }
          config["sensors"].push(sensor)
        end
      rescue
        puts "Can't access to manager list, skipping metrics between managers"
      end

      ####################################
      # SERVICE SPECIFIC MONITORIZATION
      ####################################

      # Hadoop resourcemanager (TODO: resolve script dependencies)
      #begin
      #  if node["redborder"]["services"]["hadoop-resourcemanager"]
      #    sensor = {
      #      "timeout" => 5,
      #      "sensor_name" => "hadoop-resourcemanager",
      #      "sensor_ip" => hostip,
      #      "community" => community,
      #      "snmp_version" => "2c",
      #      "monitors" => [
      #        { "name" => "yarn_memory", "system" => "/opt/rb/bin/rb_get_yarn_capacity.sh -m 2>/dev/null" => "unit" => "%", "integer" => 1 },
      #        { "name" => "yarn_apps_pending", "system" => "/opt/rb/bin/rb_get_yarn_capacity.sh -p 2>/dev/null", "unit" => "tasks", "integer" => 1 }
      #      ]
      #    }
      #    config["sensors"].push(sensor)
      #  end
      #rescue
      #  puts "Error accessing to redborder service list, skipping hadoop-resourcemanager monitorization"
      #end

      # Druid overlord (TODO: resolve script dependencies)
      #begin
      #  if node["redborder"]["services"]["druid-overlord"]
      #    sensor = {
      #      "timeout" => 5,
      #      "sensor_name" => "druid-overlord",
      #      "sensor_ip" => hostip,
      #      "community" => community,
      #      "snmp_version" => "2c",
      #      "monitors" => [
      #        { "name" => "pending_tasks", "system" => "/opt/rb/bin/rb_get_tasks.sh -pn 2>/dev/null", "unit" => "tasks", "integer" => 1},
      #        { "name" => "running_capacity", "system" => "/opt/rb/bin/rb_get_tasks.sh -on 2>/dev/null", "unit" => "tasks", "integer" => 1},
      #        { "name" => "desired_capacity", "system" => "/opt/rb/bin/rb_get_tasks.sh -dn 2>/dev/null", "unit" => "task%", "integer" => 1}
      #      ]
      #    }
      #  end
      #rescue
      #  puts "Error accessing to redborder service list, skipping druid-overlord monitorization"
      #end

      # Druid coordinator (TODO: resolve script dependencies)
      #begin
      #  if node["redborder"]["services"]["druid-coordinator"]
      #    sensor = {
      #      "timeout" => 5,
      #      "sensor_name" => "druid-overlord",
      #      "sensor_ip" => hostip,
      #      "community" => community,
      #      "snmp_version" => "2c",
      #      "monitors" => [
      #        { "name" => "hot_tier_capacity", "system" => "/opt/rb/bin/rb_get_tiers.sh -l -t hot 2>/dev/null", "unit" => "%", "integer" => 1 },
      #        { "name" => "default_tier_capacity", "system" => "/opt/rb/bin/rb_get_tiers.sh -l -t _default_tier 2>/dev/null", "unit" => "%", "integer" => 1 }
      #      ]
      #    }
      #  end
      #rescue
      #  puts "Error accessing to redborder service list, skipping druid-overlord monitorization"
      #end

      #####################################
      # SENSOR MONITORIZATION
      #####################################

      # Remote sensors monitored or any managers
      flow_nodes = resource["flow_nodes"]
      monitor_dg = Chef::DataBagItem.load("rBglobal", "monitors")
      begin
        if !flow_nodes.nil? and manager_list.length>0
          flow_nodes.each_with_index do |fnode, findex|
            inserted={}
            if !fnode["redborder"]["monitors"].nil? and !fnode["ipaddress"].nil? and fnode["redborder"]["parent_id"].nil?
              if (findex%manager_list.length != manager_list.index and !fnode["redborder"].nil? and fnode["redborder"]["monitors"].size>0)
                sensor = {
                  "timeout" => 5,
                  "sensor_name" => fnode["rbname"].nil? ? fnode.name : fnode["rbname"],
                  "sensor_ip" => fnode["ipaddress"],
                  "community" => (fnode["redborder"]["snmp_community"].nil? or fnode["redborder"]["snmp_community"]=="") ? "public" : fnode["redborder"]["snmp_community"].to_s,
                  "snmp_version" => (fnode["redborder"]["snmp_version"].nil? or fnode["redborder"]["snmp_version"]=="") ? "2c" : fnode["redborder"]["snmp_version"].to_s,
                  "enrichment" => enrich(flow_nodes[findex]),
                  "monitors" =>
                    if !fnode.nil? and !fnode["redborder"].nil? and !fnode["redborder"]["monitors"].nil?
                      send_kafka = false
                      fnode["redborder"]["monitors"].each do |monit|
                        if inserted[monit["name"]].nil? and (monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?(monit["name"]))
                          fnode["redborder"]["monitors"].each do |monit2|
                            send_kafka = true if (monit2["name"] == monit["name"] and monit2["kafka"].nil? or monit2["kafka"]=="1" or monit2["kafka"]==1 or monit2["kafka"]==true)
                          end
                          send=[{"send" => send_kafka ? 1 : 0}]
                          keys = monit.keys.sort; keys.delete("name"); keys.delete("kafka"); keys.insert(0, "name")
                          last_key = keys.length
                          keys.insert(last_key, "send")
                          keys.each_with_index do |k, i|
                            ((i!=0) ? ", " : "" ) ; k
                            monit[k].to_s.gsub!("%sensor_ip", fnode["ipaddress"])
                            monit[k].to_s.gsub!("%snmp_community", (fnode["redborder"]["snmp_community"].nil? or fnode["redborder"]["snmp_community"]=="") ? "public" : fnode["redborder"]["snmp_community"].to_s)
                            monit[k].to_s.gsub!("%telnet_user", fnode["redborder"]["telnet_user"].nil? ? "" : fnode["redborder"]["telnet_user"])
                            monit[k].to_s.gsub!("%telnet_password", fnode["redborder"]["telnet_password"].nil? ? "" : fnode["redborder"]["telnet_password"])
                            if k == "send"
                              #send_kafka ? monit["send"] = "0" : monit["send"] = "1"
                              #fnode["redborder"]["monitors"].concat(send)
                              fnode.default["redborder"]["monitors"].inserted(last_key, send)
                            end
                          end
                        end
                      end
                    end
                }
                config["sensors"].push(sensor)
              end
            end
          end
        end
      rescue
        puts "Can't access to flow sensor, skipping..."
      end

      # DEVICES SENSORS
      device_nodes = resource["device_nodes"]
      monitor_dg = Chef::DataBagItem.load("rBglobal", "monitors")
      begin
        if !device_nodes.nil? and manager_list.length>0
          device_nodes.each_with_index do |dnode, dindex|
            inserted = {}
            if !dnode["redborder"]["monitors"].nil? and !dnode["ipaddress"].nil? and dnode["redborder"]["parent_id"].nil?
              if (dindex%manager_list.length != manager_list.index and !dnode["redborder"].nil? and dnode["redborder"]["monitors"].length>0)
                sensor = {
                  "timeout" => 5,
                  "sensor_name" => dnode["rbname"].nil? ? dnode.name : dnode["rbname"],
                  "sensor_ip" => dnode["ipaddress"],
                  "community" => (dnode["redborder"]["snmp_community"].nil? or dnode["redborder"]["snmp_community"]=="") ? "public" : dnode["redborder"]["snmp_community"].to_s,
                  "snmp_version" => (dnode["redborder"]["snmp_version"].nil? or dnode["redborder"]["snmp_version"]=="") ? "2c" : dnode["redborder"]["snmp_version"].to_s,
                  "enrichment" => enrich(device_nodes[dindex]),
                  "monitors" =>
                    if !dnode.nil? and !dnode["redborder"].nil? and !dnode["redborder"]["monitors"].nil?
                      dnode["redborder"]["monitors"].each do |monit|
                        if inserted[monit["name"]].nil? and (monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?(monit["name"]) or monit["name"].start_with? "custom_")
                          send_kafka = "false"
                          dnode["redborder"]["monitors"].each do |monit2|
                            send_kafka = "true" if (monit2["name"] == monit["name"] and (monit2["send"].nil? or monit2["send"]==1 or monit2["send"]==true))
                          end
                          #get_sensor = "rb_get_sensor"
                          keys = monit.keys.sort; keys.delete("name"); keys.delete("send"); keys.insert(0, "name")
                          keys.each_with_index do |k, i|
                            ((i!=0) ? ", " : "") ; k
                            monit[k].to_s.gsub!("%sensor_ip", dnode["ipaddress"])
                            monit[k].to_s.gsub!("%snmp_community", (dnode["redborder"]["snmp_community"].nil? or dnode["redborder"]["snmp_community"]=="") ? "public" : dnode["redborder"]["snmp_community"].to_s)
                            monit[k].to_s.gsub!("%telnet_user", dnode["redborder"]["telnet_user"].nil? ? "" : dnode["redborder"]["telnet_user"] )
                            monit[k].to_s.gsub!("%telnet_password", dnode["redborder"]["telnet_password"].nil? ? "" : dnode["redborder"]["telnet_password"])
                            #monit[k].to_s.gsub(rb_get_sensor.sh, (dnode["redborder"]["protocol"] == "IPMI" and !dnode["redborder"]["rest_api_user"].nil? and !dnode["redborder"]["rest_api_password"].nil?) ? rb_get_sensor.sh -i "#{dnode["redborder"]["ipaddress"]} -u #{dnode["redborder"]["rest_api_user"]} -p #{dnode["redborder"]["rest_api_password"]} : rb_get_sensor.sh").gsub(rb_get_redfish.sh, (dnode["redborder"]["protocol"] == "Redfish" and !dnode["redborder"]["rest_api_user"].nil? and !dnode["redborder"]["rest_api_password"].nil?) ? rb_get_redfish.sh -i "#{dnode["redborder"]["ipaddress"]} -u #{dnode["redborder"]["rest_api_user"]} -p #{dnode["redborder"]["rest_api_password"]}" : "rb_get_redfish.sh" )
                          end
                          #"send" ;  send_kafka ? "1" : "0"
                        end
                      end
                    end
                }
                config["sensors"].push(sensor)
              end
            end
          end
        end
      rescue
        puts "Can't access to device sensor, skipping..."
      end
      return config
    end
  end
end