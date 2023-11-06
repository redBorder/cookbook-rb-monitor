module Rbmonitor
  module Helpers
    
    def enrich(resource_node)
      node={}
      #node[:name] = resource_node["hostname"].nil? ? resource_node["name"] : resource_node["hostname"]
      node[:name] = resource_node["hostname"] if resource_node["hostname"]
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

    def monitors(resource_node, inserted)

      monit_array = []
      monit_aux = {}
      inserted = {}
      monitor_dg = Chef::DataBagItem.load("rBglobal", "monitors")  rescue monitor_dg={}

      if !resource_node.nil? and !resource_node["redborder"].nil? and !resource_node["redborder"]["monitors"].nil?
        send_kafka = false
        resource_node["redborder"]["monitors"].each do |monit|
          monit_aux = monit.to_hash
          next if ( (monit["name"]=="swap" or monit["name"]=="swap_free" or monit["name"]=="swap_total") and resource_node["memory"]["swap"]["total"].to_i==0 and resource_node["redborder"]["is_ips"]) 
          next if ( (monit["name"]=="system_temp" or monit["name"]=="" or monit["name"]=="" ) and !File.exist?"/dev/ipmi0" and !File.exist?"/dev/ipmi/0" and !File.exist?"/dev/ipmidev/0" and resource_node["redborder"]["is_ips"]) 
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
              ((i!=0) ? ", " : "" ) ; k #TODO deprecated line
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

    def update_config(resource)
      inserted = {}
      kafka_topic = resource["kafka_topic"]
      log_level = resource["log_level"]

      # Calls to add monitors
      update_service_config(resource)
      update_cluster_config(resource) if node["redborder"]["is_manager"]
      update_default_config(resource) if node["redborder"]["is_manager"] or node["redborder"]["is_proxy"]
      update_proxy_config(resource, inserted) if node["redborder"]["is_proxy"]
      update_sensor_config(resource, inserted) if node["redborder"]["is_manager"]

      update_ips_config(resource, inserted) if node["redborder"]["is_ips"]

      # Conf section
      if node["redborder"]["is_manager"]
        threads = [node.default[:redborder][:monitor][:count]/8, 5].min
        timeout = 40
        sleep_main_thread = 50
      elsif node["redborder"]["is_ips"] or node["redborder"]["is_proxy"]
        threads = 1
        timeout = 30
        sleep_main_thread = 25
      end

      node.default["redborder"]["monitor"]["config"][:conf] = {
        "debug" => log_level,
        "stdout" => 1,
        "syslog" => 0,
        "threads" => threads, 
        "timeout" => timeout,
        "max_snmp_fails" => 2,
        "max_kafka_fails" => 2,
        "sleep_main_thread" => sleep_main_thread,
        "sleep_worker_thread" => 5,
      }
      # TODO: IPS cloud
      if (node["redborder"]["is_ips"] and !node["redborder"]["cloud"].nil? and (node["redborder"]["cloud"]==1 or node["redborder"]["cloud"]=="1" or node["redborder"]["cloud"]==true or node["redborder"]["cloud"]=="true")) and node["redborder"]["sensor_id"] and node["redborder"]["sensor_id"].to_i>0
        node.default["redborder"]["monitor"]["config"][:conf] = node.default["redborder"]["monitor"]["config"][:conf].merge({
          "http_endpoint" => "https://data.#{node["redborder"]["cdomain"]}/rbdata/#{node["redborder"]["sensor_uuid"]}/rb_monitor",
          "http_max_total_connections" => 10,
          "http_timeout" => 10000,
          "http_connttimeout" => 10000,
          "http_verbose" => 0,
          "rb_http_max_messages" => 1024,
          "rb_http_mode" => "deflated"
        })
      else
        node.default["redborder"]["monitor"]["config"][:conf] = node.default["redborder"]["monitor"]["config"][:conf].merge({
          "kafka_broker" => "kafka.service",
          "kafka_timeout" => 2,
          "kafka_topic" => kafka_topic
        })
      end

      # Send the hash with all the sensors and the configuration to the template
      return node.default["redborder"]["monitor"]["config"]

    end

  end
end