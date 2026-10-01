module EasyFlow
  Choice = Data.define(:value, :label, :hint, :info) do
    def initialize(value:, label: nil, hint: nil, info: nil)
      super(value: value, label: label.presence || value, hint: hint, info: info)
    end
  end
end
