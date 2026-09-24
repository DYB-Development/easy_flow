module EasyFlow
  class Host
    attr_reader :name
    attr_writer :layout, :admin_layout

    def initialize(name)
      @name = name.to_s
    end

    def layout
      @layout || "easy_flow/application"
    end

    def admin_layout
      @admin_layout || "application"
    end
  end
end
