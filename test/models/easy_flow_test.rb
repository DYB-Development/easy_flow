require "test_helper"

module EasyFlow
  class EasyFlowTest < ActiveSupport::TestCase
    test "keeps the settings a host is set up with" do
      EasyFlow.host(:alembic) { |host| host.layout = "alembic" }

      assert_equal "alembic", EasyFlow.hosts.fetch("alembic").layout
    ensure
      EasyFlow.hosts.delete("alembic")
    end

    test "refuses to set up a host with no name" do
      assert_raises(ArgumentError) { EasyFlow.host("") }
    end

    test "finds no flows for a host that is not set up, even flows that name it" do
      Definition.create!(host: "retired", slug: "old")

      assert_empty EasyFlow.host_named("retired").flows
    end

    test "draws a step with the template it ships when nothing replaces it" do
      assert_equal "easy_flow/steps/choosing", EasyFlow.drawing
    end

    test "draws every step with the template a host puts in its place" do
      EasyFlow.draws_with("host/steps/panel")

      assert_equal "host/steps/panel", EasyFlow.drawing
    ensure
      EasyFlow.draws_with(nil)
    end

    test "renders the visitor pages in its own layout when the host names none" do
      host_layout = EasyFlow.layout
      EasyFlow.layout = nil

      assert_equal "easy_flow/application", EasyFlow.layout
    ensure
      EasyFlow.layout = host_layout
    end

    test "builds its controllers on a plain controller when the host names none" do
      host_controller = EasyFlow.base_controller
      EasyFlow.base_controller = nil

      assert_equal "ActionController::Base", EasyFlow.base_controller
    ensure
      EasyFlow.base_controller = host_controller
    end

    test "refuses a check it does not ship" do
      assert_raises(UnknownCheck) { EasyFlow.check(:invented) }
    end
  end
end
