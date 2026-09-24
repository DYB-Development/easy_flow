require "test_helper"

module EasyFlow
  class CanvasAssetTest < ActionDispatch::IntegrationTest
    test "the canvas bundle is served by the asset pipeline" do
      get ActionController::Base.helpers.asset_path("easy_flow/canvas.js")

      assert_response :success
    end
  end
end
