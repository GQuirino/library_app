class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: { message: "Signed up.", user: resource }, status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_content
    end
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :birthdate, :phone_number, address: [ :street, :city, :state, :zip ] ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :birthdate, :phone_number, address: [ :street, :city, :state, :zip ] ])
  end
end
