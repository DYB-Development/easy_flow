Rails.application.routes.draw do
  mount EasyFlow::Engine => "/easy_flow", defaults: { easy_flow_host: "dummy" }
  mount EasyFlow::Engine => "/console", as: :console_flows, defaults: { easy_flow_host: "console" }
  mount EasyFlow::Engine => "/retired", as: :retired_flows, defaults: { easy_flow_host: "retired" }
  mount EasyFlow::Engine => "/owned", as: :owned_flows, defaults: { easy_flow_host: "owned" }
  mount EasyFlow::Engine => "/branded", as: :branded_flows, defaults: { easy_flow_host: "branded" }

  get "home", to: redirect("/"), as: :home

  get "host/:slug", to: "host_flows#show", as: :host_flow
  get "host/:slug/step", to: "host_flows#step", as: :host_flow_step
  post "host/:slug/runs", to: "host_flows#start", as: :host_flow_runs
  get "host/runs/:id", to: "host_flows#step", as: :host_run
  patch "host/runs/:id", to: "host_flows#update"

  get "coded/:slug", to: "coded_flows#show", as: :coded_flow
  get "coded/:slug/step", to: "coded_flows#step", as: :coded_flow_step
  post "coded/:slug/runs", to: "coded_flows#start", as: :coded_flow_runs
  get "coded/runs/:id", to: "coded_flows#step", as: :coded_run
  patch "coded/runs/:id", to: "coded_flows#update"
end
