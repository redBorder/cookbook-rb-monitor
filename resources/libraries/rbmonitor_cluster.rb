module Rbmonitor
  module Helpers
    
    def config_hash_cluster(hostname, community)
      
      #########################
      # BETWEEN MANAGERS (Latency, pkts_lost and pkts_percent_rcv)
      #########################
      begin
        #Calculate next manager to calculate metrics with it
        managers = node.default["redborder"]["managers_list"]
        if managers.length > 1
          managers.each do | current_manager |
            next_manager = managers.at((managers.index(current_manager)+1) % managers.length)
            next_manager_ip = node.default[:redborder][:cluster_info][next_manager][:ip]
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
            node.default[:redborder][:monitor][:count] = node.default[:redborder][:monitor][:count] + 3
            node.default["redborder"]["monitor"]["config"][:sensors].push(sensor)
          end
        end
      rescue
        puts "Can't access to manager list, skipping metrics between managers"
      end

    end

  end
end