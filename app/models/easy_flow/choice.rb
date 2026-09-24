module EasyFlow
  Choice = Data.define(:value, :label, :hint) do
    def initialize(value:, label: nil, hint: nil)
      super(value: value, label: label.presence || value, hint: hint)
    end
  end
end
