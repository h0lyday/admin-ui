# encoding: utf-8

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf'


##
# Imports
#
require 'uuid.pb'

module Events
  ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

  ##
  # Message Classes
  #
  class ValueMetric < ::Protobuf::Message; end
  class CounterEvent < ::Protobuf::Message; end
  class ContainerMetric < ::Protobuf::Message; end


  ##
  # File Options
  #
  set_option :java_package, "org.cloudfoundry.dropsonde.events"
  set_option :java_outer_classname, "MetricFactory"


  ##
  # Message Fields
  #
  class ValueMetric
    required :string, :name, 1
    required :double, :value, 2
    required :string, :unit, 3
  end

  class CounterEvent
    required :string, :name, 1
    required :uint64, :delta, 2
    optional :uint64, :total, 3
  end

  class ContainerMetric
    required :string, :applicationId, 1
    required :int32, :instanceIndex, 2
    required :double, :cpuPercentage, 3
    required :uint64, :memoryBytes, 4
    required :uint64, :diskBytes, 5
    optional :uint64, :memoryBytesQuota, 6
    optional :uint64, :diskBytesQuota, 7
  end

end

