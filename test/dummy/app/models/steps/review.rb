module Steps
  class Review
    include EasyFlow::Step

    step_name "Review"

    setting :role, type: :string
    setting :hours, type: :integer

    summarizes_by { |node| "role: #{node.config['role']} · #{node.config['hours']}h" }
  end
end
