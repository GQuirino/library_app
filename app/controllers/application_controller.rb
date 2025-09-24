class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError do |exception|
    render json: { error: "Not authorized" }, status: :forbidden
  end
end
