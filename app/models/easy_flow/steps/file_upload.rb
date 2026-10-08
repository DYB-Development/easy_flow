module EasyFlow
  module Steps
    class FileUpload
      include Step

      Asked = Data.define(:id, :text, :accepts)

      step_name "File upload"

      setting :question, type: :string
      setting :accepts, type: :string, label: "Accepted file types"
      setting :required, type: :boolean

      names_by :question
      awaits_input
      drawn_by "easy_flow/steps/uploading"
      answer_check { |node, value| FileUpload.problem_with(node, value) }
      labels_answer_by { |_node, reference| EasyFlow.file_store&.name_of(reference) }

      displays_by { |node| Asked.new(id: node.id.to_sym, text: node.config["question"], accepts: node.config["accepts"]) }

      def self.problem_with(node, value)
        return "Choose a file to go on." if node.config["required"] && value.blank?
        return if value.blank?
        return "A file can only be uploaded in a flow that saves its runs." unless value.respond_to?(:original_filename)

        kinds = accepted_kinds(node)
        return if kinds.empty?
        return if kinds.include?(File.extname(value.original_filename).downcase)

        "Choose a #{kinds.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')} file."
      end

      def self.accepted_kinds(node)
        node.config["accepts"].to_s.split(",").map { |kind| kind.strip.downcase }.compact_blank
      end
    end
  end
end
