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
        enrichment['uuid'] = redborder['sensor_uuid']
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
      send_flag = 0

      begin
        data_bag = data_bag_item('rBglobal', 'monitors')
      rescue
        data_bag = {}
      end

      resource_node['redborder']['monitors'].each do |resource_node_monitor|
        monitor = resource_node_monitor.to_hash
        name    = monitor['name']
        next unless name

        # skip if already inserted or not allowed by data_bag
        monitors_list = data_bag['monitors']
        next unless inserted[name].nil? && (monitors_list.nil? || monitors_list.include?(name))

        # decide send_flag for this monitor
        send_flag = resource_node['redborder']['monitors'].any? do |m|
          m = m.to_hash
          m['name'] == name && (m['send'].nil? || %w[1 true].include?(m['send'].to_s))
        end
        send_flag = send_flag ? 1 : 0

        # reorder keys: ensure 'name' first, 'send' last
        keys = monitor.keys.map(&:to_s).sort - %w[name send]
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

          protocol      = resource_node['redborder']['protocol']
          rest_user     = resource_node['redborder']['rest_api_user']
          rest_password = resource_node['redborder']['rest_api_password']
          ip            = resource_node['redborder']['ipaddress']

          if protocol == 'IPMI' && rest_user && rest_password
            cmd = "rb_get_sensor.sh -i #{ip} -u #{rest_user} -p #{rest_password}"
            val.gsub!('rb_get_sensor.sh', cmd)
          elsif protocol == 'Redfish' && rest_user && rest_password
            cmd = "rb_get_redfish.sh -i #{ip} -u #{rest_user} -p #{rest_password}"
            val.gsub!('rb_get_redfish.sh', cmd)
          end

          monitor[k] = val
        end

        monitor['send'] = send_flag
        inserted[name]  = true
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

      if resource['managers'] && !resource['managers'].empty?
        update_sensor_config(resource)
      else
        update_sensor_proxyips(resource)
      end

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
