module Steps
  class AwaitSignal
    include EasyFlow::Step

    cattr_accessor :signalled, default: false

    step_name "Await signal"

    waits_until { |_node, _state| Steps::AwaitSignal.signalled }
  end
end
