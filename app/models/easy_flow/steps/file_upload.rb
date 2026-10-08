module EasyFlow
  module Steps
    class FileUpload
      include Step

      Asked = Data.define(:id, :text, :accepts)

      step_name "File upload"

      setting :question, type: :string
      setting :accepts, type: :string, label: "Accepted file types"

      names_by :question
      awaits_input
      drawn_by "easy_flow/steps/uploading"

      displays_by { |node| Asked.new(id: node.id.to_sym, text: node.config["question"], accepts: node.config["accepts"]) }
    end
  end
end
