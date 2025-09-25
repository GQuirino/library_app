class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    token = request.env["warden-jwt_auth.token"]
    render json: { user: resource, token: token }, status: :ok
  end

  def respond_to_on_destroy
    if current_user
      render json: { message: "Logged out successfully." }, status: :ok
    else
      render json: { errors: [ "User has no active session." ] }, status: :unauthorized
    end
  end
end
