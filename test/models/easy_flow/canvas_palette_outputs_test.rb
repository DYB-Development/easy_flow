require "test_helper"

module EasyFlow
  class CanvasPaletteOutputsTest < ActiveSupport::TestCase
    test "lists the name of each output a step type declares in its palette entry" do
      entry = palette_entry do
        output :score, type: :integer
        output :verdict, values: %w[pass fail]
      end

      assert_equal [ "score", "verdict" ], entry["outputs"].map { |output| output["name"] }
    end

    private

    def palette_entry(&declare)
      registry = Registry.new.tap { |built| built.register(StepType.define(:rate) { step_name "Rate"; instance_eval(&declare) }) }
      document = Document.new({ "entry" => "a", "nodes" => [ { "id" => "a", "type" => "rate" } ], "edges" => [] })
      Canvas.new(document, registry: registry).to_h["palette"].first
    end
  end
end
