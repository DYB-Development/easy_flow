require "test_helper"

module EasyFlow
  class QuestionPicturesTest < ActionDispatch::IntegrationTest
    class Store
      def url_of(reference)
        "/pictures/#{reference}"
      end
    end

    setup do
      @stored_with, EasyFlow.picture_store = EasyFlow.picture_store, Store.new
    end

    teardown do
      EasyFlow.picture_store = @stored_with
    end

    def flow_with(step)
      Definition.create!(host: "dummy", slug: "pictured-#{step['type']}").tap do |flow|
        flow.record_definition(flowing("slug" => "pictured-#{step['type']}", "entry" => step["id"], "nodes" => [ step ]))
        flow.publish
      end
    end

    def question
      { "id" => "france", "type" => "question", "question" => "Which country is this?", "picture" => "picture-1",
        "answers" => [ { "value" => "france" } ] }
    end

    test "a player sees a question step's picture above the question" do
      get easy_flow.run_path(Run.start(flow_with(question)))

      assert_select "fieldset img[src='/pictures/picture-1'] + legend", text: "Which country is this?"
    end
  end
end
