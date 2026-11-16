EasyFlow.base_controller = "ApplicationController"

EasyFlow.host(:dummy) do |host|
  host.layout = "application"
  host.visitor_authorization_method = :easy_flow_visitor_permitted?
  host.drawer_tabs = lambda do |flow|
    [ { label: "Fixtures", count: "12/12", content: "<p>12 of 12 fixtures pass for #{ERB::Util.html_escape(flow.slug)}.</p>" },
      { label: "Flow tests", count: "3/3", content: "<p>3 of 3 flow tests pass.</p>" },
      { label: "Dry-run", content: "<p>No dry-run yet.</p>" } ]
  end
end

EasyFlow.host(:owned) do |host|
  host.visitor_authorization_method = :easy_flow_visitor_permitted?
  host.owner_method = :current_customer
end

EasyFlow.host(:console) { |host| host.visitor_authorization_method = :easy_flow_visitor_permitted? }

EasyFlow.host(:branded) do |host|
  host.layout = "branded"
  host.admin_layout = "branded"
  host.visitor_authorization_method = :easy_flow_visitor_permitted?
end

Rails.application.config.to_prepare do
  Steps::Notify.register
  Steps::Deliver.register
  Steps::AwaitSignal.register
  Steps::ForTheRun.register
  Steps::NameCustomer.register
  Steps::ForEach.register
  Steps::Agent.register
  Steps::Check.register
  Steps::Review.register
  Steps::Integration.register
  Steps::EmitEvent.register
end
