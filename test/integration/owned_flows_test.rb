require "test_helper"

module EasyFlow
  class OwnedFlowsTest < ActionDispatch::IntegrationTest
    setup do
      @ours = Customer.create!(name: "Ours")
      @theirs = Customer.create!(name: "Theirs")
    end

    test "a host that names an owner lists only that owner's flows in its builder" do
      Definition.create!(host: "owned", slug: "ours", title: "Ours", owner: @ours)
      Definition.create!(host: "owned", slug: "theirs", title: "Theirs", owner: @theirs)

      get "/owned/manage/flows", headers: as(@ours)

      assert_select "a", text: "Theirs", count: 0
    end

    test "a flow created in a host that names an owner belongs to that owner" do
      post "/owned/manage/flows", params: { flow: { slug: "fresh", title: "Fresh" } }, headers: as(@ours)

      assert_equal @ours, Definition.find_by!(host: "owned", slug: "fresh").owner
    end

    test "the builder of a host that names an owner cannot open another owner's flow" do
      theirs = Definition.create!(host: "owned", slug: "theirs", title: "Theirs", owner: @theirs)

      get "/owned/manage/flows/#{theirs.id}/edit", headers: as(@ours)

      assert_response :not_found
    end

    test "a visitor cannot take another owner's flow" do
      theirs = Definition.create!(host: "owned", slug: "theirs", title: "Theirs", owner: @theirs)
      theirs.record_definition(flowing("slug" => "theirs", "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "question", "text" => "A?", "options" => [ "y" ] } ]))
      theirs.publish

      get "/owned/theirs/step", headers: as(@ours)

      assert_response :not_found
    end

    test "a host that names no owner still shares every flow" do
      Definition.create!(host: "dummy", slug: "shared", title: "Shared", owner: @theirs)

      get "/easy_flow/manage/flows"

      assert_select "a", text: "Shared"
    end

    private

    def as(customer)
      { "X-Customer" => customer.id.to_s }
    end
  end
end
