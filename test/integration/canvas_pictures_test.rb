require "test_helper"

module EasyFlow
  class CanvasPicturesTest < ActionDispatch::IntegrationTest
    class Store
      def keep(_file, flow:)
        "picture-for-#{flow.slug}"
      end

      def url_of(reference)
        "/pictures/#{reference}"
      end
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

    test "an author who chooses a picture when the host has set up no picture store is told pictures cannot be added yet" do
      EasyFlow.picture_store = nil

      post "#{easy_flow.manage_flow_canvas_path(flow)}/pictures", params: { picture: picture }

      assert_equal [ 422, "Pictures cannot be added yet. Ask the app's developer to set up a picture store." ], [ response.status, response.parsed_body["error"] ]
    end

    test "an author whose chosen picture the host's store refuses is told the store's reason" do
      refusing = Object.new
      refusing.define_singleton_method(:keep) { |_file, flow:| raise PictureRefused, "That file is not a picture." }
      EasyFlow.picture_store = refusing

      post "#{easy_flow.manage_flow_canvas_path(flow)}/pictures", params: { picture: picture }

      assert_equal [ 422, "That file is not a picture." ], [ response.status, response.parsed_body["error"] ]
    end
  end
end
