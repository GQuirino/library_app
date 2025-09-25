Rails.application.routes.draw do
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

      post "/reservations/create", to: "reservations#create", as: "create_reservation"
      patch "/reservations/:id/return", to: "reservations#return_book", as: "return_book"
    end
  end
end
