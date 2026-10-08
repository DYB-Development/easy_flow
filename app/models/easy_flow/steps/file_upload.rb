module EasyFlow
  module Steps
    class FileUpload
      include Step

      step_name "File upload"

      setting :question, type: :string
      setting :accepts, type: :string, label: "Accepted file types"

      names_by :question
      awaits_input
    end
  end
end
