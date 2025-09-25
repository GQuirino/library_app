module Api
  module V1
    class DashboardController < ::ApplicationController
      before_action :authenticate_user!

      def index
        if current_user.librarian?
          render json: Dashboards::LibrarianDashboard.call
        elsif current_user.member?
          render json: Dashboards::MemberDashboard.call(current_user)
        end
      end
    end
  end
end
