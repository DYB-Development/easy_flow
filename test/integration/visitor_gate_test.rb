require "test_helper"

module EasyFlow
  class VisitorGateTest < ActionDispatch::IntegrationTest
    def published
      @published ||= Definition.create!(host: "dummy", slug: "gated").tap do |flow|
        flow.record_definition(
          "slug" => "gated", "entry" => "ask",
          "nodes" => [ { "id" => "ask", "type" => "question", "text" => "Ready?",
                         "options" => [ { "value" => "yes", "weight" => 1 } ] } ],
          "edges" => []
        )
        flow.publish
      end
    end

    def without_host_configuration
      permission = EasyFlow.host_named(:dummy).visitor_authorization_method
      EasyFlow.host_named(:dummy).visitor_authorization_method = nil
      yield
    ensure
      EasyFlow.host_named(:dummy).visitor_authorization_method = permission
    end

    test "a visitor cannot reach a flow the host has not authorized" do
      without_host_configuration do
        get easy_flow.flow_path(published.slug)

        assert_response :not_found
      end
    end

    test "a visitor can reach a flow the host authorizes" do
      get easy_flow.flow_path(published.slug)

      assert_response :success
    end

    test "a visitor cannot reach a flow with nothing published even when the host authorizes it" do
      unpublished = Definition.create!(host: "dummy", slug: "unpublished")

      get easy_flow.flow_path(unpublished.slug)

      assert_response :not_found
    end

    test "a visitor cannot step through a flow the host has not authorized" do
      without_host_configuration do
        get easy_flow.flow_step_path(published.slug)

        assert_response :not_found
      end
    end

    test "a visitor cannot start a saved session on a flow the host has not authorized" do
      without_host_configuration do
        post easy_flow.flow_runs_path(published.slug)

        assert_response :not_found
      end
    end

    test "a visitor cannot resume a saved session on a flow the host has not authorized" do
      run = Run.start(published)

      without_host_configuration do
        get easy_flow.run_path(run)

        assert_response :not_found
      end
    end

    test "a visitor cannot answer into a saved session on a flow the host has not authorized" do
      run = Run.start(published)

      without_host_configuration do
        patch easy_flow.run_path(run), params: { answers: { ask: "yes" } }

        assert_response :not_found
      end
    end

    test "an admin can preview a flow a visitor cannot reach" do
      without_host_configuration do
        get easy_flow.manage_flow_preview_path(published)

        assert_response :success
      end
    end

    test "an admin can step through a preview a visitor cannot reach" do
      without_host_configuration do
        get easy_flow.step_manage_flow_preview_path(published)

        assert_response :success
      end
    end

    test "a preview starts into the preview rather than the visitor path" do
      without_host_configuration do
        get easy_flow.manage_flow_preview_path(published)

        assert_select "a[href=?]", easy_flow.step_manage_flow_preview_path(published)
      end
    end

    test "a host can answer a refusal its own way instead of the plain not found" do
      EasyFlow.refusal_method = :send_a_refused_visitor_to_login

      without_host_configuration do
        get easy_flow.flow_path(published.slug)

        assert_redirected_to "/host-login"
      end
    ensure
      EasyFlow.refusal_method = nil
    end

    test "a host is told which refusal it is answering" do
      EasyFlow.refusal_method = :note_the_refusal

      without_host_configuration do
        get easy_flow.flow_path(published.slug)

        assert_equal "EasyFlow::NotPermitted", response.headers["X-Refusal"]
      end
    ensure
      EasyFlow.refusal_method = nil
    end
  end
end
