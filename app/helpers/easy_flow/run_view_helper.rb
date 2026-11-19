require "keystone_ui/react/mount_helper"

module EasyFlow
  module RunViewHelper
    include KeystoneUi::React::MountHelper

    def easy_flow_run_view(version, steps:, selected: nil, ended_at: nil, start_and_end: true, **attributes)
      react_ui("easy_flow/run-view", RunView.new(version, steps: steps, selected: selected, ended_at: ended_at, start_and_end: start_and_end).to_h,
               data: { flow_run_view: true }, **attributes)
    end
  end
end
