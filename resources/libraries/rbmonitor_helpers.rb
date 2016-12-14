module Rbmonitor
  module Helpers

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
      # TODO
      

      return config
    end
  end
end