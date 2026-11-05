require "test_helper"

module EasyFlow
  class HostTest < ActiveSupport::TestCase
    test "renders its visitor pages in easy_flow's own layout when it names none" do
      assert_equal "easy_flow/application", Host.new(:alembic).layout
    end

    test "renders its pages for managing flows in the application layout when it names none" do
      assert_equal "application", Host.new(:alembic).admin_layout
    end

    test "holds only the flows it owns" do
      Definition.create!(host: "console", slug: "setup")

      assert_empty Host.new(:alembic).flows
    end

    test "offers every step type when it names none" do
      assert Host.new(:alembic).offers?(:question)
    end

    test "does not offer a step type left off the list it names" do
      host = Host.new(:alembic)
      host.offers = %i[compare]

      assert_not host.offers?(:question)
    end

    test "offers a step type on the list it names" do
      host = Host.new(:alembic)
      host.offers = %i[compare]

      assert host.offers?("compare")
    end

    test "asks the object it names which answers a step allows in a run" do
      host = Host.new(:shop)
      host.allowed_answers = ->(step, answers) { [ "download" ] if step.id == "sold_as" && answers[:kind] == "pdf" }

      assert_equal [ "download" ], host.answers_allowed(Node.new(id: "sold_as", type: "question", config: {}), { kind: "pdf" })
    end

    test "leaves insert buttons hidden until hovered when it says nothing" do
      assert_not Host.new(:alembic).always_show_insert_buttons?
    end

    test "keeps showing step type codes when it says nothing" do
      assert_not Host.new(:alembic).hide_step_type_codes?
    end

    test "hides step type codes when it asks to" do
      host = Host.new(:alembic)
      host.hide_step_type_codes = true

      assert host.hide_step_type_codes?
    end

    test "always shows insert buttons when it asks to" do
      host = Host.new(:alembic)
      host.always_show_insert_buttons = true

      assert host.always_show_insert_buttons?
    end

    test "a host names no note for Publish unless it sets one" do
      assert_nil Host.new(:alembic).publish_note
    end

    test "a host gives no explanation for a setting unless it sets one" do
      assert_nil Host.new(:alembic).explanation_for(:question, :category)
    end

    test "a host gives the explanation it sets for one setting of one step type" do
      host = Host.new(:alembic)
      host.setting_explanations = { question: { category: "The round this question counts toward." } }

      assert_equal "The round this question counts toward.", host.explanation_for(:question, :category)
    end

    test "a host names no back link unless it sets one" do
      assert_nil Host.new(:alembic).back_link
    end

    test "a host refuses a back link with no address" do
      assert_raises(ArgumentError) { Host.new(:alembic).back_link = { label: "Games" } }
    end
  end
end
