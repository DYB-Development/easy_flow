require "test_helper"

module EasyFlow
  class HostTest < ActiveSupport::TestCase
    test "renders its visitor pages in easy_flow's own layout when it names none" do
      assert_equal "easy_flow/application", Host.new(:alembic).layout
    end
  end
end
