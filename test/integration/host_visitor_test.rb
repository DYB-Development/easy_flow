require "test_helper"

module EasyFlow
  class HostVisitorTest < ActionDispatch::IntegrationTest
    def published
      @published ||= Definition.create!(host: "dummy", slug: "fee-check").tap do |flow|
        flow.record_definition(flowing(
          "slug" => "fee-check", "entry" => "annual_fee",
          "nodes" => [ { "id" => "annual_fee", "type" => "question", "text" => "Does the card have an annual fee?",
                         "options" => [ { "value" => "yes", "label" => "Yes" } ] } ],
          "edges" => []
        ))
        flow.publish
      end
    end

    def console_published
      @console_published ||= Definition.create!(host: "console", slug: "console-fee").tap do |flow|
        flow.record_definition(published.definition.merge("slug" => "console-fee"))
        flow.publish
      end
    end

    test "a visitor on one host's path does not reach another host's flow" do
      get console_flows.flow_path(published.slug)

      assert_response :not_found
    end

    test "a visitor on one host's path does not open another host's run" do
      run = Run.start(published)

      get console_flows.run_path(run)

      assert_response :not_found
    end

    test "a visitor who starts a second host's flow stays on that host's path" do
      post console_flows.flow_runs_path(console_published.slug)

      assert_redirected_to "/console/runs/#{Run.sole.id}"
    end

    test "a visitor sees a host's flow in the layout that host names" do
      get console_flows.flow_path(console_published.slug)

      assert_select "title", "EasyFlow"
    end

    test "a host that names no visitor check lets no visitor into its flows" do
      EasyFlow.host_named(:console).visitor_authorization_method = nil

      get console_flows.flow_path(console_published.slug)

      assert_response :not_found
    ensure
      EasyFlow.host_named(:console).visitor_authorization_method = :easy_flow_visitor_permitted?
    end
  end
end
