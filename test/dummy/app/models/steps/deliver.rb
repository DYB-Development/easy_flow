module Steps
  class Deliver
    include EasyFlow::Step

    step_name "Deliver"

    setting :message, type: :string
    setting :to, type: :previous_step

    def process(node, state)
      state[node.config["to"]].present?
    end
  end
end
