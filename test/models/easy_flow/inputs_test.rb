require "test_helper"

module EasyFlow
  class InputsTest < ActiveSupport::TestCase
    class HostStep
      include Step
      include Inputs
    end

    def taking(*inputs)
      Node.new(id: "lookup", type: "read_data", config: { "inputs" => inputs })
    end

    test "reads an input with a fixed value as that value" do
      assert_equal({ "sku" => "A1" }, Inputs.values_of(taking({ "name" => "sku", "value" => "A1" }), {}))
    end

    test "reads an input from an earlier step as that step's output" do
      input = { "name" => "sku", "step" => "pick", "output" => "code" }

      assert_equal({ "sku" => "A1" }, Inputs.values_of(taking(input), { "pick" => { "code" => "A1" } }))
    end

    test "reads an input from a step reached more than once as its latest output" do
      input = { "name" => "sku", "step" => "pick", "output" => "code" }
      state = { "pick" => { "code" => "A1" }, "pick@2" => { "code" => "B2" }, "pick@10" => { "code" => "C3" } }

      assert_equal({ "sku" => "C3" }, Inputs.values_of(taking(input), state))
    end

    test "reads an input marked as the run's owner as that owner's id" do
      input = { "name" => "item", "from_run_owner" => true }

      assert_equal({ "item" => 42 }, Inputs.values_of(taking(input), {}, run: Run.new(owner_id: 42)))
    end

    test "gives no value for an input marked as the run's owner when there is no run" do
      assert_equal({ "item" => nil }, Inputs.values_of(taking({ "name" => "item", "from_run_owner" => true }), {}))
    end

    test "gives a step type that includes it a list of named inputs" do
      assert_equal %i[name value step output], HostStep.step_type.settings.record_fields[:inputs].keys
    end
  end
end
