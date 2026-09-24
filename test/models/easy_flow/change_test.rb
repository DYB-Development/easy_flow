require "test_helper"

module EasyFlow
  class ChangeTest < ActiveSupport::TestCase
    test "phrases an added step by name" do
      assert_equal "Added “What is your budget?”", Change.phrase("action" => "added", "named" => [ "What is your budget?" ])
    end

    test "phrases a connection between two steps" do
      assert_equal "Connected “branch” → “basic”", Change.phrase("action" => "connected", "named" => [ "branch", "basic" ])
    end

    test "phrases a change that names nothing" do
      assert_equal "Added", Change.phrase("action" => "added", "named" => [])
    end

    test "falls back to an action it does not know" do
      assert_equal "reticulated", Change.phrase("action" => "reticulated", "named" => [])
    end

    test "drops a name that is missing rather than quoting nothing" do
      assert_equal "Connected “branch”", Change.phrase("action" => "connected", "named" => [ "branch", nil ])
    end

    test "phrases a detail plainly rather than quoting it like a name" do
      assert_equal "Returned to version 3", Change.phrase("action" => "returned", "detail" => "version 3")
    end

    test "prefers a name over a detail when both arrive" do
      assert_equal "Added “A”", Change.phrase("action" => "added", "named" => [ "A" ], "detail" => "ignored")
    end
  end
end
