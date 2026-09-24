module EasyFlow
  class Host
    attr_reader :name
    attr_writer :layout, :admin_layout
    attr_accessor :admin_authentication_method

    def initialize(name)
      @name = name.to_s
    end

    def layout
      @layout || "easy_flow/application"
    end

    def admin_layout
      @admin_layout || "application"
    end

    def flows
      Definition.where(host: name)
    end

    def set_up?
      true
    end
  end
end
