require "test_helper"

module EasyFlow
  class FileUploadStepTest < ActionDispatch::IntegrationTest
    def uploading
      @uploading ||= Definition.create!(host: "dummy", slug: "uploading").tap do |flow|
        flow.record_definition(flowing("slug" => "uploading", "entry" => "guide",
          "nodes" => [ { "id" => "guide", "type" => "file_upload", "question" => "Upload the guide", "required" => true, "accepts" => ".pdf" },
                       { "id" => "after", "type" => "question", "question" => "Anything else?", "options" => [ "no" ] } ],
          "edges" => [ { "from" => "guide", "to" => "after" } ]))
        flow.publish
      end
    end

    class KeptFiles
      attr_reader :files

      def initialize
        @files = {}
      end

      def keep(file)
        "kept-#{files.size + 1}".tap { |reference| files[reference] = file.original_filename }
      end

      def name_of(reference)
        files[reference]
      end
    end

    setup { @stored_with, EasyFlow.file_store = EasyFlow.file_store, KeptFiles.new }
    teardown { EasyFlow.file_store = @stored_with }

    test "an uploaded file is kept by the host and the run records the reference it gives" do
      run = Run.start(uploading)

      patch easy_flow.run_path(run), params: { asked: "guide", answers: { guide: fixture_file_upload("guide.pdf", "application/pdf") } }

      assert_equal "guide.pdf", EasyFlow.file_store.name_of(run.reload.recorded[:guide])
    end

    test "a run moves on to the next step once its file is uploaded" do
      run = Run.start(uploading)

      patch easy_flow.run_path(run), params: { asked: "guide", answers: { guide: fixture_file_upload("guide.pdf", "application/pdf") } }
      follow_redirect!

      assert_select "legend", text: "Anything else?"
    end

    test "a visitor who continues past a required file step with no file is told to choose one" do
      run = Run.start(uploading)

      patch easy_flow.run_path(run), params: { asked: "guide" }
      follow_redirect!

      assert_select "body", text: /Choose a file to go on\./
    end

    test "a visitor reaching a file step is offered a file to upload" do
      get easy_flow.run_path(Run.start(uploading))

      assert_select "form[enctype='multipart/form-data'] input[type=file][name='answers[guide]']"
    end
  end
end
