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
    end
  end
end
