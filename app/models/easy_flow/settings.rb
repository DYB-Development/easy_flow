module EasyFlow
  class Settings
    class OptionsUnavailable < StandardError
      attr_reader :setting

      def initialize(setting, cause)
        @setting = setting
        super("#{setting} options could not be worked out: #{cause.class}: #{cause.message}")
      end
    end

    attr_reader :fields, :labels, :explanations, :record_fields, :record_labels, :record_explanations, :record_choices, :record_outputs_of, :record_required, :drawn_from, :outputs_of

    def initialize(fields: {}, labels: {}, explanations: {}, record_fields: {}, record_labels: {}, record_explanations: {}, record_choices: {}, record_outputs_of: {}, record_required: {}, choices: {},
      limits: {}, checks: {}, required: [], optional: [], drawn_from: {}, outputs_of: {}, kept: {})
      @fields = fields
      @labels = labels
      @explanations = explanations
      @record_fields = record_fields
      @record_labels = record_labels
      @record_explanations = record_explanations
      @record_choices = record_choices
      @record_outputs_of = record_outputs_of
      @record_required = record_required
      @choices = choices
      @limits = limits
      @checks = checks
      @required = required
      @optional = optional
      @drawn_from = drawn_from
      @outputs_of = outputs_of
      @kept = kept
    end

    def choices
      @choices.transform_values { |offered| depends_on_settings?(offered) ? [] : worked_out(offered) }
    end

    def choices_for(config)
      choices.merge(worked_out_choices(config))
    end

    def worked_out_choices(config)
      @choices.select { |_name, offered| depends_on_settings?(offered) }.to_h do |name, offered|
        [ name, offered.call(config.to_h) ]
      rescue StandardError => error
        raise OptionsUnavailable.new(labels[name], error)
      end
    end

    def strays(config)
      worked_out_choices(config).filter_map do |name, offered|
        chosen = config.to_h[name.to_s]
        name.to_s if chosen.present? && values_of(offered).exclude?(chosen)
      end
    end

    def cleared(config)
      config.to_h.merge(strays(config).index_with(nil))
    end

    def kept_values(config)
      @kept.to_h { |name, kept| [ name.to_s, kept[:finder].call(config.to_h)&.public_send(kept[:attribute]) ] }
    end

    def unkept(config)
      config.to_h.except(*@kept.keys.map(&:to_s))
    end

    def keep(config)
      refused = []
      ActiveRecord::Base.transaction(requires_new: true) do
        refused = @kept.filter_map do |name, kept|
          record = kept[:finder].call(config.to_h)
          next if record.nil? || record.update(kept[:attribute] => config.to_h[name.to_s])

          "#{labels[name]} #{record.errors.messages_for(kept[:attribute]).to_sentence}"
        end
        raise ActiveRecord::Rollback if refused.any?
      end
      refused
    end

    def naming_steps
      fields.select { |_name, type| type == :previous_step }.keys
    end

    def required
      fields.keys.select { |name| @required.include?(name) || (naming_steps.include?(name) && !@optional.include?(name)) }
    end

    def requirements_for(config)
      naming_steps.map { |name| config.to_h[name.to_s] }.compact_blank
    end

    def coerce(config)
      config.to_h.to_h { |name, value| [ name, cast(fields[name.to_sym], value, record_fields[name.to_sym]) ] }
    end

    def objections(config)
      offered = choices_for(config)
      config.to_h.flat_map { |name, value| objections_to(name.to_sym, value, offered) }.compact
    end

    private

    def worked_out(offered)
      offered.respond_to?(:call) ? offered.call : offered
    end

    def depends_on_settings?(offered)
      offered.respond_to?(:arity) && offered.arity == 1
    end

    def objections_to(name, value, offered)
      [ unoffered(name, value, offered[name]), over_limit(name, value), refused(name, value) ]
    end

    def unoffered(name, value, offered)
      return unless offered

      stray = Array(value).find { |chosen| values_of(offered).exclude?(chosen) }
      "#{labels[name]} does not offer #{stray}" if stray
    end

    def values_of(offered)
      offered.map { |choice| choice.is_a?(Hash) ? choice.stringify_keys["value"] : choice }
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
