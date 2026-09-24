require "test_helper"

module EasyFlow
  module Steps
    class QuestionTest < ActiveSupport::TestCase
      test "displays itself as what it asks" do
        node = Node.new(id: "budget", type: "question", config: { "question" => "Budget?" })

        assert_equal "Budget?", Question.step_type.display_of(node).text
      end

      test "declares a setting for the question it asks" do
        assert_equal :string, Question.step_type.settings.fields[:question]
      end

      test "declares a setting for the answers it offers" do
        assert_equal :list, Question.step_type.settings.fields[:answers]
      end

      test "an answer carries a weight a host can score it by" do
        assert_equal :integer, Question.step_type.settings.record_fields[:answers][:weight]
      end

      test "declares a category a host can group it by" do
        assert_equal :string, Question.step_type.settings.fields[:category]
      end

      test "offers its answers as the values of its answer output" do
        node = Node.new(id: "q", type: "question",
          config: { "answers" => [ { "value" => "high", "label" => "Over $1k" } ] })

        assert_equal [ { "value" => "high", "label" => "Over $1k" } ], Question.step_type.values_of(:answer, node)
      end

      test "declares the answer it captures as an output" do
        assert_equal [ :answer ], Question.step_type.outputs.map(&:name)
      end

      test "registers through the public step-type API" do
        registry = Registry.new

        Question.register(registry)

        assert_equal :question, registry.fetch("question").id
      end

      test "resolves for a document node naming it as the type" do
        registry = Registry.new
        Question.register(registry)
        node = Document.new({ "nodes" => [ { "id" => "q", "type" => "question" } ] }).node("q")

        assert_equal "Question", registry.fetch(node.type).step_name
      end

      test "awaits external input" do
        assert_predicate Question.step_type, :awaits_input?
      end

      test "cannot run without the answers it offers" do
        assert_equal [ :answers ], Question.step_type.settings.required
      end
    end
  end
end
