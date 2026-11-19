module EasyFlow
  VisitKey = Data.define(:step, :item, :visit, :pass) do
    def self.parse(key)
      step, *rest = key.to_s.split("@")
      item = rest.shift.delete_prefix("item").to_i if rest.first.to_s.start_with?("item")
      pass = rest.shift.delete_prefix("pass").to_i if rest.first.to_s.start_with?("pass")
      new(step: step, item: item, visit: (rest.first || 1).to_i, pass: pass || 1)
    end

    def initialize(step:, item: nil, visit: 1, pass: 1)
      super
    end

    def to_s
      [ step, ("item#{item}" if item), ("pass#{pass}" if pass > 1), (visit if visit > 1) ].compact.join("@")
    end
  end
end
