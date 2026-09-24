Rails.application.routes.draw do
  mount EasyFlow::Engine => "/easy_flow"

  get "host/:slug/step", to: "host_flows#step"
end
