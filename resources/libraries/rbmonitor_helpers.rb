module Rbmonitor
  module Helpers
    def enrich(resource_node)
      enrichment = {}

      if resource_node['rbname']
        enrichment['name'] = resource_node['rbname']
      end

      redborder = resource_node['redborder']

      return enrichment unless redborder

      if redborder['sensor_uuid']
        enrichment['sensor_uuid'] = redborder['sensor_uuid']
      end

      if redborder['service_provider']
        enrichment['service_provider'] = redborder['service_provider']
      end

      if redborder['service_provider_uuid']
        enrichment['service_provider_uuid'] = redborder['service_provider_uuid']
      end

      if redborder['namespace']
        enrichment['namespace'] = redborder['namespace']
      end

      if redborder['namespace_uuid']
        enrichment['namespace_uuid'] = redborder['namespace_uuid']
      end

      if redborder['organization']
        enrichment['organization'] = redborder['organization']
      end

      if redborder['organization_uuid']
        enrichment['organization_uuid'] = redborder['organization_uuid']
      end

      if redborder['campus']
        enrichment['campus'] = redborder['campus']
      end

      if redborder['campus_uuid']
        enrichment['campus_uuid'] = redborder['campus_uuid']
      end

      if redborder['deployment']
        enrichment['deployment'] = redborder['deployment']
      end

      if redborder['deployment_uuid']
        enrichment['deployment_uuid'] = redborder['deployment_uuid']
      end

      if redborder['market']
        enrichment['market'] = redborder['market']
      end

      if redborder['market_uuid']
        enrichment['market_uuid'] = redborder['market_uuid']
      end

      if redborder['building']
        enrichment['building_uuid'] = redborder['building_uuid']
      end

      enrichment
    end

    def clean_snmp_command(command, redborder)
      replacements = {
        '%snmp_username'       => ['-u', redborder['snmp_username']],
        '%snmp_security_level' => ['-l', redborder['snmp_security_level']],
        '%snmp_auth_protocol'  => ['-a', redborder['snmp_auth_protocol']],
        '%snmp_auth_password'  => ['-A', redborder['snmp_auth_password']],
        '%snmp_priv_protocol'  => ['-x', redborder['snmp_priv_protocol']],
        '%snmp_priv_password'  => ['-X', redborder['snmp_priv_password']],
        '%sensor_ip'           => [nil, redborder['ipaddress']],
      }

      result = command.dup

      replacements.each do |placeholder, (flag, value)|
        if value.nil? || value.strip.empty?
          if flag
            result.gsub!(/#{Regexp.escape(flag)}\s*#{Regexp.escape(placeholder)}/, '')
          end
          result.gsub!(placeholder, '')
        else
          result.gsub!(placeholder, value)
        end
      end

      result.strip.squeeze('')
    end

    def monitors(resource_node)
      return [] unless resource_node && resource_node['redborder'] && resource_node['redborder']['monitors']

      monitors = []
      inserted = {}
      inserted_operations = []
      send_flag = 0

      begin
        data_bag = data_bag_item('rBglobal', 'monitors')
      rescue
        data_bag = {}
      end

      resource_node['redborder']['monitors'].each do |resource_node_monitor|
        monitor = resource_node_monitor.to_hash
        name    = monitor['name']
        operation = monitor['system']
        next unless name

        # skip if already inserted with the same operation if has operation or not allowed by data_bag
        monitors_list = data_bag['monitors']
        next unless (inserted[name].nil? || !inserted_operations.include?(operation)) && (monitors_list.nil? || monitors_list.include?(name))

        # decide send_flag for this monitor
        send_flag = resource_node['redborder']['monitors'].any? do |m|
          m = m.to_hash
          m['name'] == name && (m['send'].nil? || %w(1 true).include?(m['send'].to_s))
        end
        send_flag = send_flag ? 1 : 0

        # reorder keys: ensure 'name' first, 'send' last
        keys = monitor.keys.map(&:to_s).sort - %w(name send)
        keys.unshift('name')
        keys << 'send'

        keys.each do |k|
          val = monitor[k].to_s.dup

          val.gsub!('%sensor_ip', resource_node['ipaddress'].to_s)

          snmp_community = resource_node['redborder']['snmp_community']
          snmp_community = 'public' if snmp_community.nil? || snmp_community.empty?
          val.gsub!('%snmp_community', snmp_community)

          if monitor[k].is_a?(String) && monitor[k].include?('%snmp_')
            val = clean_snmp_command(val, resource_node['redborder'])
          end

          val.gsub!('%telnet_user', resource_node['redborder']['telnet_user'].to_s)
          val.gsub!('%telnet_password', resource_node['redborder']['telnet_password'].to_s)

          rest_user     = resource_node['redborder']['rest_api_user']
          rest_password = resource_node['redborder']['rest_api_password']
          redfish_user = resource_node['redborder']['redfish_user']
          redfish_password = resource_node['redborder']['redfish_password']
          ipmi_user = resource_node['redborder']['ipmi_user']
          ipmi_password = resource_node['redborder']['ipmi_password']
          ip            = resource_node['redborder']['ipaddress']

          # Update ip, user and password for IPMI monitors
          if (rest_user && rest_password) || (ipmi_user && ipmi_password)
            user = rest_user
            password = rest_password
            if ipmi_user && ipmi_password
              user = ipmi_user
              password = ipmi_password
            end
            cmd = "rb_get_sensor.sh -i #{ip} -u #{user} -p #{password}"
            val.gsub!('rb_get_sensor.sh', cmd)
          end

          # Update ip, user and password for REDFISH monitors
          if (rest_user && rest_password) || (redfish_user && redfish_password)
            user = rest_user
            password = rest_password
            if redfish_user && redfish_password
              user = redfish_user
              password = redfish_password
            end
            cmd = "rb_get_redfish.sh -i #{ip} -u #{user} -p #{password}"
            val.gsub!('rb_get_redfish.sh', cmd)
          end

          # Update ip, user and password for VMware ESXi VM monitors
          if val.include?('rb_vmware_exsi_vm_monitor.py')
            parent_id = resource_node['redborder']['parent_id']
            query = Chef::Search::Query.new
            parent_nodes = query.search(:node, "name:rbvmware-exsi-#{parent_id}").first
            parent_node = parent_nodes.first if parent_nodes

            vmware_user       = parent_node ? parent_node['redborder']['vmware_username'] : ''
            vmware_password   = parent_node ? parent_node['redborder']['vmware_password'] : ''
            vmware_datacenter = parent_node ? parent_node['redborder']['vmware_datacenter'] : ''
            vmware_folder     = parent_node ? parent_node['redborder']['vmware_folder'] : ''
            ip                = parent_node ? parent_node['redborder']['ipaddress'] : ''
            vm_name           = resource_node['rbname'] || resource_node.name
            cmd = "python3 /usr/lib/redborder/scripts/rb_vmware_exsi_vm_monitor.py -i #{ip} -u #{vmware_user} -p #{vmware_password} -d #{vmware_datacenter} -f #{vmware_folder} -n #{vm_name}"
            val.gsub!('rb_vmware_exsi_vm_monitor.py', cmd)

          # Update ip, user and password for VMware ESXi Host monitors
          elsif val.include?('rb_vmware_exsi_monitor.py')
            vmware_user       = resource_node['redborder']['vmware_username']
            vmware_password   = resource_node['redborder']['vmware_password']
            vmware_datacenter = resource_node['redborder']['vmware_datacenter']
            vmware_folder     = resource_node['redborder']['vmware_folder']
            ip                = resource_node['redborder']['ipaddress']
            cmd = "python3 /usr/lib/redborder/scripts/rb_vmware_exsi_monitor.py -i #{ip} -u #{vmware_user} -p #{vmware_password} -d #{vmware_datacenter} -f #{vmware_folder}"
            val.gsub!('rb_vmware_exsi_monitor.py', cmd)
          end

          # Format monitor enrichment as a correct JSON being a Ruby hash if is a endpoint
          if monitor[k].is_a?(Hash) && !monitor[k]['endpoint'].nil?
            val = monitor[k]
          end

          monitor[k] = val
        end

        monitor['send'] = send_flag
        inserted[name]  = true
        inserted_operations << operation
        monitors << monitor
      end

      monitors
    end

    def update_config(resource)
      # Conf section
      kafka_topic = resource['kafka_topic']
      log_level = resource['log_level']

      # Calls to add monitors
      update_cluster_config(resource)
      update_service_config(resource)
      update_manager_config(resource)
      update_sensors(resource)

      node.default['redborder']['monitor']['config']['conf'] = {
        'debug': log_level,
        'stdout': 1,
        'syslog': 0,
        'threads': [node.default['redborder']['monitor']['count'] / 8, 5].min,
        'timeout': 40,
        'max_snmp_fails': 2,
        'max_kafka_fails': 2,
        'sleep_main': 50,
        'sleep_worker': 5,
      }

      if (node['redborder']['cloud'] &&
          (node['redborder']['cloud'] == 1 ||
           node['redborder']['cloud'] == '1' ||
           node['redborder']['cloud'] == true ||
           node['redborder']['cloud'] == 'true')) &&
         node['redborder']['sensor_id'] && node['redborder']['sensor_id'].to_i > 0
        node.default['redborder']['monitor']['config']['conf'].merge!(
          'http_endpoint': "https://http2k.#{node['redborder']['cdomain']}/rbdata/#{node['redborder']['sensor_uuid']}/rb_monitor",
          'http_max_total_connections': 10,
          'http_timeout': 10000,
          'http_connttimeout': 10000,
          'http_verbose': 0,
          'rb_http_max_messages': 1024,
          'http_insecure': true,
          'rb_http_mode': 'normal'
        )
      else
        node.default['redborder']['monitor']['config']['conf'].merge!(
         'kafka_broker': 'kafka.service',
         'kafka_timeout': 2,
         'kafka_topic': kafka_topic)
      end

      # Send the hash with all the sensors and the configuration to the template
      node.default['redborder']['monitor']['config']
    end
  end
end
