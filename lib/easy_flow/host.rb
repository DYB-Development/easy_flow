module EasyFlow
  class Host
    attr_reader :name
    attr_writer :layout

    def initialize(name)
      @name = name.to_s
    end

    def layout
      @layout || "easy_flow/application"
    end
  end
end
