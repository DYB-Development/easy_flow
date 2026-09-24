module EasyFlow
  class UnsetHost < Host
    def initialize
      super(nil)
    end

    def flows
      Definition.none
    end
  end
end
