module Steps
  class Notify
    include EasyFlow::Step

    step_name "Notify"

    awaits_input
    drawn_by "steps/notify"
    displays_by { |node| EasyFlow::Asked.new(id: node.id.to_sym, text: node.config["message"], choices: []) }

    setting :message, type: :string
    setting :channels, type: :multi_select, options: %w[email sms push], limit: 2,
      check: ->(chosen) { "Channels needs at least one" if chosen.blank? }
  end
end
