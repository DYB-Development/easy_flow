module EasyFlow
  Asked = Data.define(:id, :text, :choices, :picture_url) do
    def initialize(id:, text:, choices:, picture_url: nil)
      super
    end
  end
end
