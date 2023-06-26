module Rbmonitor
  module Helpers
  
    def update_manager_config(resource)

      ##########################
      # MANAGER MONITORIZATION
      ##########################

      # SNMP MONITORS FOR MANAGERS
      # OID extracted from http://www.debianadmin.com/linux-snmp-oids-for-cpumemory-and-disk-statistics.html
      monitor_dg = Chef::DataBagItem.load("rBglobal", "monitors")   rescue monitor_dg={}
      snmp_monitors = []
      begin
        if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("load_1") 
          snmp_monitors.push({"name": "load_1", "oid": "UCD-SNMP-MIB::laLoad.1", "unit": "%"},)
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1 
        end
        if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("cpu")
          snmp_monitors.push({"name": "cpu_idle", "oid": "UCD-SNMP-MIB::ssCpuIdle.0", "send": 0, "unit": "%"},)
          snmp_monitors.push({"name": "cpu", "op": "100-cpu_idle", "unit": "%"},)
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 2
        end
        if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("memory") or monitor_dg["monitors"].include?("memory_buffer") or monitor_dg["monitors"].include?("memory_cache")
          snmp_monitors.push({"name": "memory_total", "oid": "UCD-SNMP-MIB::memTotalReal.0", "send": 0, "unit": "kB" },)
          snmp_monitors.push({"name": "memory_free",  "oid": "UCD-SNMP-MIB::memAvailReal.0", "send": 0, "unit": "kB" },)
          snmp_monitors.push({"name": "memory_total_buffer", "oid": "UCD-SNMP-MIB::memBuffer.0", "send": 0, "unit": "kB" },)
          snmp_monitors.push({"name": "memory_total_cache", "oid": "UCD-SNMP-MIB::memCached.0", "send": 0, "unit": "kB" },)
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("memory")
            snmp_monitors.push({"name": "memory", "op": "100*(memory_total-memory_free-memory_total_buffer-memory_total_cache)/memory_total", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("memory_buffer")
             snmp_monitors.push({"name": "memory_buffer", "op": "100*memory_total_buffer/memory_total", "unit": "%"},)
             node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("memory_cache")
            snmp_monitors.push({"name": "memory_cache", "op": "100*memory_total_cache/memory_total", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 4
        end
        if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("swap")
          if !node.automatic["memory"].nil? and !node.automatic["memory"]["swap"].nil? and !node.automatic["memory"]["swap"]["total"].nil? and node.automatic["memory"]["swap"]["total"].to_i>0
            snmp_monitors.push({"name": "swap_total", "oid": "UCD-SNMP-MIB::memTotalSwap.0", "send": 0, "unit": "kB", "integer": 1 },)
            snmp_monitors.push({"name": "swap_free",  "oid": "UCD-SNMP-MIB::memAvailSwap.0", "send": 0, "unit": "kB", "integer": 1 },)
            snmp_monitors.push({"name": "swap",  "op": "100*(swap_total-swap_free)/swap_total", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 3
          end
        end
        if monitor_dg["monitors"].nil? and monitor_dg["monitors"].include?("avio")
          snmp_monitors.push({"name": "avio", "system": "atop 2 2 |grep avio |  awk '{print $15}' | paste -s -d'+' | sed 's/^/scale=3; (/' | sed 's|$|)/2|' | bc", "unit": "ms"},)
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
        end
        if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("disk")
          snmp_monitors.push({"name": "disk", "oid": "UCD-SNMP-MIB::dskPercent.1", "unit": "%"},)
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
        end
        if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("disk_load")
          snmp_monitors.push({"name": "disk_load", "system": "snmptable -v 2c -c redborder 127.0.0.1 diskIOTable|grep ' dm-0 ' | awk '{print $7}'", "unit": "%"})
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
        end

        if File.exist?("/dev/mapper/vg_rbdata-lv_aggregated")
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("disk_aggregated")
            snmp_monitors.push({"name": "disk_aggregated",  "oid": "UCD-SNMP-MIB::dskPercent.2", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("disk_aggregated_load")
            snmp_monitors.push({"name": "disk_aggregated_load", "system": "snmptable -v 2c -c redborder 127.0.0.1 diskIOTable|grep ' dm-1 ' | awk '{print $7}'", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
        end
        if File.exist?("/dev/mapper/vg_rbdata-lv_raw")
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("disk_raw")
            snmp_monitors.push({"name": "disk_raw", "oid": "UCD-SNMP-MIB::dskPercent.3", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("disk_raw_load")
            snmp_monitors.push({"name": "disk_raw_load", "system": "snmptable -v 2c -c redborder 127.0.0.1 diskIOTable|grep ' dm-2 ' | awk '{print $7}'", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end 
        elsif File.exist?("/dev/mapper/vg_rbdata-lv_raw")
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("disk_raw")
            snmp_monitors.push({"name": "disk_raw", "oid": "UCD-SNMP-MIB::dskPercent.2", "unit": "%"},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
        end
      rescue 
        puts "Error, can't access to SNMP monitors, skipping snmp monitors"
      end

      # IPMI monitors
      monitor_dg = Chef::DataBagItem.load("rBglobal", "monitors")   rescue monitor_dg={}
      ipmi_monitors = []
      
      begin
        if File.exist?("/dev/ipmi0") or File.exist?("/dev/ipmi/0") or File.exist?("/dev/ipmidev/0")
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("system_temp")
            ipmi_monitors.push({"name": "system_temp",      "system": "sudo /usr/lib/redborder/bin/rb_get_sensor.sh -t Temperature -s 'System Temp'", "unit": "celsius", "integer": 1},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("peripheral_temp")
            ipmi_monitors.push({"name": "peripheral_temp",  "system": "sudo /usr/lib/redborder/bin/rb_get_sensor.sh -t Temperature -s 'Peripheral[ Temp]*'", "unit": "celsius", "integer": 1},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("pch_temp")
            ipmi_monitors.push({"name": "pch_temp",         "system": "sudo /usr/lib/redborder/bin/rb_get_sensor.sh -t Temperature -s 'PCH Temp'", "unit": "celsius", "integer": 1},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
          if monitor_dg["monitors"].nil? or monitor_dg["monitors"].include?("fan")
            ipmi_monitors.push({"name": "fan",              "system": "sudo /usr/lib/redborder/bin/rb_get_sensor.sh -t Fan -a -s 'FAN[ ]*'", "unit": "rpm", "name_split_suffix": "_per_instance", "split": ";", "split_op": "mean", "instance_prefix": "fan-", "integer": 1},)
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
          end
        end
      rescue
        puts "Error, can't access to IPMI, skipping ipmi monitors"
      end

      # Kafka
      kafka_monitors = []
      begin
        if (node.default["redborder"]["services"]["kafka"] == true and  File.exist?"/tmp/kafka")
          kafka_monitors.push({"name"=> "kafka_disk_cached_pages", "system"=> "find /tmp/kafka/ \\( -size +1 -a -! -type d \\) -exec /usr/local/bin/pcstat -terse {} \\+ | awk -F',' '{s+=$5;c+=$6}END{print c/s*100}'", "unit"=> "%"},)
          kafka_monitors.push({"name"=> "cache_hits", "system"=> "sudo /usr/lib/redborder/bin/cachestat.sh | awk '{$1=$1};1'", "unit"=> "%"})
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
        end
      rescue
        puts "Error, can't access to Kafka, skipping kafka monitors"
      end

      #Calculate used memory per service
      memory_monitors = []
      begin
        enabled_services = node.default["redborder"]["services"].map { |service|
          service[0] if service[1]
        }
        enabled_services.delete_if { |service| service == nil }
        enabled_services.each do |service|
          service_list = %w[ druid-broker druid-coordinator druid-historical druid-middlemanager druid-overlord druid-realtime http2k kafka n2klocd redborder-nmsp redborder-postgresql webui zookeeper f2k ]
          if service_list.include? service
            serv = service.gsub("-", "_")
            memory_monitors.push({ "name" => "memory_total_#{serv}", "unit" => "kB", "integer" => 1, "send" => 0,
                                   "system" => "sudo /usr/lib/redborder/bin/rb_mem.sh -n #{service} 2>/dev/null" } )
            memory_monitors.push({ "name" => "memory_#{serv}", "op" => "100*(memory_total_#{serv})/memory_total", "unit" => "%"} )
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 2
          end
        end
      rescue
        puts "Can't access to redborder service list, skipping memory services monitorization"
      end

      #Create monitors array
      manager_monitors = []
      manager_monitors.concat(snmp_monitors)
      manager_monitors.concat(ipmi_monitors)
      manager_monitors.concat(kafka_monitors)
      manager_monitors.concat(memory_monitors)

      if node.default["redborder"]["services"]["druid-middlemanager"] == true
        manager_monitors.push({ "name" => "running_tasks", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -u -n 2>/dev/null", "unit" => "tasks", "integer" => 1})
        node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 1
      end

      manager_sensor = {
        "timeout" => 5,
        "sensor_name" => resource["hostname"],
        "sensor_ip" => resource["hostip"],
        "community" => resource["community"],
        "snmp_version" => "2c",
        "monitors" => manager_monitors
      }
      #Finally, add manager sensor to sensors array in config
      node.default["redborder"]["monitor"]["config"][:sensors].push(manager_sensor)

    end
    
  end
end