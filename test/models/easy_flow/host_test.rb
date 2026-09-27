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
  end
end
