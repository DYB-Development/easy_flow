Rails.application.routes.draw do
  mount EasyFlow::Engine => "/easy_flow"

  get "host/:slug/step", to: "host_flows#step"
  post "host/:slug/runs", to: "host_flows#start"
  get "host/runs/:id", to: "host_flows#step", as: :host_run
end
