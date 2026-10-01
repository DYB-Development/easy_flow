module Steps
  class ForTheRun
    include EasyFlow::Step

    step_name "For the run"

    awaits_input
    drawn_by "steps/notify"
    displays_by { |node, run| EasyFlow::Asked.new(id: node.id.to_sym, text: "Asked in run #{run.id}", choices: []) }
  end
end
