module EasyFlow
  class UnsetHost < Host
    def initialize
      super(nil)
    end

    def flows
      Definition.none
    end

    def set_up?
      false
    end
  end
end
