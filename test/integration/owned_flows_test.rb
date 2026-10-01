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

    private

    def as(customer)
      { "X-Customer" => customer.id.to_s }
    end
  end
end
