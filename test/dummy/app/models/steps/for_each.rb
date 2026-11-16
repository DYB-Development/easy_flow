module Steps
  class ForEach
    include EasyFlow::Step

    step_name "For each"

    holds_steps

    setting :list, type: :string
    setting :concurrency, type: :integer
    setting :on_item_failure, type: :select, options: %w[continue stop]
  end
end
