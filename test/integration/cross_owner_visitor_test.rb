require "test_helper"

module EasyFlow
  class CrossOwnerVisitorTest < ActionDispatch::IntegrationTest
    setup do
      @ours = Customer.create!(name: "Ours")
      @theirs = Customer.create!(name: "Theirs")
      EasyFlow.host_named(:owned).finds_flows_across_owners = true
    end

    teardown { EasyFlow.host_named(:owned).finds_flows_across_owners = false }

    def theirs
      @theirs_flow ||= Definition.create!(host: "owned", slug: "theirs", title: "Theirs", owner: @theirs, persists: "each_step").tap do |flow|
        flow.record_definition(flowing("slug" => "theirs", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "text" => "A?", "options" => [ "y" ] } ]))
        flow.publish
      end
    end

    test "a visitor opens another owner's flow from its public code when the host finds flows across owners" do
      get "/owned/#{theirs.public_code}", headers: as(@ours)

      assert_response :success
    end

    test "a visitor continues a run of another owner's flow from the run's public code when the host finds flows across owners" do
      run = Run.start(theirs)

      get "/owned/runs/#{run.public_code}", headers: as(@ours)

      assert_select "form[action=?]", "/owned/runs/#{run.public_code}"
    end

    private

    def as(customer)
      { "X-Customer" => customer.id.to_s }
    end
  end
end
