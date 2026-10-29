require "test_helper"

module EasyFlow
  class AskedTest < ActiveSupport::TestCase
    test "carries a picture's address when it is given one and none otherwise" do
      assert_equal [ "/pictures/picture-1", nil ], [ Asked.new(id: :a, text: "A?", choices: [], picture_url: "/pictures/picture-1").picture_url,
                                                     Asked.new(id: :a, text: "A?", choices: []).picture_url ]
    end
  end
end
