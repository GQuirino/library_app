module Api
  module V1
    class ReservationsController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/reservations/create
      def create
        authorize Reservation

        begin
          ActiveRecord::Base.transaction do
            book_copy = BookCopy.find(create_reservation_params[:book_copy_id])

            # prefer logged in user as reservation user
            @reservation = Reservation.new(
              user_id: create_reservation_params[:user_id].presence || current_user.id,
              book_copy: book_copy,
              return_date: create_reservation_params[:return_date]
            )

            @reservation.save!

            render json: @reservation, status: :created
          end
        rescue ActiveRecord::RecordNotFound
          render json: { errors: ['Book copy not found'] }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [e.message] }, status: :unprocessable_content
        rescue ActionController::ParameterMissing => e
          render json: { errors: [e.message] }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "Reservation creation failed: #{e.message}"
          render json: { errors: ['Unable to create reservation. Please try again.'] }, status: :internal_server_error
        end
      end

      # PATCH /api/v1/reservations/:id/return
      def return_book
        authorize Reservation, :update?

        begin
          ActiveRecord::Base.transaction do
            @reservation = Reservation.find(params[:id])

            if @reservation.returned_at.present?
              render json: { errors: ['Book has already been returned'] }, status: :unprocessable_content
              return
            end

            if @reservation.mark_as_returned!
              render json: { message: "Book returned successfully" }, status: :ok
            else
              render json: { errors: @reservation.errors.full_messages }, status: :unprocessable_content
            end
          end
        rescue ActiveRecord::RecordNotFound
          render json: { errors: ['Reservation not found'] }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [e.message] }, status: :unprocessable_content
        rescue StandardError => e
          Rails.logger.error "Book return failed: #{e.message}"
          render json: { errors: ['Unable to return book. Please try again.'] }, status: :internal_server_error
        end
      end

      private

     def create_reservation_params
        reservation_params = params.require(:reservation).permit(:user_id, :book_copy_id, :return_date)

        # Check for empty/nil required fields
        if reservation_params[:book_copy_id].blank?
          raise ActionController::ParameterMissing.new(:book_copy_id)
        end

        if reservation_params[:return_date].blank?
          raise ActionController::ParameterMissing.new(:return_date)
        end

        reservation_params
      end
    end
  end
end
