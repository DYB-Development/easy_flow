module EasyFlow
  Output = Data.define(:name, :label, :type, :values, :from) do
    def initialize(name:, label: nil, type: :string, values: nil, from: nil)
      raise UnknownOutputType, "#{type} is not one of #{OUTPUT_TYPES.join(', ')}" unless OUTPUT_TYPES.include?(type)

      super(name: name, label: label.presence || name.to_s.humanize, type: type, values: values, from: from)
    end

    def values_for(node)
      Array(values.respond_to?(:call) ? values.call(node) : values).map { |value| taken(value) }
    end

    private

    def taken(value)
      return value if value.is_a?(Hash)

      { "value" => value, "label" => value.to_s }
    end
  end
end
