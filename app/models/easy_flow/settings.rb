module EasyFlow
  class Settings
    attr_reader :fields, :labels, :record_fields, :record_labels, :choices, :drawn_from, :outputs_of

    def initialize(fields: {}, labels: {}, record_fields: {}, record_labels: {}, choices: {},
      limits: {}, checks: {}, required: [], drawn_from: {}, outputs_of: {})
      @fields = fields
      @labels = labels
      @record_fields = record_fields
      @record_labels = record_labels
      @choices = choices
      @limits = limits
      @checks = checks
      @required = required
      @drawn_from = drawn_from
      @outputs_of = outputs_of
    end

    def naming_steps
      fields.select { |_name, type| type == :previous_step }.keys
    end

    def required
      fields.keys.select { |name| @required.include?(name) || naming_steps.include?(name) }
    end

    def requirements_for(config)
      naming_steps.map { |name| config.to_h[name.to_s] }.compact_blank
    end

    def coerce(config)
      config.to_h.to_h { |name, value| [ name, cast(fields[name.to_sym], value, record_fields[name.to_sym]) ] }
    end

    def objections(config)
      config.to_h.flat_map { |name, value| objections_to(name.to_sym, value) }.compact
    end

    private

    def objections_to(name, value)
      [ unoffered(name, value), over_limit(name, value), refused(name, value) ]
    end

    def unoffered(name, value)
      offered = choices[name]
      return unless offered

      stray = Array(value).find { |chosen| offered.exclude?(chosen) }
      "#{labels[name]} does not offer #{stray}" if stray
    end

    def over_limit(name, value)
      allowed = @limits[name]
      return unless allowed && Array(value).size > allowed

      "#{labels[name]} takes at most #{allowed}"
    end

    def refused(name, value)
      @checks[name]&.call(value)
    end

    def cast(type, value, holds = nil)
      case type
      when :integer then Integer(value, exception: false)
      when :float then Float(value, exception: false)
      when :boolean then ActiveModel::Type::Boolean.new.cast(value).present?
      when :list then Array(value).map { |entry| cast_entry(entry, holds.to_h) }
      else value
      end
    end

    def cast_entry(entry, holds)
      entry.to_h.to_h { |name, value| [ name, cast(holds[name.to_sym], value) ] }
    end
  end
end
