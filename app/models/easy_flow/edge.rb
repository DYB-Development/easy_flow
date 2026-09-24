module EasyFlow
  Edge = Data.define(:from, :to, :on) do
    def initialize(from:, to:, on: nil)
      super
    end
  end
end
