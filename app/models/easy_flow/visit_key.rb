module EasyFlow
  VisitKey = Data.define(:step, :item, :visit) do
    def self.parse(key)
      step, *rest = key.to_s.split("@")
      item = rest.shift.delete_prefix("item").to_i if rest.first.to_s.start_with?("item")
      new(step: step, item: item, visit: (rest.first || 1).to_i)
    end

    def to_s
      [ step, ("item#{item}" if item), (visit if visit > 1) ].compact.join("@")
    end
  end
end
