module EasyFlow
  class StepType
    ShownValues = Data.define(:heading, :columns, :values) do
      def drawn(node)
        { "heading" => heading, "columns" => columns,
          "values" => values.call(node).to_h.map { |label, value| { "label" => label.to_s, "value" => value.to_s } } }
      end
    end
  end
end
