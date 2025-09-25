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

      resources :reservations, only: [ :index, :show, :create ] do
        member do
          patch :return_book, path: "return"
          post :create
        end
      end
    end
  end
end
