module EasyFlow
  module Steps
    class FileUpload
      include Step

      step_name "File upload"

      setting :question, type: :string

      names_by :question
      awaits_input
    end
  end
end
