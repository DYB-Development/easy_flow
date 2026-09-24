module EasyFlow
  class Host
    attr_reader :name
    attr_accessor :layout

    def initialize(name)
      @name = name.to_s
    end
  end
end
