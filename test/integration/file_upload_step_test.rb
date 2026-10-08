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

    test "a visitor reaching a file step is offered a file to upload" do
      get easy_flow.run_path(Run.start(uploading))

      assert_select "form[enctype='multipart/form-data'] input[type=file][name='answers[guide]']"
    end
  end
end
