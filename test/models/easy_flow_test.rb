require "test_helper"

module EasyFlow
  class EasyFlowTest < ActiveSupport::TestCase
    test "keeps the settings a host is set up with" do
      EasyFlow.host(:alembic) { |host| host.layout = "alembic" }

      assert_equal "alembic", EasyFlow.hosts.fetch("alembic").layout
    ensure
      EasyFlow.hosts.delete("alembic")
    end

    test "refuses to set up a host with no name" do
      assert_raises(ArgumentError) { EasyFlow.host("") }
    end

    test "finds no flows for a host that is not set up, even flows that name it" do
      Definition.create!(host: "retired", slug: "old")

      assert_empty EasyFlow.host_named("retired").flows
    end

    test "draws a step with the template it ships when nothing replaces it" do
      assert_equal "easy_flow/steps/choosing", EasyFlow.drawing
    end

    test "draws every step with the template a host puts in its place" do
      EasyFlow.draws_with("host/steps/panel")

      assert_equal "host/steps/panel", EasyFlow.drawing
    ensure
      EasyFlow.draws_with(nil)
    end

    test "builds its controllers on a plain controller when the host names none" do
      host_controller = EasyFlow.base_controller
      EasyFlow.base_controller = nil

      assert_equal "ActionController::Base", EasyFlow.base_controller
    ensure
      EasyFlow.base_controller = host_controller
    end

    test "refuses a check it does not ship" do
      assert_raises(UnknownCheck) { EasyFlow.check(:invented) }
    end

    test "keeps a picture through the host's picture store, telling it the flow the picture belongs to" do
      kept = []
      store = Object.new
      store.define_singleton_method(:keep) { |file, flow:| kept << [ file, flow ] && "picture-1" }
      stored_with, EasyFlow.picture_store = EasyFlow.picture_store, store
      flow = Definition.new(slug: "capitals")

      assert_equal [ "picture-1", [ [ :file, flow ] ] ], [ EasyFlow.keep_picture(:file, flow: flow), kept ]
    ensure
      EasyFlow.picture_store = stored_with
    end

    test "refuses to keep a picture when the host has set up no picture store" do
      stored_with, EasyFlow.picture_store = EasyFlow.picture_store, nil

      assert_raises(NoPictureStore) { EasyFlow.keep_picture(:file, flow: Definition.new(slug: "capitals")) }
    ensure
      EasyFlow.picture_store = stored_with
    end

    test "turns a picture's reference into the address the host's picture store gives for it" do
      store = Object.new
      store.define_singleton_method(:url_of) { |reference| "/pictures/#{reference}" }
      stored_with, EasyFlow.picture_store = EasyFlow.picture_store, store

      assert_equal "/pictures/picture-1", EasyFlow.picture_url("picture-1")
    ensure
      EasyFlow.picture_store = stored_with
    end

    test "gives no picture address for a step with no picture" do
      assert_nil EasyFlow.picture_url(nil)
    end

    test "refuses to keep an uploaded file when the host has set up no file store" do
      stored_with, EasyFlow.file_store = EasyFlow.file_store, nil

      assert_raises(NoFileStore) { EasyFlow.keep_file(Rack::Test::UploadedFile.new(file_fixture("guide.pdf"), "application/pdf")) }
    ensure
      EasyFlow.file_store = stored_with
    end
  end
end
