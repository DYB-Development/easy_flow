EasyFlow.layout = "application"
EasyFlow.base_controller = "ApplicationController"
EasyFlow.visitor_authorization_method = :easy_flow_visitor_permitted?

EasyFlow.host(:dummy)
EasyFlow.host(:console)

Rails.application.config.to_prepare do
  Steps::Notify.register
  Steps::Deliver.register
end
