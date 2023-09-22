module Rbmonitor
  module Helpers
  
    def update_service_config(resource)

      ####################################
      # SERVICE SPECIFIC MONITORIZATION
      ####################################

      # Hadoop resourcemanager (TODO: resolve script dependencies)
      #begin
      #  if node.default["redborder"]["services"]["hadoop-resourcemanager"]
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
      #    node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
      #  end
      #rescue
      #  puts "Error accessing to redborder service list, skipping hadoop-resourcemanager monitorization"
      #end

      # Logstash
      pipelines = ["bulkstats-pipeline", "location-pipeline", "meraki-pipeline", "mobility-pipeline", "monitor-pipeline", "netflow-pipeline", "nmsp-pipeline", "radius-pipeline", "rbwindow-pipeline", "redfish-pipeline", "scanner-pipeline", "sflow-pipeline", "vault-pipeline"]
      begin
        if node.default["redborder"]["services"]["logstash"] == true
          sensor= {
            "timeout"=>5,
            "sensor_name"=> resource["hostname"],
            "sensor_ip"=> resource["hostip"],
            "community" => resource["community"],
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
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 7
          node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
          pipelines.each do |pipeline|
            sensor_pipeline= {
              "timeout"=>5,
              "sensor_name"=> "#{resource["hostname"]}-#{pipeline}",
              "sensor_ip"=> resource["hostip"],
              "community" => resource["community"],
              "snmp_version"=> "2c",
              "monitors"=>
                [
                  {"name"=> "logstash_events_per_pipeline", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -e "+pipeline+" 2>/dev/null", "unit"=> "event", "integer"=> 1},
                  {"name"=> "logstash_events_count_queue", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -w "+pipeline+" 2>/dev/null", "unit"=> "event", "integer"=> 1},
                  {"name"=> "logstash_events_count_queue_bytes", "system"=> "/usr/lib/redborder/bin/rb_get_logstash_stats.sh -z "+pipeline+" 2>/dev/null", "unit"=> "bytes", "integer"=> 1}
                ]
            }
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 3
            node.default["redborder"]["monitor"]["config"][:sensors].push(sensor_pipeline)
          end
        end
      rescue
        puts "Error accessing to redborder service list, skipping logstash monitorization"
      end

      # Druid-overlord
      begin
        if node.default["redborder"]["services"]["druid-overlord"] == true
          sensor = {
            "timeout" => 5,
            "sensor_name" => "druid-overlord",
            "sensor_ip"=> resource["hostip"],
            "community" => resource["community"],
            "snmp_version" => "2c",
            "monitors" => [
              { "name" => "pending_tasks", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -pn 2>/dev/null", "unit" => "tasks", "integer" => 1},
              { "name" => "running_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -on 2>/dev/null", "unit" => "tasks", "integer" => 1},
              { "name" => "desired_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tasks.sh -dn 2>/dev/null", "unit" => "task%", "integer" => 1}
            ]
          }
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 3
          node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
        end
      rescue
        puts "Error accessing to redborder service list, skipping druid-overlord monitorization"
      end

      # Druid-coordinator
      begin
        if node.default["redborder"]["services"]["druid-coordinator"] == true
          sensor = {
            "timeout" => 5,
            "sensor_name" => "druid-coordinator",
            "sensor_ip"=> resource["hostip"],
            "community" => resource["community"],
            "snmp_version" => "2c",
            "monitors" => [
              { "name" => "hot_tier_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tiers.sh -t hot 2>/dev/null", "unit" => "%", "integer" => 1 },
              { "name" => "default_tier_capacity", "system" => "/usr/lib/redborder/bin/rb_get_tiers.sh -t _default_tier 2>/dev/null", "unit" => "%", "integer" => 1 }
            ]
          }
          node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 2
          node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
        end
      rescue
        puts "Error accessing to redborder service list, skipping druid-coordinator monitorization"
      end

    end

  end
end