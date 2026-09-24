require "test_helper"

class TailwindSourcesTest < ActiveSupport::TestCase
  test "the engine has keystone_ui's Tailwind build scan its views" do
    assert_includes KeystoneUi.configuration.tailwind_sources, EasyFlow::Engine.root.join("app/views/**/*.erb").to_s
  end
end
