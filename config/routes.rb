EasyFlow::Engine.routes.draw do
  namespace :manage do
    resources :flows, only: [ :index, :create, :show, :edit, :update, :destroy ] do
      resource :definition, only: [ :edit, :update ]
      resource :preview, only: :show, controller: "previews" do
        get :step
      end
      resources :versions, only: :index do
        post :return, on: :member
      end

      resource :canvas, only: :show, controller: "canvas" do
        post   "steps",       action: :add_step
        patch  "steps/:step", action: :configure_step
        delete "steps/:step",      action: :remove_step
        patch  "steps/:step/move", action: :move_step
        post   "versions",    action: :create
        post   "publish",     action: :publish
        patch  "details",     action: :details
        post   "undo",        action: :undo
        post   "redo",        action: :redo
        post   "edges",       action: :connect
        delete "edges",       action: :disconnect
      end
    end
  end

  post ":slug/runs", to: "flows#start", as: :flow_runs
  get "runs/:id", to: "flows#step", as: :run
  patch "runs/:id", to: "flows#update"

  get ":slug", to: "flows#show", as: :flow
  get ":slug/step", to: "flows#step", as: :flow_step
end
