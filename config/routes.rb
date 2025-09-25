Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  devise_for :users,
    path: "",
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      registration: "signup"
    },
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations"
    }

  namespace :api do
    namespace :v1 do
      get "/dashboard", to: "dashboard#index"

      resources :books do
        resources :book_copies, except: [ :show ]
      end

      resources :book_copies, only: [ :show ]

      resources :reservations, only: [ :index, :show ] do
        member do
          patch :return_book, path: "return"
        end
      end

      post "/reservations/create", to: "reservations#create", as: "create_reservation"
    end
  end
end
