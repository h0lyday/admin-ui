require 'date'
require_relative 'base_view_model'

module AdminUI
  class ApplicationInstancesViewModel < AdminUI::BaseViewModel
    BILLION = 1000.0 * 1000.0 * 1000.0
    def do_items
      containers = @doppler.containers

      # containers have to exist. Other record types are optional
      return result unless containers['connected']

      applications  = @cc.applications
      droplets      = @cc.droplets
      organizations = @cc.organizations
      processes     = @cc.processes
      spaces        = @cc.spaces
      stacks        = @cc.stacks

      application_guid_hash = Hash[applications['items'].map { |item| [item[:guid], item] }]
      droplet_hash          = Hash[droplets['items'].map { |item| [item[:guid], item] }]
      organization_hash     = Hash[organizations['items'].map { |item| [item[:id], item] }]
      process_app_hash      = Hash[processes['items'].map { |item| [item[:app_guid], item] }]
      space_hash            = Hash[spaces['items'].map { |item| [item[:guid], item] }]
      stack_hash            = Hash[stacks['items'].map { |item| [item[:name], item] }]

      items = []
      hash  = {}

      containers['items'].each_value do |container|
        return result unless @running
        Thread.pass

        application_guid = container[:application_id]
        instance_index   = container[:instance_index]
        application      = application_guid_hash[application_guid]
        space            = application.nil? ? nil : space_hash[application[:space_guid]]
        organization     = space.nil? ? nil : organization_hash[space[:organization_id]]
        process          = process_app_hash[application_guid]
        droplet_guid     = application.nil? ? nil : application[:droplet_guid]
        droplet          = droplet_guid.nil? ? nil : droplet_hash[droplet_guid]
        stack            = nil

        # ContainerMetrics can come from either a Cell (rep) or a DEA as of cf-release 233
        diego = container[:origin] != 'DEA' # Coming from rep can be empty string. Better to check for !DEA.

        row = []

        key = "#{application_guid}/#{instance_index}"

        row.push(key)

        if application
          row.push(application[:name])
        else
          row.push(nil)
        end

        row.push(application_guid)
        row.push(container[:instance_index])

        row.push(Time.at(container[:timestamp] / BILLION).to_datetime.rfc3339)

        row.push(diego)

        stack_name = nil
        if droplet
          stack_name = droplet[:buildpack_receipt_stack_name]
          stack = stack_hash[stack_name] if stack_name
        end
        row.push(stack_name)

        row.push(Utils.convert_bytes_to_megabytes(container[:memory_bytes]))
        row.push(Utils.convert_bytes_to_megabytes(container[:disk_bytes]))
        row.push(container[:cpu_percentage])

        if process
          row.push(process[:memory])
          row.push(process[:disk_quota])
        else
          row.push(nil, nil)
        end

        if organization && space
          row.push("#{organization[:name]}/#{space[:name]}")
        else
          row.push(nil)
        end

        container_key = "#{container[:ip]}:#{container[:index]}"

        if diego
          row.push(nil)
          row.push(container_key)
        else
          row.push(container_key)
          row.push(nil)
        end

        items.push(row)

        hash[key] =
          {
            'application'  => application,
            'container'    => container,
            'droplet'      => droplet,
            'organization' => organization,
            'process'      => process,
            'space'        => space,
            'stack'        => stack
          }
      end

      result(true, items, hash, (1..14).to_a, [1, 2, 4, 5, 6, 12, 13, 14])
    end
  end
end
