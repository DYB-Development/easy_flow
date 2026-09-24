EasyFlow::Engine.routes.draw do
  post ":slug/runs", to: "flows#start", as: :flow_runs
  get "runs/:id", to: "flows#step", as: :run
  patch "runs/:id", to: "flows#update"

  get ":slug", to: "flows#show", as: :flow
  get ":slug/step", to: "flows#step", as: :flow_step
end
