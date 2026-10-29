require "test_helper"

module EasyFlow
  class CanvasPicturesTest < ActionDispatch::IntegrationTest
    class Store
      def keep(_file, flow:) = "picture-for-#{flow.slug}"
      def url_of(reference) = "/pictures/#{reference}"
    end

    setup do
      @stored_with, EasyFlow.picture_store = EasyFlow.picture_store, Store.new
    end

    teardown do
      EasyFlow.picture_store = @stored_with
    end

    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "canvas")
    end

    def picture
      Rack::Test::UploadedFile.new(file_fixture("picture.png"), "image/png")
    end

    test "an author's chosen picture is kept for the flow and its reference and address are returned" do
      post "#{easy_flow.manage_flow_canvas_path(flow)}/pictures", params: { picture: picture }

      assert_equal({ "reference" => "picture-for-canvas", "url" => "/pictures/picture-for-canvas" }, response.parsed_body)
    end
  end
end
