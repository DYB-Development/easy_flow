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

    test "lists the label of each output a step type declares in its palette entry" do
      entry = palette_entry do
        output :score, label: "Score out of ten", type: :integer
        output :verdict, values: %w[pass fail]
      end

      assert_equal [ "Score out of ten", "Verdict" ], entry["outputs"].map { |output| output["label"] }
    end

    test "lists the type of each output a step type declares in its palette entry" do
      entry = palette_entry do
        output :score, type: :integer
        output :verdict, values: %w[pass fail]
      end

      assert_equal [ "integer", "string" ], entry["outputs"].map { |output| output["type"] }
    end

    test "lists the fixed values of an output under it in the palette entry" do
      entry = palette_entry { output :level, values: %w[high medium low] }

      assert_equal %w[high medium low], entry["outputs"].first["values"]
    end

    test "shows an output whose values depend on a drawn step's settings with no values" do
      entry = palette_entry { output :answer, values: ->(node) { Array(node.config["options"]) } }

      assert_nil entry["outputs"].first["values"]
    end

    test "names the list setting a step type reports one output for each name in" do
      entry = palette_entry do
        setting(:values, type: :list) { setting :name, type: :string }
        outputs_named_by :values
      end

      assert_equal "values", entry["outputs_named_by"]
    end

    private

    def palette_entry(&declare)
      registry = Registry.new.tap { |built| built.register(StepType.define(:rate) { step_name "Rate"; instance_eval(&declare) }) }
      document = Document.new({ "entry" => "a", "nodes" => [ { "id" => "a", "type" => "rate" } ], "edges" => [] })
      Canvas.new(document, registry: registry).to_h["palette"].first
    end
  end
end
