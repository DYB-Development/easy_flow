Rails.application.routes.draw do
  mount EasyFlow::Engine => "/easy_flow", defaults: { easy_flow_host: "dummy" }
  mount EasyFlow::Engine => "/console", as: :console_flows, defaults: { easy_flow_host: "console" }
  mount EasyFlow::Engine => "/retired", as: :retired_flows, defaults: { easy_flow_host: "retired" }

  scope defaults: { easy_flow_host: "dummy" } do
    get "host/:slug/step", to: "host_flows#step"
    post "host/:slug/runs", to: "host_flows#start"
    get "host/runs/:id", to: "host_flows#step", as: :host_run
    patch "host/runs/:id", to: "host_flows#update"
  end
end
