module Rbmonitor
  module Helpers
    inserted = {}
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
      return node
    end

    def monitors(resource_node,inserted)

      monit_array = []
      monit_aux = {}
      inserted={}
      monitor_dg = Chef::DataBagItem.load("rBglobal", "monitors")
      if !resource_node.nil? and !resource_node["redborder"].nil? and !resource_node["redborder"]["monitors"].nil?
        send_kafka = false
        resource_node["redborder"]["monitors"].each do |monit|
          monit_aux = monit.to_hash
          if inserted[monit_aux["name"]].nil? and (monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?(monit_aux["name"]))
            resource_node["redborder"]["monitors"].each do |monit2|
              monit2_aux = monit2.to_hash
              send_kafka = true if (monit2_aux["name"] == monit_aux["name"] and (monit2_aux["send"].nil? or monit2_aux["send"]=="1" or monit2_aux["send"]==1 or monit2_aux["send"]==true))
            end
            send = send_kafka ? 1 : 0
            keys = monit_aux.keys.sort; keys.delete("name"); keys.delete("send"); keys.insert(0, "name")
            last_key = keys.length
            keys.insert(last_key, "send")
            keys.each_with_index do |k, i|
              ((i!=0) ? ", " : "" ) ; k
              monit_aux[k].to_s.gsub!("%sensor_ip", resource_node["ipaddress"])
              monit_aux[k].to_s.gsub!("%snmp_community", (resource_node["redborder"]["snmp_community"].nil? or resource_node["redborder"]["snmp_community"]=="") ? "public" : resource_node["redborder"]["snmp_community"].to_s)
              monit_aux[k].to_s.gsub!("%telnet_user", resource_node["redborder"]["telnet_user"].nil? ? "" : resource_node["redborder"]["telnet_user"])
              monit_aux[k].to_s.gsub!("%telnet_password", resource_node["redborder"]["telnet_password"].nil? ? "" : resource_node["redborder"]["telnet_password"])
              monit_aux[k].to_s.gsub!("rb_get_sensor.sh", (resource_node["redborder"]["protocol"] == "IPMI" and !resource_node["redborder"]["rest_api_user"].nil? and !resource_node["redborder"]["rest_api_password"].nil?) ? "rb_get_sensor.sh -i #{resource_node["redborder"]["ipaddress"]} -u #{resource_node["redborder"]["rest_api_user"]} -p #{resource_node["redborder"]["rest_api_password"]}" : "rb_get_sensor.sh" )
              monit_aux[k].to_s.gsub!("rb_get_redfish.sh", (resource_node["redborder"]["protocol"] == "Redfish" and !resource_node["redborder"]["rest_api_user"].nil? and !resource_node["redborder"]["rest_api_password"].nil?) ? "rb_get_redfish.sh -i #{resource_node["redborder"]["ipaddress"]} -u #{resource_node["redborder"]["rest_api_user"]} -p #{resource_node["redborder"]["rest_api_password"]}" : "rb_get_redfish.sh" )
              monit_aux["send"] = send
            end
            inserted[monit_aux["name"]]=true
          end
            monit_array.push(monit_aux)
        end
      end
      return monit_array
    end

    def config_hash(resource)
      config = {}
      inserted = {}

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

      # Kafka
      kafka_monitors = []
      begin
        if (node["redborder"]["services"]["kafka"] == true and  File.exist?"/tmp/kafka")
          kafka_monitors.push({"name"=> "kafka_disk_cached_pages", "system"=> "find /tmp/kafka/ \\( -size +1 -a -! -type d \\) -exec /opt/rb/bin/pcstat -terse {} \\+ | awk -F',' '{s+=$5;c+=$6}END{print c/s*100}'", "unit"=> "%"},)
          kafka_monitors.push({"name"=> "cache_hits", "system"=> "sudo /usr/lib/redborder/bin/cachestat.sh | awk '{$1=$1};1'", "unit"=> "%"})
        end
      rescue
        puts "Error, can't access to Kafka, skipping kafka monitors"
      end

      #Calculate used memory per service
      memory_monitors = []
      begin
        enabled_services = node["redborder"]["services"].map { |service|
          service[0] if service[1]
        }
        enabled_services.delete_if { |service| service == nil }
        enabled_services.each do |service|
          service_list = %w[ druid-broker druid-coordinator druid-historical druid-middleManager druid-overlord druid-realtime http2k kafka n2klocd redborder-nmsp redborder-postgresql webui zookeeper f2k ]
          if service_list.include? service
            serv = service.gsub("-", "_")
            memory_monitors.push({ "name" => "memory_total_#{serv}", "unit" => "kB", "integer" => 1, "send" => 0,
                                   "system" => "sudo /usr/lib/redborder/bin/rb_mem.sh -n #{service} 2>/dev/null" } )
            memory_monitors.push({ "name" => "memory_#{serv}", "op" => "100*(memory_total_#{serv})/memory_total", "unit" => "%"} )
          end
        end
      rescue
        puts "Can't access to redborder service list, skipping memory services monitorization"
      end

      #Create monitors array
      manager_monitors = []
      manager_monitors.concat(snmp_monitors)
      manager_monitors.concat(kafka_monitors)
      manager_monitors.concat(memory_monitors)

      # TODO: script dependencies
      if node["redborder"]["services"]["druid-middlemanager"] == true
        manager_monitors.push({ "name" => "running_tasks", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -u -n 2>/dev/null", "unit" => "tasks", "integer" => 1})
      end

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
        managers = node["redborder"]["managers_list"]

        if managers.length > 1
        next_manager = managers.at((managers.index(hostname)+1) % managers.length)
        next_manager_ip = node["redborder"]["cluster_info"][next_manager]["ip"]
          sensor = {
            "timeout" => 5,
            "sensor_name" => next_manager,
            "sensor_ip" => next_manager_ip,
            "community" => community,
            "snmp_version" => "2c",
            "monitors" => [
              { "name" => "latency",
                "system" => "nice -n 19 fping -q -s #{next_manager}.node 2>&1| grep 'avg round trip time'|awk '{print $1}'", "unit" => "ms" },
              { "name" => "pkts_lost",
                "system" => "nice -n 19 fping -p 1 -c 10 #{next_manager}.node 2>&1 | tail -n 1 | awk '{print $5}' | sed 's/%.*$//' | tr '/' ' ' | awk '{print $3}'", "unit" => "%" },
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

      # Logstash (TODO: resolve script dependencies)
      pipelines = ["bulkstats-pipeline", "location-pipeline", "meraki-pipeline", "mobility-pipeline", "monitor-pipeline", "netflow-pipeline", "nmsp-pipeline", "radius-pipeline", "rbwindow-pipeline", "redfish-pipeline", "scanner-pipeline", "sflow-pipeline", "social-pipeline", "vault-pipeline"]
      begin
        if node["redborder"]["services"]["logstash"] == true
          sensor= {
            "timeout"=>5,
            "sensor_name"=> hostname,
            "sensor_ip"=> hostip,
            "community" => community,
            "snmp_version"=> "2c",
            "monitors"=>
              [
                {"name"=> "logstash_cpu", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -c 2>/dev/null", "unit"=> "%"},
                {"name"=> "logstash_load_1", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -l 2>/dev/null", "unit"=> "%"},
                {"name"=> "logstash_load_5", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -m 2>/dev/null", "unit"=> "%"},
                {"name"=> "logstash_load_15", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -n 2>/dev/null", "unit"=> "%"},
                {"name"=> "logstash_heap", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -u 2>/dev/null", "unit"=> "%"},
                {"name"=> "logstash_events", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -e 2>/dev/null", "unit"=> "event", "integer"=> 1},
                {"name"=> "logstash_memory", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -v 2>/dev/null", "unit"=> "bytes", "integer"=> 1}
              ]
          }
          config["sensors"].push(sensor)
          pipelines.each do |pipeline|
            sensor_pipeline= {
              "timeout"=>5,
              "sensor_name"=> "#{hostname}-#{pipeline}",
              "sensor_ip"=> hostip,
              "community" => community,
              "snmp_version"=> "2c",
              "monitors"=>
                [
                  {"name"=> "logstash_events_per_pipeline", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -e "+pipeline+" 2>/dev/null", "unit"=> "event", "integer"=> 1},
                  {"name"=> "logstash_events_count_queue", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -w "+pipeline+" 2>/dev/null", "unit"=> "event", "integer"=> 1},
                  {"name"=> "logstash_events_count_queue_bytes", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -z "+pipeline+" 2>/dev/null", "unit"=> "bytes", "integer"=> 1}
                ]
            }
            config["sensors"].push(sensor_pipeline)
          end
        end
      rescue
        puts "Error accessing to redborder service list, skipping logstash monitorization"
      end

      # Druid overlord (TODO: resolve script dependencies)
      begin
        if node["redborder"]["services"]["druid-overlord"] == true
          sensor = {
            "timeout" => 5,
            "sensor_name" => "druid-overlord",
            "sensor_ip" => hostip,
            "community" => community,
            "snmp_version" => "2c",
            "monitors" => [
              { "name" => "pending_tasks", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -pn 2>/dev/null", "unit" => "tasks", "integer" => 1},
              { "name" => "running_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -on 2>/dev/null", "unit" => "tasks", "integer" => 1},
              { "name" => "desired_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -dn 2>/dev/null", "unit" => "task%", "integer" => 1}
            ]
          }
          config["sensors"].push(sensor)
        end
      rescue
        puts "Error accessing to redborder service list, skipping druid-overlord monitorization"
      end

      # Druid coordinator (TODO: resolve script dependencies)
      begin
        if node["redborder"]["services"]["druid-coordinator"] == true
          sensor = {
            "timeout" => 5,
            "sensor_name" => "druid-coordinator",
            "sensor_ip" => hostip,
            "community" => community,
            "snmp_version" => "2c",
            "monitors" => [
              { "name" => "hot_tier_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tiers.sh -t hot 2>/dev/null", "unit" => "%", "integer" => 1 },
              { "name" => "default_tier_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tiers.sh -t _default_tier 2>/dev/null", "unit" => "%", "integer" => 1 }
            ]
          }
       config["sensors"].push(sensor)
        end
      rescue
        puts "Error accessing to redborder service list, skipping druid-coordinator monitorization"
      end

      #####################################
      # SENSOR MONITORIZATION
      #####################################

      #cluster = resource["cluster"]
      #managers_index = cluster.map{|x| x.name}.index(node.name)

      # Remote sensors monitored or any managers
      flow_nodes = resource["flow_nodes"]
      manager_list = node["redborder"]["managers_list"]
      begin
        if !flow_nodes.nil? and manager_list.length>0
          manager_index = manager_list.find_index(hostname)
          flow_nodes.each_with_index do |fnode, findex|
            if !fnode["redborder"]["monitors"].nil? and !fnode["ipaddress"].nil? and fnode["redborder"]["parent_id"].nil?
              if findex % manager_list.length == manager_index and !fnode["redborder"].nil? and fnode["redborder"]["monitors"].size > 0
                sensor = {
                  "timeout" => 2000,
                  "sensor_name" => fnode["rbname"].nil? ? fnode.name : fnode["rbname"],
                  "sensor_ip" => fnode["ipaddress"],
                  "community" => (fnode["redborder"]["snmp_community"].nil? or fnode["redborder"]["snmp_community"]=="") ? "public" : fnode["redborder"]["snmp_community"].to_s,
                  "snmp_version" => (fnode["redborder"]["snmp_version"].nil? or fnode["redborder"]["snmp_version"]=="") ? "2c" : fnode["redborder"]["snmp_version"].to_s,
                  "enrichment" => enrich(flow_nodes[findex]),
                  "monitors" => monitors(flow_nodes[findex],inserted)
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
      manager_list = node["redborder"]["managers_list"]
      begin
        if !device_nodes.nil? and manager_list.length>0
          manager_index = manager_list.find_index(hostname)
          device_nodes.each_with_index do |dnode, dindex|
            if !dnode["redborder"]["monitors"].nil? and !dnode["ipaddress"].nil? and dnode["redborder"]["parent_id"].nil?
              if dindex % manager_list.length == manager_index and !dnode["redborder"].nil? and dnode["redborder"]["monitors"].length > 0
                sensor = {
                  "timeout" => 2000,
                  "sensor_name" => dnode["rbname"].nil? ? dnode.name : dnode["rbname"],
                  "sensor_ip" => dnode["ipaddress"],
                  "community" => (dnode["redborder"]["snmp_community"].nil? or dnode["redborder"]["snmp_community"]=="") ? "public" : dnode["redborder"]["snmp_community"].to_s,
                  "snmp_version" => (dnode["redborder"]["snmp_version"].nil? or dnode["redborder"]["snmp_version"]=="") ? "2c" : dnode["redborder"]["snmp_version"].to_s,
                  "enrichment" => enrich(device_nodes[dindex]),
                  "monitors" => monitors(device_nodes[dindex],inserted)
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