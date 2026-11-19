require "test_helper"

module EasyFlow
  class ForEachTest < ActiveSupport::TestCase
    def registry
      @registry ||= Registry.new.tap do |built|
        built.register(Start.step_type)
        built.register(ForEach.step_type)
        built.register(StepType.define(:ask) { awaits_input })
      end
    end

    def drawing
      { "nodes" => [ { "id" => "start", "type" => "start" }, { "id" => "outline", "type" => "ask" },
                     { "id" => "variants", "type" => "for_each", "list" => "outline.variants", "holds" => [ "write" ] },
                     { "id" => "write", "type" => "ask" }, { "id" => "after", "type" => "ask" } ],
        "edges" => [ { "from" => "start", "to" => "outline" }, { "from" => "outline", "to" => "variants" },
                     { "from" => "variants", "to" => "write" }, { "from" => "write", "to" => "after" } ] }
    end

    def digest
      Digest.new(Document.new(drawing, registry: registry), registry: registry)
    end

    def outlined
      { "outline" => { "variants" => %w[short long plain] } }
    end

    test "a for_each step holds steps and offers a list, a concurrency and an item-failure rule" do
      step_type = ForEach.step_type

      assert_equal [ true, { list: :string, concurrency: :integer, on_item_failure: :select } ], [ step_type.holds_steps?, step_type.settings.fields ]
    end

    test "walks its held steps once for each item of the list, one item after another in list order" do
      reached = [ outlined, outlined.merge("write@item1" => "a"), outlined.merge("write@item1" => "a", "write@item2" => "b") ]

      assert_equal %w[write@item1 write@item2 write@item3], reached.map { |state| digest.next_step(state).id }
    end
  end
end
