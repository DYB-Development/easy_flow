require "test_helper"

class GemDependenciesTest < ActiveSupport::TestCase
  def requirement_for(name)
    Gem::Specification.load(File.expand_path("../easy_flow.gemspec", __dir__)).dependencies.find { |dependency| dependency.name == name }&.requirement
  end

  test "requires keystone_ui at the version the editor is built against or a later 0.x release" do
    assert_equal Gem::Requirement.new("~> 0.27"), requirement_for("keystone_ui")
  end
end
