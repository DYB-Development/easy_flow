module EasyFlow
  class ForEach
    include Step

    step_name "For each"

    holds_steps
    repeats_held_steps_for :list

    setting :list, type: :string
    setting :concurrency, type: :integer
    setting :on_item_failure, type: :select, options: %w[continue stop]

    output :result, values: %w[passed failed]
    output :items
    output :passed, type: :integer
    output :failed, type: :integer
  end
end
