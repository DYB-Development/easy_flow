require "test_helper"

class ThemeColoursTest < ActiveSupport::TestCase
  FIXED_COLOURS = /\b(?:hover:|divide-)?(?:text|bg|border|divide)-(?:gray-\d+|white|black)\b/

  def fixed_colours_in(view)
    EasyFlow::Engine.root.join("app/views/easy_flow", view).read.scan(FIXED_COLOURS)
  end

  test "a choice step colours its question from the host's theme" do
    assert_empty fixed_colours_in("steps/_choosing.html.erb")
  end
end
