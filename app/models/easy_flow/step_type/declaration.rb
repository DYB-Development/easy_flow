module EasyFlow
  class StepType
    class Declaration
      def initialize(id)
        @id = id
        @step_name = id.to_s
        @fields = {}
        @labels = {}
        @record_fields = {}
        @record_labels = {}
        @choices = {}
        @limits = {}
        @checks = {}
        @drawn_from = {}
        @outputs_of = {}
        @declared_outputs = []
        @required = []
        @awaits_input = false
        @ends_here = false
        @begins_here = false
      end

      def output(name, type: :string, label: nil, values: nil, from: nil)
        @declared_outputs += [ Output.new(name: name, type: type, label: label, values: values, from: from) ]
      end

      def displays_by(&display)
        @display = display
      end

      def drawn_by(template)
        @drawn_by = template
      end

      def process(&behaviour)
        @behaviour = behaviour
      end

      def route(&routing)
        @routing = routing
      end

      def step_name(value)
        @step_name = value
      end

      def awaits_input
        @awaits_input = true
      end

      def ends_here
        @ends_here = true
      end

      def begins_here
        @begins_here = true
      end

      def names_by(field = nil, &naming)
        @naming_field = field
        @naming = naming
      end

      def setting(name, type: nil, from: nil, outputs_of: nil, label: nil, options: nil, limit: nil, check: nil, required: false, &entries)
        type ||= :from_step if from
        type ||= :from_step if outputs_of
        raise UnknownFieldType, "#{type} is not one of #{FIELD_TYPES.join(', ')}" unless FIELD_TYPES.include?(type)

        @drawn_from[name] = from if from
        @outputs_of[name] = outputs_of if outputs_of
        @required += [ name ] if required

        declare_entries(name, entries) if type == :list
        declare_choices(name, type, options)
        @limits[name] = limit if limit
        @checks[name] = check if check
        @labels[name] = label.presence || name.to_s.humanize
        @fields[name] = type
      end

      protected

      attr_reader :fields, :labels

      private

      def declare_choices(name, type, options)
        return @choices[name] = options if options.present?
        raise UnknownFieldType, "a #{type} must offer options" if %i[select multi_select].include?(type)
      end

      def declare_entries(name, entries)
        raise UnknownFieldType, "a list must say what an entry holds" if entries.nil?

        declared = Declaration.new(:entry).tap { |entry| entry.instance_eval(&entries) }
        @record_fields[name] = declared.fields
        @record_labels[name] = declared.labels
      end

      public

      def to_step_type
        StepType.new(id: @id, step_name: @step_name, settings: settings, awaits_input: @awaits_input,
          ends_here: @ends_here, begins_here: @begins_here, behaviour: @behaviour, routing: @routing,
          display: @display, drawn_by: @drawn_by, naming_field: @naming_field, naming: @naming,
          outputs: @declared_outputs)
      end

      def settings
        Settings.new(fields: @fields, labels: @labels, record_fields: @record_fields,
          record_labels: @record_labels, choices: @choices, limits: @limits, checks: @checks,
          required: @required, drawn_from: @drawn_from, outputs_of: @outputs_of)
      end
    end
  end
end
