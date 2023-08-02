module Rbmonitor
  module Helpers

    def monitors_ips_ids(resource_node,inserted)

      # IDS/IPS monitor 
      monit_array = []
      monit_aux = {}
      inserted = {}
      monitor_dg = Chef::DataBagItem.load("rBglobal", "monitors")  rescue monitor_dg={}
      node["redborder"]["snort"]["groups"].each do |id, original_group|
      group_name = (original_group["name"].nil? ? "none" : original_group["name"].to_s.gsub(' ',''))
      group_id   = (original_group["group_id"].nil? ? "0" : original_group["group_id"].to_s.gsub(' ',''))
      if original_group["cpu_list"] and original_group["segments"] and  original_group["cpu_list"].size>0 and original_group["segments"].size>0 and !original_group["monitors"].nil?
        monit_array = ["/* snort group monitoring #{group_name}  (manager group_id: #{group_id}; internal group_id:  #{id} ) Total monitors:  #{original_group["monitors"].size} */"]
        original_group["monitors"].each do |monit|
          monit_aux = monit.to_hash
            if inserted["#{monit["name"]}_#{group_id}"].nil? and (monitor_dg.nil? or monitor_dg.include?(monit["name"]))
              keys = monit.keys.sort; keys.delete("name"); keys.delete("system"); keys.delete("group_id"); keys.delete("group_name"); keys.insert(0, "name")
              keys.each_with_index do |k, i|
                ((i!=0) ? ", " : "" ) ; k
                monit_aux[k].to_s.gsub!("%group_id", "#{group_id}")
              end
              inserted["#{monit["name"]}_#{group_id}"]=true
            end
          monit_array.push(monit_aux)
        end
        end
      end
        return monit_array
    end


    def update_ips_config(resource, inserted)

      # IPS monitor
      ips_monitor = []
      begin
        ips_monitor.push({"name": "avio", "system": "atop 2 2 |grep avio |  awk '{print $15}' | paste -s -d'+' | sed 's/^/scale=3; (/' | sed 's|$|)/2|' | bc", "unit": "ms"},)
        ips_monitor.push({"name": "disk_load", "system": "snmptable -v 2c -c redborder 127.0.0.1 diskIOTable|grep ' dm-0 ' | awk '{print $7}'", "unit": "%"},)
        ips_monitor.push("/* Sensor monitoring - Total monitors: #{node["redborder"]["monitors"].size} */")
      rescue
        puts "Error IPS monitor"
      end

      #Create monitors array
      ips_monitors = []
      ips_monitors.concat(ips_monitor)
      ips_monitors.concat(monitors(node,inserted))
      ips_monitors.concat("/* IDS/IPS monitoring: */")
      ips_monitors.concat(monitors_ips_ids(node,inserted))


      ips_sensor = {
        "timeout" => 5,
        "sensor_name" => resource["hostname"],
        "sensor_ip" => resource["hostip"],
        "community" => resource["community"],
        "snmp_version" => "2c",
        "enrichment" => enrich(node),
        "monitors" => ips_monitors
      }
      node.default["redborder"]["monitor"]["config"][:sensors].push(ips_sensor)

    end
  end
end
