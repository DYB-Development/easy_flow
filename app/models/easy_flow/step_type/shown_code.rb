module EasyFlow
  class StepType
    ShownCode = Data.define(:heading, :code) do
      def drawn(node)
        { "heading" => heading, "code" => code.call(node).to_h.map { |summary, text| { "summary" => summary.to_s, "code" => text.to_s } } }
      end
    end
  end
end
