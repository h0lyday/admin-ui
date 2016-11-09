require 'net/http'
require 'time'
require 'uri'
require 'yajl'
require_relative '../spec_helper'

module CCHelper
  # Workaround since I cannot instantiate Net::HTTPOK and have body() function successfully
  # Failing with NoMethodError: undefined method `closed?
  class OK < Net::HTTPOK
    attr_reader :body
    def initialize(hash)
      super(1.0, 200, 'OK')
      @body = Yajl::Encoder.encode(hash)
    end
  end

  # Workaround since I cannot instantiate Net::HTTPCreated and have body() function successfully
  # Failing with NoMethodError: undefined method `closed?
  class Created < Net::HTTPOK
    attr_reader :body
    def initialize
      super(1.0, 201, 'Created')
      @body = Yajl::Encoder.encode({})
    end
  end

  # Workaround since I cannot instantiate Net::HTTPNotFound and have body() function successfully
  # Failing with NoMethodError: undefined method `closed?
  class NotFound < Net::HTTPNotFound
    attr_reader :body
    def initialize(hash)
      super(1.0, 404, 'NotFound')
      @body = Yajl::Encoder.encode(hash)
    end
  end

  # Workaround since I cannot instantiate Net::HTTPBadRequest and have body() function successfully
  # Failing with NoMethodError: undefined method `closed?
  class BadRequest < Net::HTTPBadRequest
    attr_reader :body
    def initialize(hash)
      super(1.0, 400, 'BadRequest')
      @body = Yajl::Encoder.encode(hash)
    end
  end

  def cc_stub(config, populate_and_stub = true, insert_second_quota_definition = false, event_type = 'space')
    @last_unique_id   = 0
    @unique_ids       = {}

    @last_unique_time = Time.parse('2015-04-23 08:00:00 -0500')
    @unique_times     = {}

    return unless populate_and_stub

    @cc_apps_deleted                      = false
    @cc_buildpacks_deleted                = false
    @cc_domains_deleted                   = false
    @cc_feature_flags_deleted             = false
    @cc_organizations_deleted             = false
    @cc_quota_definitions_deleted         = false
    @cc_routes_deleted                    = false
    @cc_route_mappings_deleted            = false
    @cc_security_groups_deleted           = false
    @cc_security_groups_spaces_deleted    = false
    @cc_services_deleted                  = false
    @cc_service_bindings_deleted          = false
    @cc_service_brokers_deleted           = false
    @cc_service_instances_deleted         = false
    @cc_service_keys_deleted              = false
    @cc_service_plans_deleted             = false
    @cc_service_plan_visibilities_deleted = false
    @cc_space_quota_definitions_deleted   = false
    @cc_spaces_deleted                    = false
    @cc_users_deleted                     = false
    @uaa_groups_deleted                   = false
    @uaa_users_deleted                    = false
    @uaa_clients_deleted                  = false

    @cc_organization_created = false

    populate_db(config.ccdb_uri,  File.join(File.dirname(__FILE__), './ccdb'), ccdb_inserts(insert_second_quota_definition, event_type))
    populate_db(config.uaadb_uri, File.join(File.dirname(__FILE__), './uaadb'), uaadb_inserts)

    cc_login_stubs(config)
    cc_app_stubs(config)
    cc_buildpack_stubs(config)
    cc_domain_stubs(config)
    cc_feature_flag_stubs(config)
    cc_organization_stubs(config)
    cc_quota_definition_stubs(config)
    cc_route_stubs(config)
    cc_route_mapping_stubs(config)
    cc_security_group_stubs(config)
    cc_security_group_space_stubs(config)
    cc_service_stubs(config)
    cc_service_binding_stubs(config)
    cc_service_broker_stubs(config)
    cc_service_instance_stubs(config)
    cc_service_key_stubs(config)
    cc_service_plan_stubs(config)
    cc_service_plan_visibility_stubs(config)
    cc_space_stubs(config)
    cc_space_quota_definition_stubs(config)
    cc_user_stubs(config)

    uaa_client_stubs(config)
    uaa_group_stubs(config)
    uaa_user_stubs(config)
  end

  def cc_clear_apps_cache_stub(config)
    cc_clear_service_bindings_cache_stub(config)
    cc_clear_route_mappings_cache_stub(config)
    cc_clear_droplets_cache_stub(config)
    cc_clear_packages_cache_stub(config)
    cc_clear_processes_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM apps')

    @cc_apps_deleted = true
  end

  def cc_clear_buildpacks_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM buildpacks')

    @cc_buildpacks_deleted = true
  end

  def cc_clear_domains_cache_stub(config)
    cc_clear_routes_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM organizations_private_domains')
    sql(config.ccdb_uri, 'DELETE FROM domains')

    @cc_domains_deleted = true
  end

  def cc_clear_droplets_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM droplets')
  end

  def cc_clear_feature_flags_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM feature_flags')

    @cc_feature_flags_deleted = true
  end

  def cc_clear_organizations_cache_stub(config)
    cc_clear_domains_cache_stub(config)
    cc_clear_service_plan_visibilities_cache_stub(config)
    cc_clear_space_quota_definitions_cache_stub(config)
    cc_clear_spaces_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM organizations_auditors')
    sql(config.ccdb_uri, 'DELETE FROM organizations_billing_managers')
    sql(config.ccdb_uri, 'DELETE FROM organizations_managers')
    sql(config.ccdb_uri, 'DELETE FROM organizations_users')
    sql(config.ccdb_uri, 'DELETE FROM organizations')

    @cc_organizations_deleted = true
    @cc_organization_created  = false
  end

  def cc_clear_packages_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM packages')
  end

  def cc_clear_processes_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM processes')
  end

  def cc_clear_quota_definitions_cache_stub(config)
    cc_clear_organizations_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM quota_definitions')

    @cc_quota_definitions_deleted = true
  end

  def cc_clear_routes_cache_stub(config)
    cc_clear_route_mappings_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM routes')

    @cc_routes_deleted = true
  end

  def cc_clear_route_mappings_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM route_mappings')

    @cc_route_mappings_deleted = true
  end

  def cc_clear_security_groups_cache_stub(config)
    cc_clear_security_groups_spaces_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM security_groups')

    @cc_security_groups_deleted = true
  end

  def cc_clear_security_groups_spaces_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM security_groups_spaces')

    @cc_security_groups_spaces_deleted = true
  end

  def cc_clear_service_bindings_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM service_bindings')

    @cc_service_bindings_deleted = true
  end

  def cc_clear_service_brokers_cache_stub(config)
    cc_clear_services_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM service_dashboard_clients')
    sql(config.ccdb_uri, 'DELETE FROM service_brokers')

    @cc_service_brokers_deleted = true
  end

  def cc_clear_service_instances_cache_stub(config)
    cc_clear_service_bindings_cache_stub(config)
    cc_clear_service_keys_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM service_instance_operations')
    sql(config.ccdb_uri, 'DELETE FROM service_instances')

    @cc_service_instances_deleted = true
  end

  def cc_clear_service_keys_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM service_keys')

    @cc_service_keys_deleted = true
  end

  def cc_clear_service_plans_cache_stub(config)
    cc_clear_service_instances_cache_stub(config)
    cc_clear_service_plan_visibilities_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM service_plans')

    @cc_service_plans_deleted = true
  end

  def cc_clear_service_plan_visibilities_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM service_plan_visibilities')

    @cc_service_plan_visibilities_deleted = true
  end

  def cc_clear_services_cache_stub(config)
    cc_clear_service_plans_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM services')

    @cc_services_deleted = true
  end

  def cc_clear_space_quota_definitions_cache_stub(config)
    cc_clear_spaces_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM space_quota_definitions')

    @cc_space_quota_definitions_deleted = true
  end

  def cc_clear_spaces_cache_stub(config)
    cc_clear_routes_cache_stub(config)
    cc_clear_security_groups_spaces_cache_stub(config)
    cc_clear_service_brokers_cache_stub(config)
    cc_clear_users_cache_stub(config)
    cc_clear_apps_cache_stub(config)

    sql(config.ccdb_uri, 'DELETE FROM events')
    sql(config.ccdb_uri, 'DELETE FROM spaces')

    @cc_spaces_deleted = true
  end

  def cc_clear_users_cache_stub(config)
    sql(config.ccdb_uri, 'DELETE FROM spaces_auditors')
    sql(config.ccdb_uri, 'DELETE FROM spaces_developers')
    sql(config.ccdb_uri, 'DELETE FROM spaces_managers')
    sql(config.ccdb_uri, 'DELETE FROM organizations_auditors')
    sql(config.ccdb_uri, 'DELETE FROM organizations_billing_managers')
    sql(config.ccdb_uri, 'DELETE FROM organizations_managers')
    sql(config.ccdb_uri, 'DELETE FROM organizations_users')
    sql(config.ccdb_uri, 'DELETE FROM request_counts')
    sql(config.ccdb_uri, 'DELETE FROM users')

    @cc_users_deleted = true
  end

  def uaa_clear_approvals_cache_stub(config)
    sql(config.uaadb_uri, 'DELETE FROM authz_approvals')
  end

  def uaa_clear_clients_cache_stub(config)
    uaa_clear_approvals_cache_stub(config)

    sql(config.uaadb_uri, 'DELETE FROM oauth_client_details')

    @uaa_clients_deleted = true
  end

  def uaa_clear_group_membership_cache_stub(config)
    sql(config.uaadb_uri, 'DELETE FROM group_membership')
  end

  def uaa_clear_groups_cache_stub(config)
    uaa_clear_approvals_cache_stub(config)
    uaa_clear_group_membership_cache_stub(config)

    sql(config.uaadb_uri, 'DELETE FROM groups')

    @uaa_groups_deleted = true
  end

  def uaa_clear_users_cache_stub(config)
    uaa_clear_approvals_cache_stub(config)
    uaa_clear_group_membership_cache_stub(config)

    sql(config.uaadb_uri, 'DELETE FROM users')

    @uaa_users_deleted = true
  end

  def cc_app
    {
      created_at:           unique_time('cc_app_created'),
      desired_state:        'STARTED',
      droplet_guid:         cc_droplet_guid,
      guid:                 'application1',
      id:                   unique_id('cc_app'),
      max_task_sequence_id: 1,
      name:                 'test',
      space_guid:           cc_space[:guid],
      updated_at:           unique_time('cc_app_updated')
    }
  end

  def cc_app_rename
    'renamed_test'
  end

  def cc_buildpack
    {
      created_at: unique_time('cc_buildpack_created'),
      enabled:    true,
      filename:   'buildpack1.zip',
      guid:       'buildpack1',
      id:         unique_id('cc_buildpack'),
      key:        'buildpack_key1',
      locked:     false,
      name:       'Node.js',
      position:   1,
      updated_at: unique_time('cc_buildpack_updated')
    }
  end

  def cc_buildpack_rename
    'renamed Node.js'
  end

  def cc_domain
    {
      created_at:             unique_time('cc_domain_created'),
      guid:                   'domain1',
      id:                     unique_id('cc_domain'),
      name:                   'test_domain',
      owning_organization_id: cc_organization[:id],
      updated_at:             unique_time('cc_domain_updated')
    }
  end

  def cc_droplet_guid
    'droplet1'
  end

  def cc_droplet
    {
      app_guid:                         cc_app[:guid],
      buildpack_receipt_detect_output:  'node.js',
      buildpack_receipt_buildpack:      cc_buildpack[:name],
      buildpack_receipt_buildpack_guid: cc_buildpack[:guid],
      buildpack_receipt_stack_name:     cc_stack[:name],
      created_at:                       unique_time('cc_droplet_created'),
      droplet_hash:                     'droplet_hash1',
      error_description:                'An app was not successfully detected by any available buildpack',
      error_id:                         'NoAppDetectedError',
      execution_metadata:               '{}',
      guid:                             cc_droplet_guid,
      id:                               unique_id('cc_droplet'),
      package_guid:                     cc_package[:guid],
      process_types:                    '{"web":"node test.js"}',
      staging_disk_in_mb:               4096,
      staging_memory_in_mb:             1024,
      state:                            'STAGED',
      updated_at:                       unique_time('cc_droplet_updated')
    }
  end

  def cc_event_app
    {
      actee:             cc_app[:guid],
      actee_name:        cc_app[:name],
      actee_type:        'app',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_app_created'),
      guid:              'event1',
      id:                unique_id('cc_event_app'),
      metadata:          '{}',
      organization_guid: cc_organization[:guid],
      space_guid:        cc_space[:guid],
      timestamp:         unique_time('cc_event_app_timestamp'),
      type:              'audit.app.create',
      updated_at:        unique_time('cc_event_app_updated')
    }
  end

  def cc_event_route
    {
      actee:             cc_route[:guid],
      actee_name:        cc_route[:host],
      actee_type:        'route',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_route_created'),
      guid:              'event1',
      id:                unique_id('cc_event_route'),
      metadata:          '{}',
      organization_guid: cc_organization[:guid],
      space_guid:        cc_space[:guid],
      timestamp:         unique_time('cc_event_route_timestamp'),
      type:              'audit.route.create',
      updated_at:        unique_time('cc_event_route_updated')
    }
  end

  def cc_event_service
    {
      actee:             cc_service[:guid],
      actee_name:        cc_service[:label],
      actee_type:        'service',
      actor:             cc_service_broker[:guid],
      actor_name:        cc_service_broker[:name],
      actor_type:        'service_broker',
      created_at:        unique_time('cc_event_service_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service'),
      metadata:          '{}',
      organization_guid: '',
      space_guid:        '',
      timestamp:         unique_time('cc_event_service_timestamp'),
      type:              'audit.service.create',
      updated_at:        unique_time('cc_event_service_updated')
    }
  end

  def cc_event_service_binding
    {
      actee:             cc_service_binding[:guid],
      actee_name:        nil,
      actee_type:        'service_binding',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_service_binding_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service_binding'),
      metadata:          '{}',
      organization_guid: cc_organization[:guid],
      space_guid:        cc_space[:guid],
      timestamp:         unique_time('cc_event_service_binding_timestamp'),
      type:              'audit.service_binding.create',
      updated_at:        unique_time('cc_event_service_binding_updated')
    }
  end

  def cc_event_service_broker
    {
      actee:             cc_service_broker[:guid],
      actee_name:        cc_service_broker[:name],
      actee_type:        'service_broker',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_service_broker_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service_broker'),
      metadata:          '{}',
      organization_guid: '',
      space_guid:        '',
      timestamp:         unique_time('cc_event_service_broker_timestamp'),
      type:              'audit.service_broker.create',
      updated_at:        unique_time('cc_event_service_broker_updated')
    }
  end

  def cc_event_service_dashboard_client
    {
      actee:             uaa_client[:client_id],
      actee_name:        uaa_client[:client_id],
      actee_type:        'service_dashboard_client',
      actor:             cc_service_broker[:guid],
      actor_name:        cc_service_broker[:name],
      actor_type:        'service_broker',
      created_at:        unique_time('cc_event_service_dashboard_client_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service_dashboard_client'),
      metadata:          '{}',
      organization_guid: '',
      space_guid:        '',
      timestamp:         unique_time('cc_event_service_dashboard_client_timestamp'),
      type:              'audit.service_dashboard_client.create',
      updated_at:        unique_time('cc_event_service_dashboard_client_updated')
    }
  end

  def cc_event_service_instance
    {
      actee:             cc_service_instance[:guid],
      actee_name:        cc_service_instance[:name],
      actee_type:        'service_instance',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_service_instance_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service_instance'),
      metadata:          '{}',
      organization_guid: cc_organization[:guid],
      space_guid:        cc_space[:guid],
      timestamp:         unique_time('cc_event_service_instance_timestamp'),
      type:              'audit.service_instance.create',
      updated_at:        unique_time('cc_event_service_instance_updated')
    }
  end

  def cc_event_service_key
    {
      actee:             cc_service_key[:guid],
      actee_name:        cc_service_key[:name],
      actee_type:        'service_key',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_service_key_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service_key'),
      metadata:          '{}',
      organization_guid: cc_organization[:guid],
      space_guid:        cc_space[:guid],
      timestamp:         unique_time('cc_event_service_key_timestamp'),
      type:              'audit.service_key.create',
      updated_at:        unique_time('cc_event_service_key_updated')
    }
  end

  def cc_event_service_plan
    {
      actee:             cc_service_plan[:guid],
      actee_name:        cc_service_plan[:name],
      actee_type:        'service_plan',
      actor:             cc_service_broker[:guid],
      actor_name:        cc_service_broker[:name],
      actor_type:        'service_broker',
      created_at:        unique_time('cc_event_service_plan_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service_plan'),
      metadata:          '{}',
      organization_guid: '',
      space_guid:        '',
      timestamp:         unique_time('cc_event_service_plan_timestamp'),
      type:              'audit.service_plan.create',
      updated_at:        unique_time('cc_event_service_plan_updated')
    }
  end

  def cc_event_service_plan_visibility
    {
      actee:             cc_service_plan_visibility[:guid],
      actee_name:        nil,
      actee_type:        'service_plan_visibility',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_service_plan_visibility_created'),
      guid:              'event1',
      id:                unique_id('cc_event_service_plan_visibility'),
      metadata:          '{}',
      organization_guid: cc_organization[:guid],
      space_guid:        '',
      timestamp:         unique_time('cc_event_service_plan_visibility_timestamp'),
      type:              'audit.service_plan_visibility.create',
      updated_at:        unique_time('cc_event_service_plan_visibility_updated')
    }
  end

  def cc_event_space
    {
      actee:             cc_space[:guid],
      actee_name:        cc_space[:name],
      actee_type:        'space',
      actor:             cc_user[:guid],
      actor_name:        uaa_user[:username],
      actor_type:        'user',
      created_at:        unique_time('cc_event_space_created'),
      guid:              'event1',
      id:                unique_id('cc_event_space'),
      metadata:          '{}',
      organization_guid: cc_organization[:guid],
      space_guid:        cc_space[:guid],
      timestamp:         unique_time('cc_event_space_timestamp'),
      type:              'audit.space.create',
      updated_at:        unique_time('cc_event_space_updated')
    }
  end

  def cc_feature_flag
    {
      created_at:    unique_time('cc_feature_flag_created'),
      enabled:       true,
      error_message: 'feature flag error message',
      guid:          'feature1',
      id:            unique_id('cc_feature_flag'),
      name:          'app_scaling',
      updated_at:    unique_time('cc_feature_flag_updated')
    }
  end

  # /v2/info returned from the system is not symbols
  def cc_info
    {
      'authorization_endpoint'   => 'http://authorization_endpoint.com',
      'build'                    => '2222',
      'doppler_logging_endpoint' => 'wss://doppler_logging_endpoint.com',
      'token_endpoint'           => 'http://token_endpoint.com'
    }
  end

  def cc_organization
    {
      billing_enabled:     false,
      created_at:          unique_time('cc_organization_created'),
      guid:                'organization1',
      id:                  unique_id('cc_organization'),
      name:                'test_org',
      quota_definition_id: cc_quota_definition[:id],
      status:              'active',
      updated_at:          unique_time('cc_organization_updated')
    }
  end

  def cc_organization_rename
    'renamed_test_org'
  end

  def cc_organization2
    {
      billing_enabled:     false,
      created_at:          Time.new,
      guid:                'organization2',
      id:                  unique_id('cc_organization2'),
      name:                'new_org',
      quota_definition_id: cc_quota_definition[:id],
      status:              'active',
      updated_at:          nil
    }
  end

  def cc_organization_auditor
    {
      organization_id: cc_organization[:id],
      user_id:         cc_user[:id]
    }
  end

  def cc_organization_billing_manager
    {
      organization_id: cc_organization[:id],
      user_id:         cc_user[:id]
    }
  end

  def cc_organization_manager
    {
      organization_id: cc_organization[:id],
      user_id:         cc_user[:id]
    }
  end

  def cc_organization_private_domain
    {
      organization_id:   cc_organization[:id],
      private_domain_id: cc_domain[:id]
    }
  end

  def cc_organization_user
    {
      organization_id: cc_organization[:id],
      user_id:         cc_user[:id]
    }
  end

  def cc_package
    {
      app_guid:     cc_app[:guid],
      created_at:   unique_time('cc_package_created'),
      docker_image: 'cloudfoundry/diego-docker-app:latest',
      error:        nil,
      guid:         'package1',
      id:           unique_id('cc_package'),
      package_hash: 'package_hash1',
      state:        'READY',
      type:         'bits',
      updated_at:   unique_time('cc_package_updated')
    }
  end

  def cc_process
    {
      app_guid:             cc_app[:guid],
      command:              'node test.js',
      created_at:           unique_time('cc_process_created'),
      detected_buildpack:   cc_buildpack[:name],
      diego:                true,
      disk_quota:           1024,
      enable_ssh:           true,
      file_descriptors:     16_384,
      guid:                 'process1',
      health_check_timeout: nil,
      health_check_type:    'port',
      id:                   unique_id('cc_process'),
      instances:            1,
      memory:               128,
      metadata:             '{}',
      package_updated_at:   unique_time('cc_process_package_updated'),
      ports:                '"[8081]"',
      production:           true,
      state:                'STARTED',
      type:                 'web',
      updated_at:           unique_time('cc_process_updated'),
      version:              '87dc4122-8d26-4801-a98f-87d97cc76976'
    }
  end

  def cc_quota_definition
    {
      app_instance_limit:         10,
      app_task_limit:             10,
      created_at:                 unique_time('cc_quota_definition_created'),
      guid:                       'quota1',
      id:                         unique_id('cc_quota_definition'),
      instance_memory_limit:      512,
      memory_limit:               1024,
      name:                       'test_quota_1',
      non_basic_services_allowed: true,
      total_private_domains:      10,
      total_reserved_route_ports: 100,
      total_routes:               100,
      total_services:             100,
      total_service_keys:         100,
      updated_at:                 unique_time('cc_quota_definition_updated')
    }
  end

  def cc_quota_definition_rename
    'renamed_test_quota_1'
  end

  def cc_quota_definition2
    {
      app_instance_limit:         10,
      app_task_limit:             10,
      created_at:                 Time.new,
      guid:                       'quota2',
      id:                         unique_id('cc_quota_definition2'),
      instance_memory_limit:      512,
      memory_limit:               1024,
      name:                       'test_quota_2',
      non_basic_services_allowed: true,
      total_private_domains:      10,
      total_reserved_route_ports: 100,
      total_routes:               100,
      total_services:             100,
      total_service_keys:         100,
      updated_at:                 nil
    }
  end

  def cc_request_count
    {
      count:       11,
      id:          unique_id('cc_request_count'),
      user_guid:   cc_user[:guid],
      valid_until: unique_time('cc_request_count_valid')
    }
  end

  def cc_route
    {
      created_at: unique_time('cc_route_created'),
      domain_id:  cc_domain[:id],
      guid:       'route1',
      host:       'test_host',
      id:         unique_id('cc_route'),
      path:       '/path1',
      port:       0,
      space_id:   cc_space[:id],
      updated_at: unique_time('cc_route_updated')
    }
  end

  def cc_route_mapping
    {
      app_guid:     cc_app[:guid],
      app_port:     8080,
      created_at:   unique_time('cc_route_mapping_created'),
      guid:         'route_mapping1',
      id:           unique_id('cc_route_mapping'),
      process_type: 'web',
      route_guid:   cc_route[:guid],
      updated_at:   unique_time('cc_route_mapping_updated')
    }
  end

  def cc_security_group
    {
      created_at:          unique_time('cc_security_group_created'),
      guid:                'security_group1',
      id:                  unique_id('cc_security_group'),
      name:                'TestSecurityGroup',
      rules:               '[{"destination":"0.0.0.0/0","log":true,"protocol":"tcp","ports":"53","type":1,"code":2}]',
      running_default:     true,
      staging_default:     true,
      updated_at:          unique_time('cc_security_group_updated')
    }
  end

  def cc_security_group_rename
    'renamed_TestSecurityGroup'
  end

  def cc_security_group_space
    {
      security_group_id: cc_security_group[:id],
      space_id:          cc_space[:id]
    }
  end

  def cc_service_display_name
    'TestService display name'
  end

  def cc_service_provider_display_name
    'TestService prov display name'
  end

  def cc_service
    {
      active:            true,
      bindable:          true,
      created_at:        unique_time('cc_service_created'),
      description:       'TestService description',
      extra:             "{\"displayName\":\"#{cc_service_display_name}\",\"documentationUrl\":\"http://documentationUrl.com\",\"imageUrl\":\"http://docs.cloudfoundry.com/images/favicon.ico\",\"longDescription\":\"long description\",\"providerDisplayName\":\"#{cc_service_provider_display_name}\",\"supportUrl\":\"http://supportUrl.com\"}",
      guid:              'service1',
      id:                unique_id('cc_service'),
      label:             'TestService',
      plan_updateable:   true,
      purging:           false,
      requires:          '["syslog_drain", "route_forwarding", "volume_mount"]',
      service_broker_id: cc_service_broker[:id],
      tags:              '["service_tag1", "service_tag2"]',
      unique_id:         'service_unique_id',
      updated_at:        unique_time('cc_service_updated')
    }
  end

  def cc_service_binding
    {
      app_guid:              cc_app[:guid],
      created_at:            unique_time('cc_service_binding_created'),
      guid:                  'service_binding1',
      id:                    unique_id('cc_service_binding'),
      service_instance_guid: cc_service_instance[:guid],
      syslog_drain_url:      'http://service_binding_syslog_drain_url.com',
      updated_at:            unique_time('cc_service_binding_updated')
    }
  end

  # We do not retrieve credentials, but it is required for insert
  def cc_service_binding_with_credentials
    cc_service_binding.merge(credentials: '{}')
  end

  def cc_service_broker
    {
      auth_username: 'username',
      broker_url:    'http://broker_url.com',
      created_at:    unique_time('cc_service_broker_created'),
      guid:          'service_broker1',
      id:            unique_id('cc_service_broker'),
      name:          'TestServiceBroker',
      space_id:      cc_space[:id],
      updated_at:    unique_time('cc_service_broker_updated')
    }
  end

  # We do not retrieve auth_password, but it is required for insert
  def cc_service_broker_with_password
    cc_service_broker.merge(auth_password: 'password')
  end

  def cc_service_broker_rename
    'renamed_TestServiceBroker'
  end

  def cc_service_dashboard_client
    {
      service_broker_id: cc_service_broker[:id],
      uaa_id:            uaa_client[:client_id]
    }
  end

  def cc_service_instance
    {
      created_at:         unique_time('cc_service_instance_created'),
      guid:               'service_instance1',
      id:                 unique_id('cc_service_instance'),
      dashboard_url:      'http://dashboard_url.com',
      gateway_data:       nil,
      gateway_name:       nil,
      is_gateway_service: true,
      name:               'TestService-random',
      service_plan_id:    cc_service_plan[:id],
      space_id:           cc_space[:id],
      syslog_drain_url:   'http://service_instance_syslog_drain_url.com',
      tags:               '["service_instance_tag1", "service_instance_tag2"]',
      updated_at:         unique_time('cc_service_instance_updated')
    }
  end

  def cc_service_instance_rename
    'renamed_TestService-random'
  end

  def cc_service_instance_operation
    {
      broker_provided_operation: 'TestServiceInstanceOperation broker operation',
      created_at:                unique_time('cc_service_instance_operation_created'),
      description:               'TestServiceInstanceOperation description',
      guid:                      'service_instance_operation1',
      id:                        unique_id('cc_service_instance_operation'),
      proposed_changes:          '{}',
      service_instance_id:       cc_service_instance[:id],
      state:                     'succeeded',
      type:                      'create',
      updated_at:                unique_time('cc_service_instance_operation_updated')
    }
  end

  def cc_service_key
    {
      created_at:          unique_time('cc_service_key_created'),
      guid:                'service_key1',
      id:                  unique_id('cc_service_key'),
      name:                'TestServiceKey',
      service_instance_id: cc_service_instance[:id],
      updated_at:          unique_time('cc_service_key_updated')
    }
  end

  # We do not retrieve credentials, but it is required for insert
  def cc_service_key_with_credentials
    cc_service_key.merge(credentials: '{}')
  end

  def cc_service_plan_display_name
    'TestServicePlan display name'
  end

  def cc_service_plan
    {
      active:      true,
      created_at:  unique_time('cc_service_plan_created'),
      description: 'TestServicePlan description',
      extra:       "{\"displayName\":\"#{cc_service_plan_display_name}\",\"bullets\":[\"bullet1\",\"bullet2\"]}",
      free:        true,
      guid:        'service_plan1',
      id:          unique_id('cc_service_plan'),
      name:        'TestServicePlan',
      public:      true,
      service_id:  cc_service[:id],
      unique_id:   'service_plan_unique_id1',
      updated_at:  unique_time('cc_service_plan_updated')
    }
  end

  def cc_service_plan_visibility
    {
      created_at:      unique_time('cc_service_plan_visibility_created'),
      guid:            'service_plan_visibility1',
      id:              unique_id('cc_service_plan_visibility'),
      organization_id: cc_organization[:id],
      service_plan_id: cc_service_plan[:id],
      updated_at:      unique_time('cc_service_plan_visibility_updated')
    }
  end

  def cc_space
    {
      allow_ssh:                 true,
      created_at:                unique_time('cc_space_created'),
      guid:                      'space1',
      id:                        unique_id('cc_space'),
      name:                      'test_space',
      organization_id:           cc_organization[:id],
      space_quota_definition_id: cc_space_quota_definition[:id],
      updated_at:                unique_time('cc_space_updated')
    }
  end

  def cc_space_rename
    'renamed_test_space'
  end

  def cc_space_auditor
    {
      space_id: cc_space[:id],
      user_id:  cc_user[:id]
    }
  end

  def cc_space_developer
    {
      space_id: cc_space[:id],
      user_id:  cc_user[:id]
    }
  end

  def cc_space_manager
    {
      space_id: cc_space[:id],
      user_id:  cc_user[:id]
    }
  end

  def cc_space_quota_definition
    {
      app_instance_limit:         5,
      app_task_limit:             5,
      created_at:                 unique_time('cc_space_quota_definition_created'),
      guid:                       'space_quota1',
      id:                         unique_id('cc_space_quota_definition'),
      instance_memory_limit:      512,
      memory_limit:               1024,
      name:                       'test_space_quota_1',
      organization_id:            cc_organization[:id],
      non_basic_services_allowed: true,
      total_reserved_route_ports: 100,
      total_routes:               100,
      total_services:             100,
      total_service_keys:         100,
      updated_at:                 unique_time('cc_space_quota_definition_updated')
    }
  end

  def cc_space_quota_definition_rename
    'renamed_test_s_q_1' # Name needs to be 20 characters or less or the UI will truncate
  end

  def cc_space_quota_definition2
    {
      app_instance_limit:         5,
      app_task_limit:             5,
      created_at:                 Time.new,
      guid:                       'space_quota2',
      id:                         unique_id('cc_space_quota_definition2'),
      instance_memory_limit:      512,
      memory_limit:               1024,
      name:                       'test_space_quota_2',
      non_basic_services_allowed: true,
      organization_id:            cc_organization[:id],
      total_reserved_route_ports: 100,
      total_routes:               100,
      total_services:             100,
      total_service_keys:         100,
      updated_at:                 nil
    }
  end

  def cc_stack
    {
      created_at:  unique_time('cc_stack_created'),
      description: 'TestStack description',
      guid:        'stack1',
      id:          unique_id('cc_stack'),
      name:        'lucid64',
      updated_at:  unique_time('cc_stack_updated')
    }
  end

  def cc_user
    {
      active:           true,
      admin:            false,
      created_at:       unique_time('cc_user_created'),
      default_space_id: cc_space[:id],
      guid:             uaa_user[:id],
      id:               unique_id('cc_user'),
      updated_at:       unique_time('cc_user_updated')
    }
  end

  def uaa_approval
    {
      client_id:      uaa_client[:client_id],
      expiresat:      unique_time('uaa_appoval_expires'),
      lastmodifiedat: unique_time('uaa_appoval_last'),
      scope:          uaa_client[:scope],
      status:         'APPROVED',
      user_id:        uaa_user[:id]
    }
  end

  def uaa_client_autoapprove
    true
  end

  def uaa_client
    {
      access_token_validity:   1_209_600,
      additional_information:  "{\"autoapprove\":#{uaa_client_autoapprove}}",
      app_launch_url:          'http://app_launch_url.com',
      authorities:             'auth1',
      authorized_grant_types:  'grant1',
      autoapprove:             uaa_client_autoapprove.to_s,
      client_id:               'client1',
      identity_zone_id:        uaa_identity_zone[:id],
      lastmodified:            unique_time('uaa_client_last'),
      refresh_token_validity:  2_592_000,
      scope:                   'scope1',
      show_on_home_page:       false,
      web_server_redirect_uri: 'http://redirect_uri.com'
    }
  end

  def uaa_group
    {
      created:          unique_time('uaa_group_created'),
      description:      'TestGroup description',
      displayname:      'group1',
      id:               'group1',
      identity_zone_id: uaa_identity_zone[:id],
      lastmodified:     unique_time('uaa_group_last'),
      version:          5
    }
  end

  def uaa_group_membership
    {
      added:     unique_time('uaa_group_membership_added'),
      group_id:  uaa_group[:id],
      member_id: uaa_user[:id]
    }
  end

  def uaa_identity_provider
    {
      active:           true,
      config:           '{"key1":"value1","key2":"value2"}',
      created:          unique_time('uaa_identity_provider_created'),
      id:               'identity_provider1',
      identity_zone_id: uaa_identity_zone[:id],
      lastmodified:     unique_time('uaa_identity_provider_last'),
      name:             'identity_provider_name',
      origin_key:       'identity_provider_origin_key1',
      type:             'identity_provider_type1',
      version:          5
    }
  end

  def uaa_identity_zone
    {
      config:       '{"tokenPolicy":{"accessTokenValidity":43200,"refreshTokenValidity":2592000,"keys":{}},"samlConfig":{"requestSigned":false,"wantAssertionSigned":false,"certificate":null,"privateKey":null}}',
      created:      unique_time('uaa_identity_zone_created'),
      description:  'Identity zone description',
      id:           'identity_zone1',
      lastmodified: unique_time('uaa_identity_zone_last'),
      name:         'identity_zone_name',
      subdomain:    'identity_zone_subdomain',
      version:      5
    }
  end

  def uaa_user
    {
      active:              true,
      created:             unique_time('uaa_user_created'),
      email:               'admin',
      familyname:          'Flintstone',
      givenname:           'Fred',
      id:                  'user1',
      identity_zone_id:    uaa_identity_zone[:id],
      lastmodified:        unique_time('uaa_user_last'),
      passwd_lastmodified: unique_time('uaa_user_passwd'),
      phonenumber:         '012-345-6789',
      username:            'admin',
      verified:            true,
      version:             5
    }
  end

  # We do not retrieve password, but it is required for insert
  def uaa_user_with_password
    uaa_user.merge(password: 'password')
  end

  private

  def uaa_oauth
    {
      'token_type'   => 'bearer',
      'access_token' => 'bogus'
    }
  end

  def ccdb_inserts(insert_second_quota_definition, event_type)
    result = [
               [:buildpacks,                     cc_buildpack],
               [:feature_flags,                  cc_feature_flag],
               [:quota_definitions,              cc_quota_definition],
               [:security_groups,                cc_security_group],
               [:service_dashboard_clients,      cc_service_dashboard_client],
               [:stacks,                         cc_stack],
               [:organizations,                  cc_organization],
               [:domains,                        cc_domain],
               [:space_quota_definitions,        cc_space_quota_definition],
               [:organizations_private_domains,  cc_organization_private_domain],
               [:spaces,                         cc_space],
               [:security_groups_spaces,         cc_security_group_space],
               [:apps,                           cc_app],
               [:processes,                      cc_process],
               [:packages,                       cc_package],
               [:droplets,                       cc_droplet],
               [:routes,                         cc_route],
               [:service_brokers,                cc_service_broker_with_password],
               [:users,                          cc_user],
               [:request_counts,                 cc_request_count],
               [:route_mappings,                 cc_route_mapping],
               [:organizations_auditors,         cc_organization_auditor],
               [:organizations_billing_managers, cc_organization_billing_manager],
               [:organizations_managers,         cc_organization_manager],
               [:organizations_users,            cc_organization_user],
               [:services,                       cc_service],
               [:spaces_auditors,                cc_space_auditor],
               [:spaces_developers,              cc_space_developer],
               [:spaces_managers,                cc_space_manager],
               [:service_plans,                  cc_service_plan],
               [:service_instances,              cc_service_instance],
               [:service_plan_visibilities,      cc_service_plan_visibility],
               [:service_bindings,               cc_service_binding_with_credentials],
               [:service_instance_operations,    cc_service_instance_operation],
               [:service_keys,                   cc_service_key_with_credentials]
             ]

    result << [:quota_definitions, cc_quota_definition2] if insert_second_quota_definition
    result << [:space_quota_definitions, cc_space_quota_definition2] if insert_second_quota_definition

    result << [:events, cc_event_app] if event_type == 'app'
    result << [:events, cc_event_route] if event_type == 'route'
    result << [:events, cc_event_service] if event_type == 'service'
    result << [:events, cc_event_service_binding] if event_type == 'service_binding'
    result << [:events, cc_event_service_broker] if event_type == 'service_broker'
    result << [:events, cc_event_service_dashboard_client] if event_type == 'service_dashboard_client'
    result << [:events, cc_event_service_instance] if event_type == 'service_instance'
    result << [:events, cc_event_service_key] if event_type == 'service_key'
    result << [:events, cc_event_service_plan] if event_type == 'service_plan'
    result << [:events, cc_event_service_plan_visibility] if event_type == 'service_plan_visibility'
    result << [:events, cc_event_space] if event_type == 'space'

    result
  end

  def uaadb_inserts
    [
      [:identity_zone,        uaa_identity_zone],
      [:identity_provider,    uaa_identity_provider],
      [:groups,               uaa_group],
      [:users,                uaa_user_with_password],
      [:group_membership,     uaa_group_membership],
      [:oauth_client_details, uaa_client],
      [:authz_approvals,      uaa_approval]
    ]
  end

  def cc_app_instance_index
    0
  end

  def cc_app_not_found
    NotFound.new('code'        => 100_004,
                 'description' => "The app name could not be found: #{cc_app[:guid]}",
                 'error_code'  => 'CF-AppNotFound')
  end

  def cc_app_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}/restage", AdminUI::Utils::HTTP_POST, anything, anything, anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_app_rename}\"}", anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        sql(config.ccdb_uri, "UPDATE apps SET name = '#{cc_app_rename}' WHERE guid = '#{cc_app[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"state":"STOPPED"}', anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        sql(config.ccdb_uri, "UPDATE apps SET desired_state = 'STOPPED' WHERE guid = '#{cc_app[:guid]}'")
        sql(config.ccdb_uri, "UPDATE processes SET state = 'STOPPED' WHERE app_guid = '#{cc_app[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"state":"STARTED"}', anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        sql(config.ccdb_uri, "UPDATE apps SET desired_state = 'STARTED' WHERE guid = '#{cc_app[:guid]}'")
        sql(config.ccdb_uri, "UPDATE processes SET state = 'STARTED' WHERE app_guid = '#{cc_app[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"diego":true}', anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        sql(config.ccdb_uri, "UPDATE processes SET diego = 'true' WHERE app_guid = '#{cc_app[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"diego":false}', anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        sql(config.ccdb_uri, "UPDATE processes SET diego = 'false' WHERE app_guid = '#{cc_app[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"enable_ssh":true}', anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        sql(config.ccdb_uri, "UPDATE processes SET enable_ssh = 'true' WHERE app_guid = '#{cc_app[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"enable_ssh":false}', anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        sql(config.ccdb_uri, "UPDATE processes SET enable_ssh = 'false' WHERE app_guid = '#{cc_app[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        cc_clear_apps_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}?recursive=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        cc_clear_apps_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/apps/#{cc_app[:guid]}/instances/#{cc_app_instance_index}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_apps_deleted
        cc_app_not_found
      else
        cc_clear_apps_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_apps_deleted
    @cc_apps_deleted
  end

  def cc_buildpack_not_found
    NotFound.new('code'        => 10_000,
                 'description' => 'Unknown request',
                 'error_code'  => 'CF-NotFound')
  end

  def cc_buildpack_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/buildpacks/#{cc_buildpack[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_buildpack_rename}\"}", anything) do
      if @cc_buildpacks_deleted
        cc_buildpack_not_found
      else
        sql(config.ccdb_uri, "UPDATE buildpacks SET name = '#{cc_buildpack_rename}' WHERE guid = '#{cc_buildpack[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/buildpacks/#{cc_buildpack[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"enabled":true}', anything) do
      if @cc_buildpacks_deleted
        cc_buildpack_not_found
      else
        sql(config.ccdb_uri, "UPDATE buildpacks SET enabled = 'true' WHERE guid = '#{cc_buildpack[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/buildpacks/#{cc_buildpack[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"enabled":false}', anything) do
      if @cc_buildpacks_deleted
        cc_buildpack_not_found
      else
        sql(config.ccdb_uri, "UPDATE buildpacks SET enabled = 'false' WHERE guid = '#{cc_buildpack[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/buildpacks/#{cc_buildpack[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"locked":true}', anything) do
      if @cc_buildpacks_deleted
        cc_buildpack_not_found
      else
        sql(config.ccdb_uri, "UPDATE buildpacks SET locked = 'true' WHERE guid = '#{cc_buildpack[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/buildpacks/#{cc_buildpack[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"locked":false}', anything) do
      if @cc_buildpacks_deleted
        cc_buildpack_not_found
      else
        sql(config.ccdb_uri, "UPDATE buildpacks SET locked = 'false' WHERE guid = '#{cc_buildpack[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/buildpacks/#{cc_buildpack[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_buildpacks_deleted
        cc_buildpack_not_found
      else
        cc_clear_buildpacks_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_domain_not_found
    NotFound.new('code'        => 130_002,
                 'description' => "The domain could not be found: #{cc_domain[:guid]}",
                 'error_code'  => 'CF-DomainNotFound')
  end

  def cc_domain_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/domains/#{cc_domain[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_domains_deleted
        cc_domain_not_found
      else
        cc_clear_domains_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/domains/#{cc_domain[:guid]}?recursive=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_domains_deleted
        cc_domain_not_found
      else
        cc_clear_domains_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_feature_flag_not_found
    NotFound.new('code'        => 330_000,
                 'description' => "The feature flag could not be found: #{cc_feature_flag[:name]}",
                 'error_code'  => 'CF-FeatureFlagNotFound')
  end

  def cc_feature_flag_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/config/feature_flags/#{cc_feature_flag[:name]}", AdminUI::Utils::HTTP_PUT, anything, '{"enabled":true}', anything) do
      if @cc_feature_flags_deleted
        cc_feature_flag_not_found
      else
        sql(config.ccdb_uri, "UPDATE feature_flags SET enabled = 'true' WHERE name= '#{cc_feature_flag[:name]}'")
        OK.new({})
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/config/feature_flags/#{cc_feature_flag[:name]}", AdminUI::Utils::HTTP_PUT, anything, '{"enabled":false}', anything) do
      if @cc_feature_flags_deleted
        cc_feature_flag_not_found
      else
        sql(config.ccdb_uri, "UPDATE feature_flags SET enabled = 'false' WHERE name= '#{cc_feature_flag[:name]}'")
        OK.new({})
      end
    end
  end

  def cc_login_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/info", AdminUI::Utils::HTTP_GET) do
      OK.new(cc_info)
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{cc_info['token_endpoint']}/oauth/token", AdminUI::Utils::HTTP_POST, anything, anything) do
      OK.new(uaa_oauth)
    end
  end

  def cc_organization_not_found
    NotFound.new('code'        => 30_003,
                 'description' => "The organization could not be found: #{cc_organization[:guid]}",
                 'error_code'  => 'CF-OrganizationNotFound')
  end

  def cc_organization_taken
    BadRequest.new('code'        => 30_002,
                   'description' => "The organization name is taken: #{cc_organization2[:name]}",
                   'error_code'  => 'CF-OrganizationNameTaken')
  end

  def cc_organization_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations", AdminUI::Utils::HTTP_POST, anything, "{\"name\":\"#{cc_organization2[:name]}\"}", anything) do
      if @cc_organization_created
        cc_organization_taken
      else
        Sequel.connect(config.ccdb_uri, single_threaded: true, max_connections: 1, timeout: 1) do |connection|
          items = connection[:organizations]
          loop do
            begin
              items.insert(cc_organization2)
              break
            rescue Sequel::DatabaseError => error
              wrapped_exception = error.wrapped_exception
              raise unless wrapped_exception && wrapped_exception.instance_of?(SQLite3::BusyException)
            end
          end
        end
        @cc_organization_created = true
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_organization_rename}\"}", anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "UPDATE organizations SET name = '#{cc_organization_rename}' WHERE guid = '#{cc_organization[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"quota_definition_guid\":\"#{cc_quota_definition2[:guid]}\"}", anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "UPDATE organizations SET quota_definition_id = (SELECT id FROM quota_definitions WHERE guid = '#{cc_quota_definition2[:guid]}')")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"status":"suspended"}', anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "UPDATE organizations SET status = 'suspended' WHERE guid = '#{cc_organization[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"status":"active"}', anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "UPDATE organizations SET status = 'active' WHERE guid = '#{cc_organization[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        cc_clear_organizations_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}?recursive=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        cc_clear_organizations_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}/auditors/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "DELETE FROM organizations_auditors WHERE organization_id = '#{cc_organization[:id]}' AND user_id = '#{cc_user[:id]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}/billing_managers/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "DELETE FROM organizations_billing_managers WHERE organization_id = '#{cc_organization[:id]}' AND user_id = '#{cc_user[:id]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}/managers/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "DELETE FROM organizations_managers WHERE organization_id = '#{cc_organization[:id]}' AND user_id = '#{cc_user[:id]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/organizations/#{cc_organization[:guid]}/users/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_organizations_deleted
        cc_organization_not_found
      else
        sql(config.ccdb_uri, "DELETE FROM organizations_users WHERE organization_id = '#{cc_organization[:id]}' AND user_id = '#{cc_user[:id]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_quota_definition_not_found
    NotFound.new('code'        => 240_001,
                 'description' => "Quota Definition could not be found: #{cc_quota_definition[:guid]}",
                 'error_code'  => 'CF-QuotaDefinitionNotFound')
  end

  def cc_quota_definition_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/quota_definitions/#{cc_quota_definition[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_quota_definition_rename}\"}", anything) do
      if @cc_quota_definitions_deleted
        cc_quota_definition_not_found
      else
        sql(config.ccdb_uri, "UPDATE quota_definitions SET name = '#{cc_quota_definition_rename}' WHERE guid = '#{cc_quota_definition[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/quota_definitions/#{cc_quota_definition[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_quota_definitions_deleted
        cc_quota_definition_not_found
      else
        cc_clear_quota_definitions_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_route_not_found
    NotFound.new('code'        => 210_002,
                 'description' => "The route could not be found: #{cc_route[:guid]}",
                 'error_code'  => 'CF-RouteNotFound')
  end

  def cc_route_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/routes/#{cc_route[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_routes_deleted
        cc_route_not_found
      else
        cc_clear_routes_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/routes/#{cc_route[:guid]}?recursive=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_routes_deleted
        cc_route_not_found
      else
        cc_clear_routes_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_route_mapping_not_found
    NotFound.new('code'        => 210_007,
                 'description' => "The route mapping could not be found: #{cc_route_mapping[:guid]}",
                 'error_code'  => 'CF-RouteMappingNotFound')
  end

  def cc_route_mapping_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/route_mappings/#{cc_route_mapping[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_route_mappings_deleted
        cc_route_mapping_not_found
      else
        cc_clear_route_mappings_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_security_group_not_found
    NotFound.new('code'        => 300_002,
                 'description' => "The security group could not be found: #{cc_security_group[:guid]}",
                 'error_code'  => 'CF-SecurityGroupNotFound')
  end

  def cc_security_group_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/security_groups/#{cc_security_group[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_security_group_rename}\"}", anything) do
      if @cc_security_groups_deleted
        cc_security_group_not_found
      else
        sql(config.ccdb_uri, "UPDATE security_groups SET name = '#{cc_security_group_rename}' WHERE guid = '#{cc_security_group[:guid]}'")
        OK.new({})
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/config/running_security_groups/#{cc_security_group[:guid]}", AdminUI::Utils::HTTP_PUT, anything, anything, anything) do
      if @cc_security_groups_deleted
        cc_security_group_not_found
      else
        sql(config.ccdb_uri, "UPDATE security_groups SET running_default = 'true' WHERE guid = '#{cc_security_group[:guid]}'")
        OK.new({})
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/config/staging_security_groups/#{cc_security_group[:guid]}", AdminUI::Utils::HTTP_PUT, anything, anything, anything) do
      if @cc_security_groups_deleted
        cc_security_group_not_found
      else
        sql(config.ccdb_uri, "UPDATE security_groups SET staging_default = 'true' WHERE guid = '#{cc_security_group[:guid]}'")
        OK.new({})
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/config/running_security_groups/#{cc_security_group[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_security_groups_deleted
        cc_security_group_not_found
      else
        sql(config.ccdb_uri, "UPDATE security_groups SET running_default = 'false' WHERE guid = '#{cc_security_group[:guid]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/config/staging_security_groups/#{cc_security_group[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_security_groups_deleted
        cc_security_group_not_found
      else
        sql(config.ccdb_uri, "UPDATE security_groups SET staging_default = 'false' WHERE guid = '#{cc_security_group[:guid]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/security_groups/#{cc_security_group[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_security_groups_deleted
        cc_security_group_not_found
      else
        cc_clear_security_groups_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_security_group_space_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/security_groups/#{cc_security_group[:guid]}/spaces/#{cc_space[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_security_groups_deleted
        cc_security_group_not_found
      else
        cc_clear_security_groups_spaces_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_service_not_found
    NotFound.new('code'        => 120_003,
                 'description' => "The service could not be found: #{cc_service[:guid]}",
                 'error_code'  => 'CF-ServiceNotFound')
  end

  def cc_service_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/services/#{cc_service[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_services_deleted
        cc_service_not_found
      else
        cc_clear_services_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/services/#{cc_service[:guid]}?purge=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_services_deleted
        cc_service_not_found
      else
        cc_clear_services_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_service_binding_not_found
    NotFound.new('code'        => 90_004,
                 'description' => "The service binding could not be found: #{cc_service_binding[:guid]}",
                 'error_code'  => 'CF-ServiceBindingNotFound')
  end

  def cc_service_binding_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_bindings/#{cc_service_binding[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_bindings_deleted
        cc_service_binding_not_found
      else
        cc_clear_service_bindings_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_service_broker_not_found
    NotFound.new('code'        => 10_000,
                 'description' => 'Unknown request',
                 'error_code'  => 'CF-NotFound')
  end

  def cc_service_broker_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_brokers/#{cc_service_broker[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_service_broker_rename}\"}", anything) do
      if @cc_service_brokers_deleted
        cc_service_broker_not_found
      else
        sql(config.ccdb_uri, "UPDATE service_brokers SET name = '#{cc_service_broker_rename}' WHERE guid = '#{cc_service_broker[:guid]}'")
        OK.new({})
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_brokers/#{cc_service_broker[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_brokers_deleted
        cc_service_broker_not_found
      else
        cc_clear_service_brokers_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_service_instance_not_found
    NotFound.new('code'        => 60_004,
                 'description' => "The service instance could not be found: #{cc_service_instance[:guid]}",
                 'error_code'  => 'CF-ServiceInstanceNotFound')
  end

  def cc_service_instance_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_instances/#{cc_service_instance[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_service_instance_rename}\"}", anything) do
      if @cc_service_instances_deleted
        cc_service_instance_not_found
      else
        sql(config.ccdb_uri, "UPDATE service_instances SET name = '#{cc_service_instance_rename}' WHERE guid = '#{cc_service_instance[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_instances/#{cc_service_instance[:guid]}?accepts_incomplete=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_instances_deleted
        cc_service_instance_not_found
      else
        cc_clear_service_instances_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_instances/#{cc_service_instance[:guid]}?accepts_incomplete=true&recursive=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_instances_deleted
        cc_service_instance_not_found
      else
        cc_clear_service_instances_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_instances/#{cc_service_instance[:guid]}?accepts_incomplete=true&recursive=true&purge=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_instances_deleted
        cc_service_instance_not_found
      else
        cc_clear_service_instances_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_service_key_not_found
    NotFound.new('code'        => 360_003,
                 'description' => "The service key could not be found: #{cc_service_key[:guid]}",
                 'error_code'  => 'CF-ServiceKeyNotFound')
  end

  def cc_service_key_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_keys/#{cc_service_key[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_keys_deleted
        cc_service_key_not_found
      else
        cc_clear_service_keys_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_service_plan_not_found
    NotFound.new('code'        => 110_003,
                 'description' => "The service plan could not be found: #{cc_service_plan[:guid]}",
                 'error_code'  => 'CF-ServicePlanNotFound')
  end

  def cc_service_plan_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_plans/#{cc_service_plan[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"public":true}', anything) do
      if @cc_service_plans_deleted
        cc_service_plan_not_found
      else
        sql(config.ccdb_uri, "UPDATE service_plans SET public = 'true' WHERE guid = '#{cc_service_plan[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_plans/#{cc_service_plan[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"public":false}', anything) do
      if @cc_service_plans_deleted
        cc_service_plan_not_found
      else
        sql(config.ccdb_uri, "UPDATE service_plans SET public = 'false' WHERE guid = '#{cc_service_plan[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_plans/#{cc_service_plan[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_plans_deleted
        cc_service_plan_not_found
      else
        cc_clear_service_plans_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_service_plan_visibility_not_found
    NotFound.new('code'        => 260_003,
                 'description' => "The service plan visibility could not be found: #{cc_service_plan[:guid]}",
                 'error_code'  => 'CF-ServicePlanVisibilityNotFound')
  end

  def cc_service_plan_visibility_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/service_plan_visibilities/#{cc_service_plan_visibility[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_service_plan_visibilities_deleted
        cc_service_plan_visibility_not_found
      else
        cc_clear_service_plan_visibilities_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_space_not_found
    NotFound.new('code'        => 40_004,
                 'description' => "The app space could not be found: #{cc_space[:guid]}",
                 'error_code'  => 'CF-SpaceNotFound')
  end

  def cc_space_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_space_rename}\"}", anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        sql(config.ccdb_uri, "UPDATE spaces SET name = '#{cc_space_rename}' WHERE guid = '#{cc_space[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"allow_ssh":true}', anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        sql(config.ccdb_uri, "UPDATE spaces SET allow_ssh = 'true' WHERE guid = '#{cc_space[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}", AdminUI::Utils::HTTP_PUT, anything, '{"allow_ssh":false}', anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        sql(config.ccdb_uri, "UPDATE spaces SET allow_ssh = 'false' WHERE guid = '#{cc_space[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        cc_clear_spaces_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}?recursive=true", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        cc_clear_spaces_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}/auditors/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        sql(config.ccdb_uri, "DELETE FROM spaces_auditors WHERE space_id = '#{cc_space[:id]}' AND user_id = '#{cc_user[:id]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}/developers/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        sql(config.ccdb_uri, "DELETE FROM spaces_developers WHERE space_id = '#{cc_space[:id]}' AND user_id = '#{cc_user[:id]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/spaces/#{cc_space[:guid]}/managers/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_spaces_deleted
        cc_space_not_found
      else
        sql(config.ccdb_uri, "DELETE FROM spaces_managers WHERE space_id = '#{cc_space[:id]}' AND user_id = '#{cc_user[:id]}'")
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_space_quota_definition_not_found
    NotFound.new('code'        => 310_007,
                 'description' => "Space Quota Definition could not be found: #{cc_space_quota_definition[:guid]}",
                 'error_code'  => 'CF-SpaceQuotaDefinitionNotFound')
  end

  def cc_space_quota_definition_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/space_quota_definitions/#{cc_space_quota_definition[:guid]}", AdminUI::Utils::HTTP_PUT, anything, "{\"name\":\"#{cc_space_quota_definition_rename}\"}", anything) do
      if @cc_space_quota_definitions_deleted
        cc_space_quota_definition_not_found
      else
        sql(config.ccdb_uri, "UPDATE space_quota_definitions SET name = '#{cc_space_quota_definition_rename}' WHERE guid = '#{cc_space_quota_definition[:guid]}'")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/space_quota_definitions/#{cc_space_quota_definition2[:guid]}/spaces/#{cc_space[:guid]}", AdminUI::Utils::HTTP_PUT, anything, anything, anything) do
      if @cc_space_quota_definitions_deleted
        cc_space_quota_definition_not_found
      else
        sql(config.ccdb_uri, "UPDATE spaces SET space_quota_definition_id = (SELECT id FROM space_quota_definitions WHERE guid = '#{cc_space_quota_definition2[:guid]}')")
        Created.new
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/space_quota_definitions/#{cc_space_quota_definition[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_space_quota_definitions_deleted
        cc_space_quota_definition_not_found
      else
        cc_clear_space_quota_definitions_cache_stub(config)
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end

    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/space_quota_definitions/#{cc_space_quota_definition[:guid]}/spaces/#{cc_space[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_space_quota_definitions_deleted
        cc_space_quota_definition_not_found
      else
        sql(config.ccdb_uri, 'UPDATE spaces SET space_quota_definition_id = null')
        Net::HTTPNoContent.new(1.0, 204, 'OK')
      end
    end
  end

  def cc_user_not_found
    NotFound.new('code'        => 20_003,
                 'description' => "The user could not be found: #{cc_user[:guid]}",
                 'error_code'  => 'CF-UserNotFound')
  end

  def cc_user_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{config.cloud_controller_uri}/v2/users/#{cc_user[:guid]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @cc_users_deleted
        cc_user_not_found
      else
        cc_clear_users_cache_stub(config)
        OK.new({})
      end
    end
  end

  def uaa_client_not_found
    NotFound.new('message' => 'Not Found')
  end

  def uaa_client_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{cc_info['token_endpoint']}/oauth/clients/#{uaa_client[:client_id]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @uaa_clients_deleted
        uaa_client_not_found
      else
        uaa_clear_clients_cache_stub(config)
        OK.new({})
      end
    end
  end

  def uaa_group_not_found
    NotFound.new('message' => "Group #{uaa_group[:id]} does not exist")
  end

  def uaa_group_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{cc_info['token_endpoint']}/Groups/#{uaa_group[:id]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @uaa_groups_deleted
        uaa_group_not_found
      else
        uaa_clear_groups_cache_stub(config)
        OK.new({})
      end
    end
  end

  def uaa_user_not_found
    NotFound.new('message' => "User #{uaa_user[:id]} does not exist")
  end

  def uaa_user_stubs(config)
    allow(AdminUI::Utils).to receive(:http_request).with(anything, "#{cc_info['token_endpoint']}/Users/#{uaa_user[:id]}", AdminUI::Utils::HTTP_DELETE, anything, anything, anything) do
      if @uaa_users_deleted
        uaa_user_not_found
      else
        uaa_clear_users_cache_stub(config)
        OK.new({})
      end
    end
  end

  def populate_db(db_uri, path, ordered_inserts)
    Sequel.connect(db_uri, single_threaded: true, max_connections: 1, timeout: 1) do |connection|
      Sequel::Migrator.apply(connection, path)

      ordered_inserts.each do |entry|
        items = connection[entry[0]]
        loop do
          begin
            items.insert(entry[1])
            break
          rescue Sequel::DatabaseError => error
            wrapped_exception = error.wrapped_exception
            raise unless wrapped_exception && wrapped_exception.instance_of?(SQLite3::BusyException)
          end
        end
      end
    end
  end

  def sql(uri, sql)
    Sequel.connect(uri, single_threaded: true, max_connections: 1, timeout: 1) do |connection|
      loop do
        begin
          connection.run(sql)
          break
        rescue Sequel::DatabaseError => error
          wrapped_exception = error.wrapped_exception
          raise unless wrapped_exception && wrapped_exception.instance_of?(SQLite3::BusyException)
        end
      end
    end
  end

  def unique_id(key)
    result = @unique_ids[key]
    return result unless result.nil?
    @last_unique_id += 1
    @unique_ids[key] = @last_unique_id
    @last_unique_id
  end

  def unique_time(key)
    result = @unique_times[key]
    return result unless result.nil?
    @last_unique_time += 1
    @unique_times[key] = @last_unique_time
    @last_unique_time
  end
end
