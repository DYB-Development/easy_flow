require "json"
require "easy_flow/version"
require "easy_flow/host"
require "easy_flow/unset_host"
require "easy_flow/engine"

module EasyFlow
  FIELD_TYPES = %i[string integer float boolean select multi_select previous_step from_step list].freeze

  OUTPUT_TYPES = %i[string integer float boolean].freeze
  OPTIONAL_CHECKS = %i[unrouted_value unfollowed_path dead_end].freeze

  class UnknownFieldType < ArgumentError; end
  class UnknownOutputType < ArgumentError; end
  class UnknownStepType < KeyError; end
  class UnknownCheck < ArgumentError; end
  class InvalidEdit < StandardError; end
  class NotPublished < StandardError; end
  class NotPermitted < StandardError; end
  class OutOfService < StandardError; end
  class Withdrawn < StandardError; end

  DRAWING = "easy_flow/steps/choosing".freeze

  class << self
    attr_writer :layout, :base_controller
    attr_accessor :visitor_authorization_method, :refusal_method

    def layout
      @layout || "easy_flow/application"
    end

    def base_controller
      @base_controller || "ActionController::Base"
    end

    def host(name)
      raise ArgumentError, "a host needs a name" if name.blank?

      hosts[name.to_s] = Host.new(name).tap { |host| yield host if block_given? }
    end

    def hosts
      @hosts ||= {}
    end

    def host_named(name)
      hosts.fetch(name.to_s) { UnsetHost.new }
    end

    def draws_with(template)
      @drawing = template
    end

    def drawing
      @drawing.presence || DRAWING
    end

    def step(id, &declaration)
      registry.register(StepType.define(id, &declaration))
    end

    def registry
      @registry ||= Registry.new
    end

    def check(name)
      raise UnknownCheck, "#{name} is not one of #{OPTIONAL_CHECKS.join(', ')}" unless OPTIONAL_CHECKS.include?(name)

      checks << name unless checks.include?(name)
    end

    def checks
      @checks ||= []
    end
  end
end
