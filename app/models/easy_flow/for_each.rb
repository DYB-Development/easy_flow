module EasyFlow
  class ForEach
    include Step

    ITEM_LIMIT = 100

    step_name "For each"

    holds_steps
    repeats_held_steps_for :list
    needs_a_saved_run "Steps can only be run for each item in a flow that saves its runs."

    setting :list, type: :string
    setting :concurrency, type: :integer
    setting :on_item_failure, type: :select, options: %w[continue stop]
    setting :item_limit, type: :integer, label: "Most items"

    output :result, values: %w[passed failed]
    output :items
    output :passed, type: :integer
    output :failed, type: :integer
  end
end
