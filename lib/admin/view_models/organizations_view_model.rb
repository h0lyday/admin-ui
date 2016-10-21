require 'date'
require 'set'
require 'thread'
require_relative 'has_application_instances_view_model'
require_relative '../utils'

module AdminUI
  class OrganizationsViewModel < AdminUI::HasApplicationInstancesViewModel
    def do_items
      organizations = @cc.organizations

      # organizations have to exist.  Other record types are optional
      return result unless organizations['connected']

      applications                   = @cc.applications
      containers                     = @doppler.containers
      domains                        = @cc.domains
      droplets                       = @cc.droplets
      events                         = @cc.events
      organizations_auditors         = @cc.organizations_auditors
      organizations_billing_managers = @cc.organizations_billing_managers
      organizations_managers         = @cc.organizations_managers
      organizations_users            = @cc.organizations_users
      packages                       = @cc.packages
      processes                      = @cc.processes
      quotas                         = @cc.quota_definitions
      route_mappings                 = @cc.route_mappings
      routes                         = @cc.routes
      security_groups_spaces         = @cc.security_groups_spaces
      service_brokers                = @cc.service_brokers
      service_instances              = @cc.service_instances
      service_plan_visibilities      = @cc.service_plan_visibilities
      space_quotas                   = @cc.space_quota_definitions
      spaces                         = @cc.spaces
      spaces_auditors                = @cc.spaces_auditors
      spaces_developers              = @cc.spaces_developers
      spaces_managers                = @cc.spaces_managers
      users                          = @cc.users_cc

      applications_connected              = applications['connected']
      containers_connected                = containers['connected']
      domains_connected                   = domains['connected']
      droplets_connected                  = droplets['connected']
      events_connected                    = events['connected']
      organizations_roles_connected       = organizations_auditors['connected'] && organizations_billing_managers['connected'] && organizations_managers['connected'] && organizations_users['connected']
      packages_connected                  = packages['connected']
      processes_connected                 = processes['connected']
      route_mappings_connected            = route_mappings['connected']
      routes_connected                    = routes['connected']
      security_groups_spaces_connected    = security_groups_spaces['connected']
      service_brokers_connected           = service_brokers['connected']
      service_instances_connected         = service_instances['connected']
      service_plan_visibilities_connected = service_plan_visibilities['connected']
      space_quotas_connected              = space_quotas['connected']
      spaces_connected                    = spaces['connected']
      spaces_roles_connected              = spaces_auditors['connected'] && spaces_developers['connected'] && spaces_managers['connected']
      users_connected                     = users['connected']

      applications_hash = Hash[applications['items'].map { |item| [item[:guid], item] }]
      droplets_hash     = Hash[droplets['items'].map { |item| [item[:guid], item] }]
      quota_hash        = Hash[quotas['items'].map { |item| [item[:id], item] }]
      routes_used_set   = route_mappings['items'].to_set { |route_mapping| route_mapping[:route_guid] }
      spaces_guid_hash  = Hash[spaces['items'].map { |item| [item[:guid], item] }]
      spaces_id_hash    = Hash[spaces['items'].map { |item| [item[:id], item] }]

      latest_droplets = latest_app_guid_hash(droplets['items'])
      latest_packages = latest_app_guid_hash(packages['items'])

      event_target_counters = {}
      organization_space_counters                   = {}
      organization_role_counters                    = {}
      organization_default_user_counters            = {}
      organization_domain_counters                  = {}
      organization_security_groups_counters         = {}
      organization_service_broker_counters          = {}
      organization_service_instance_counters        = {}
      organization_service_plan_visibility_counters = {}
      organization_route_counters_hash              = {}
      organization_app_counters_hash                = {}
      organization_process_counters_hash            = {}
      space_quota_counters                          = {}
      space_role_counters                           = {}

      events['items'].each do |event|
        return result unless @running
        Thread.pass

        organization_guid = event[:organization_guid]
        next if organization_guid.nil?
        event_target_counters[organization_guid] = 0 if event_target_counters[organization_guid].nil?
        event_target_counters[organization_guid] += 1
      end

      spaces_guid_hash.each_value do |space|
        return result unless @running
        Thread.pass

        organization_id = space[:organization_id]
        organization_space_counters[organization_id] = 0 if organization_space_counters[organization_id].nil?
        organization_space_counters[organization_id] += 1
      end

      count_organization_roles(organizations_auditors, organization_role_counters)
      count_organization_roles(organizations_billing_managers, organization_role_counters)
      count_organization_roles(organizations_managers, organization_role_counters)
      count_organization_roles(organizations_users, organization_role_counters)

      count_space_roles(spaces_id_hash, spaces_auditors, space_role_counters)
      count_space_roles(spaces_id_hash, spaces_developers, space_role_counters)
      count_space_roles(spaces_id_hash, spaces_managers, space_role_counters)

      users['items'].each do |user|
        return result unless @running
        Thread.pass

        default_space_id = user[:default_space_id]
        next if default_space_id.nil?
        space = spaces_id_hash[default_space_id]
        next if space.nil?
        organization_id = space[:organization_id]
        organization_default_user_counters[organization_id] = 0 if organization_default_user_counters[organization_id].nil?
        organization_default_user_counters[organization_id] += 1
      end

      service_brokers['items'].each do |service_broker|
        return result unless @running
        Thread.pass

        space_id = service_broker[:space_id]
        next if space_id.nil?
        space = spaces_id_hash[space_id]
        next if space.nil?
        organization_id = space[:organization_id]
        organization_service_broker_counters[organization_id] = 0 if organization_service_broker_counters[organization_id].nil?
        organization_service_broker_counters[organization_id] += 1
      end

      service_instances['items'].each do |service_instance|
        return result unless @running
        Thread.pass

        space = spaces_id_hash[service_instance[:space_id]]
        next if space.nil?
        organization_id = space[:organization_id]
        organization_service_instance_counters[organization_id] = 0 if organization_service_instance_counters[organization_id].nil?
        organization_service_instance_counters[organization_id] += 1
      end

      domains['items'].each do |domain|
        return result unless @running
        Thread.pass

        owning_organization_id = domain[:owning_organization_id]
        next if owning_organization_id.nil?
        organization_domain_counters[owning_organization_id] = 0 if organization_domain_counters[owning_organization_id].nil?
        organization_domain_counters[owning_organization_id] += 1
      end

      space_quotas['items'].each do |space_quota|
        return result unless @running
        Thread.pass

        organization_id = space_quota[:organization_id]
        next if organization_id.nil?
        space_quota_counters[organization_id] = 0 if space_quota_counters[organization_id].nil?
        space_quota_counters[organization_id] += 1
      end

      routes['items'].each do |route|
        return result unless @running
        Thread.pass

        space = spaces_id_hash[route[:space_id]]
        next if space.nil?
        organization_id = space[:organization_id]
        organization_route_counters = organization_route_counters_hash[organization_id]
        if organization_route_counters.nil?
          organization_route_counters =
            {
              'total_routes'  => 0,
              'unused_routes' => 0
            }
          organization_route_counters_hash[organization_id] = organization_route_counters
        end

        if route_mappings_connected
          organization_route_counters['unused_routes'] += 1 unless routes_used_set.include?(route[:guid])
        end
        organization_route_counters['total_routes'] += 1
      end

      service_plan_visibilities['items'].each do |service_plan_visibility|
        return result unless @running
        Thread.pass

        organization_id = service_plan_visibility[:organization_id]
        next if organization_id.nil?
        organization_service_plan_visibility_counters[organization_id] = 0 if organization_service_plan_visibility_counters[organization_id].nil?
        organization_service_plan_visibility_counters[organization_id] += 1
      end

      security_groups_spaces['items'].each do |security_group_space|
        return result unless @running
        Thread.pass

        space = spaces_id_hash[security_group_space[:space_id]]
        next if space.nil?
        organization_id = space[:organization_id]
        organization_security_groups_counters[organization_id] = 0 if organization_security_groups_counters[organization_id].nil?
        organization_security_groups_counters[organization_id] += 1
      end

      containers_hash = create_instance_hash(containers)

      applications['items'].each do |application|
        return result unless @running
        Thread.pass

        space = spaces_guid_hash[application[:space_guid]]
        next if space.nil?
        organization_id = space[:organization_id]
        organization_app_counters = organization_app_counters_hash[organization_id]
        if organization_app_counters.nil?
          organization_app_counters =
            {
              'total'       => 0,
              'used_memory' => 0,
              'used_disk'   => 0,
              'used_cpu'    => 0
            }
          organization_app_counters_hash[organization_id] = organization_app_counters
        end

        add_instance_metrics(organization_app_counters, application, droplets_hash, latest_droplets, latest_packages, containers_hash)
      end

      processes['items'].each do |process|
        return result unless @running
        Thread.pass

        application_guid = process[:app_guid]
        application = applications_hash[application_guid]
        next if application.nil?
        space = spaces_guid_hash[application[:space_guid]]
        next if space.nil?
        organization_id = space[:organization_id]
        organization_process_counters = organization_process_counters_hash[organization_id]

        if organization_process_counters.nil?
          organization_process_counters =
            {
              'reserved_memory' => 0,
              'reserved_disk'   => 0,
              'instances'       => 0
            }
          organization_process_counters_hash[organization_id] = organization_process_counters
        end

        add_process_metrics(organization_process_counters, process)
      end

      items = []
      hash  = {}

      organizations['items'].each do |organization|
        return result unless @running
        Thread.pass

        organization_id   = organization[:id]
        organization_guid = organization[:guid]
        quota             = quota_hash[organization[:quota_definition_id]]

        event_target_counter                         = event_target_counters[organization_guid]
        organization_default_user_counter            = organization_default_user_counters[organization_id]
        organization_role_counter                    = organization_role_counters[organization_id]
        organization_space_counter                   = organization_space_counters[organization_id]
        organization_service_broker_counter          = organization_service_broker_counters[organization_id]
        organization_service_instance_counter        = organization_service_instance_counters[organization_id]
        organization_service_plan_visibility_counter = organization_service_plan_visibility_counters[organization_id]
        organization_security_groups_counter         = organization_security_groups_counters[organization_id]
        organization_app_counters                    = organization_app_counters_hash[organization_id]
        organization_domain_counter                  = organization_domain_counters[organization_id]
        organization_process_counters                = organization_process_counters_hash[organization_id]
        organization_route_counters                  = organization_route_counters_hash[organization_id]
        space_quota_counter                          = space_quota_counters[organization_id]
        space_role_counter                           = space_role_counters[organization_id]

        row = []

        row.push(organization_guid)
        row.push(organization[:name])
        row.push(organization_guid)
        row.push(organization[:status])
        row.push(organization[:created_at].to_datetime.rfc3339)

        if organization[:updated_at]
          row.push(organization[:updated_at].to_datetime.rfc3339)
        else
          row.push(nil)
        end

        if event_target_counter
          row.push(event_target_counter)
        elsif events_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_space_counter
          row.push(organization_space_counter)
        elsif spaces_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_role_counter
          row.push(organization_role_counter)
        elsif organizations_roles_connected
          row.push(0)
        else
          row.push(nil)
        end

        if space_role_counter
          row.push(space_role_counter)
        elsif spaces_connected && spaces_roles_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_default_user_counter
          row.push(organization_default_user_counter)
        elsif users_connected
          row.push(0)
        else
          row.push(nil)
        end

        if quota
          row.push(quota[:name])
        else
          row.push(nil)
        end

        if space_quota_counter
          row.push(space_quota_counter)
        elsif space_quotas_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_domain_counter
          row.push(organization_domain_counter)
        elsif domains_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_service_broker_counter
          row.push(organization_service_broker_counter)
        elsif spaces_connected && service_brokers_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_service_plan_visibility_counter
          row.push(organization_service_plan_visibility_counter)
        elsif service_plan_visibilities_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_security_groups_counter
          row.push(organization_security_groups_counter)
        elsif spaces_connected && security_groups_spaces_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_route_counters
          row.push(organization_route_counters['total_routes'])
          row.push(organization_route_counters['total_routes'] - organization_route_counters['unused_routes'])
          row.push(organization_route_counters['unused_routes'])
        elsif spaces_connected && routes_connected
          row.push(0, 0, 0)
        else
          row.push(nil, nil, nil)
        end

        if organization_process_counters
          row.push(organization_process_counters['instances'])
        elsif spaces_connected && applications_connected && processes_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_service_instance_counter
          row.push(organization_service_instance_counter)
        elsif spaces_connected && service_instances_connected
          row.push(0)
        else
          row.push(nil)
        end

        if containers_connected
          if organization_app_counters
            row.push(Utils.convert_bytes_to_megabytes(organization_app_counters['used_memory']))
            row.push(Utils.convert_bytes_to_megabytes(organization_app_counters['used_disk']))
            row.push(organization_app_counters['used_cpu'])
          elsif spaces_connected && applications_connected
            row.push(0, 0, 0)
          else
            row.push(nil, nil, nil)
          end
        else
          row.push(nil, nil, nil)
        end

        if organization_process_counters
          row.push(organization_process_counters['reserved_memory'])
          row.push(organization_process_counters['reserved_disk'])
        elsif spaces_connected && applications_connected && processes_connected
          row.push(0, 0)
        else
          row.push(nil, nil)
        end

        if organization_app_counters
          row.push(organization_app_counters['total'])
        elsif spaces_connected && applications_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization_process_counters
          row.push(organization_process_counters['STARTED'] || 0)
          row.push(organization_process_counters['STOPPED'] || 0)
        elsif spaces_connected && applications_connected && processes_connected
          row.push(0, 0)
        else
          row.push(nil, nil)
        end

        if organization_app_counters && droplets_connected && packages_connected
          row.push(organization_app_counters['PENDING'] || 0)
          row.push(organization_app_counters['STAGED'] || 0)
          row.push(organization_app_counters['FAILED'] || 0)
        elsif spaces_connected && applications_connected && droplets_connected && packages_connected
          row.push(0, 0, 0)
        else
          row.push(nil, nil, nil)
        end

        items.push(row)

        hash[organization_guid] =
          {
            'organization'     => organization,
            'quota_definition' => quota
          }
      end

      result(true, items, hash, (1..32).to_a, (1..5).to_a << 11)
    end

    private

    def count_organization_roles(input_organization_role_array, output_organization_role_counter_hash)
      input_organization_role_array['items'].each do |input_organization_role_array_entry|
        Thread.pass
        organization_id = input_organization_role_array_entry[:organization_id]
        output_organization_role_counter_hash[organization_id] = 0 if output_organization_role_counter_hash[organization_id].nil?
        output_organization_role_counter_hash[organization_id] += 1
      end
    end

    def count_space_roles(spaces_id_hash, input_space_role_array, output_space_role_counter_hash)
      input_space_role_array['items'].each do |input_space_role_array_entry|
        Thread.pass
        space = spaces_id_hash[input_space_role_array_entry[:space_id]]
        next if space.nil?
        organization_id = space[:organization_id]
        output_space_role_counter_hash[organization_id] = 0 if output_space_role_counter_hash[organization_id].nil?
        output_space_role_counter_hash[organization_id] += 1
      end
    end
  end
end
