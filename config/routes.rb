Rails.application.routes.draw do
  scope :v1, module: "api/v1", as: :v1 do
    resources :packages, only: %i[index show], param: :name do
      member do
        get "releases/latest", to: "releases#latest"
        get "releases/:version", to: "releases#show"
      end
    end

    get "blobs/:blake3", to: "blobs#show", as: :blob
    post "blobs", to: "blobs#create"
    get "keys/:fingerprint", to: "keys#show", as: :key
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
