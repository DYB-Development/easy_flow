require "test_helper"

module EasyFlow
  module Steps
    class FileUploadTest < ActiveSupport::TestCase
      test "an admin can give a file step a question on the canvas" do
        assert_equal :string, EasyFlow.registry.fetch(:file_upload).settings.fields[:question]
      end

      test "an admin can set which kinds of file a file step accepts" do
        assert_equal "Accepted file types", EasyFlow.registry.fetch(:file_upload).settings.labels[:accepts]
      end

      test "a required file step refuses a visitor who chose no file" do
        node = Node.new(id: "guide", type: "file_upload", config: { "required" => true })

        assert_equal "Choose a file to go on.", FileUpload.step_type.answer_problem(node, "")
      end

      test "a file step refuses a file of a kind it does not accept and names the kinds it does" do
        node = Node.new(id: "guide", type: "file_upload", config: { "accepts" => ".pdf, .docx" })
        notes = Rack::Test::UploadedFile.new(file_fixture("notes.txt"), "text/plain")

        assert_equal "Choose a .pdf or .docx file.", FileUpload.step_type.answer_problem(node, notes)
      end
    end
  end
end
