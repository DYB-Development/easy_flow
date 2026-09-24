EasyFlow.base_controller = "ApplicationController"

EasyFlow.host(:dummy) do |host|
  host.layout = "application"
  host.visitor_authorization_method = :easy_flow_visitor_permitted?
end

EasyFlow.host(:console) { |host| host.visitor_authorization_method = :easy_flow_visitor_permitted? }

Rails.application.config.to_prepare do
  Steps::Notify.register
  Steps::Deliver.register
end
