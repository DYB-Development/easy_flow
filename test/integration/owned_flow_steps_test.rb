require "test_helper"

module EasyFlow
  class OwnedFlowStepsTest < ActionDispatch::IntegrationTest
    setup do
      @ours = Customer.create!(name: "Ours")
      @theirs = Customer.create!(name: "Theirs")
    end

    test "saving a Flow step that names another owner's flow is refused" do
      parent = owned_flow("parent", @ours, [ { "id" => "inner", "type" => "flow_step" } ])

      patch "/owned/manage/flows/#{parent.public_code}/canvas/steps/inner", params: { config: { flow: inner_flow(@theirs).id.to_s, version: 1 } }, headers: as(@ours)

      assert_response :unprocessable_entity
    end

    test "publishing a flow whose Flow step names another owner's flow is refused" do
      parent = owned_flow("parent", @ours, [ { "id" => "inner", "type" => "flow_step", "flow" => inner_flow(@theirs).id.to_s, "version" => 1 } ])

      post "/owned/manage/flows/#{parent.public_code}/canvas/publish", headers: as(@ours)

      assert_response :unprocessable_entity
    end

    test "a running Flow step that names another owner's flow is refused instead of playing it" do
      parent = owned_flow("parent", @ours, [ { "id" => "inner", "type" => "flow_step", "flow" => inner_flow(@theirs).id.to_s, "version" => 1 } ])
      parent.publish

      assert_raises(InnerFlowError) { Run.start(parent).advance }
    end

    test "saving a Flow step that names a flow of the same owner is accepted" do
      parent = owned_flow("parent", @ours, [ { "id" => "inner", "type" => "flow_step" } ])

      patch "/owned/manage/flows/#{parent.public_code}/canvas/steps/inner", params: { config: { flow: inner_flow(@ours).id.to_s, version: 1 } }, headers: as(@ours)

      assert_response :no_content
    end

    private

    def owned_flow(slug, owner, nodes, host: "owned")
      Definition.create!(host: host, slug: slug, title: slug.titleize, owner: owner).tap do |flow|
        flow.record_definition(flowing("slug" => slug, "entry" => nodes.first["id"], "nodes" => nodes + [ { "id" => "done", "type" => "terminal" } ],
          "edges" => [ { "from" => nodes.first["id"], "to" => "done", "on" => "finished" } ]))
      end
    end

    def inner_flow(owner, host: "owned")
      Definition.create!(host: host, slug: "inner-#{owner.id}", title: "Inner", owner: owner).tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: 1, definition: flowing("slug" => "inner", "entry" => "done",
          "nodes" => [ { "id" => "done", "type" => "terminal", "output" => "finished" } ])))
      end
    end

    def as(customer)
      { "X-Customer" => customer.id.to_s }
    end
  end
end
