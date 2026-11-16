module EasyFlow
  class CheckList
    def initialize(violations)
      @violations = violations
    end

    def rows
      @violations.map { |violation| { "level" => "error", "node" => violation["node"], "sentence" => violation["sentence"] } }
    end
  end
end
