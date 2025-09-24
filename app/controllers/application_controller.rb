class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_user!
end
