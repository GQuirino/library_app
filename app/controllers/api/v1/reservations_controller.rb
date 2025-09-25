module Api
  module V1
    class ReservationsController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/reservations
      def index
        authorize Reservation

        @reservations = Reservation.all

        @reservations = @reservations.filter_by(:user_id, filter_params[:user_id]) if filter_params[:user_id].present?
        @reservations = @reservations.filter_by(:book_copy, filter_params[:book_copies]) if filter_params[:book_copies].present?
        @reservations = @reservations.by_book(filter_params[:book]) if filter_params[:book].present?
        @reservations = @reservations.by_return_date_range(*filter_params[:return_date_range]) if filter_params[:return_date_range].present?

        @reservations = @reservations.overdue if filter_params[:overdue].present? && filter_params[:overdue] == "true"
        @reservations = @reservations.active if filter_params[:overdue].present? && filter_params[:overdue] == "false"

        @reservations = @reservations.page(params["page"])
                                     .per(params["per_page"] || 20)
                                     .order(return_date: :desc)

        render json: {
          reservations: @reservations,
          meta: pagination_meta(@reservations),
          filters: filter_params
        }
      end

      # GET /api/v1/reservations/:id
      def show
        authorize Reservation

        @reservation = Reservation.find_by(id: params[:id])

        if @reservation
          render json: @reservation
        else
          render json: { errors: [ "Reservation not found" ] }, status: :not_found
        end
      end

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
          render json: { errors: [ "Book copy not found" ] }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [ e.message ] }, status: :unprocessable_content
        rescue ActionController::ParameterMissing => e
          render json: { errors: [ e.message ] }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "Reservation creation failed: #{e.message}"
          render json: { errors: [ "Unable to create reservation. Please try again." ] }, status: :internal_server_error
        end
      end

      # PATCH /api/v1/reservations/:id/return
      def return_book
        authorize Reservation, :update?

        begin
          ActiveRecord::Base.transaction do
            @reservation = Reservation.find(params[:id])

            if @reservation.returned_at.present?
              render json: { errors: [ "Book has already been returned" ] }, status: :unprocessable_content
              return
            end

            if @reservation.mark_as_returned!
              render json: { message: "Book returned successfully" }, status: :ok
            else
              render json: { errors: @reservation.errors.full_messages }, status: :unprocessable_content
            end
          end
        rescue ActiveRecord::RecordNotFound
          render json: { errors: [ "Reservation not found" ] }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [ e.message ] }, status: :unprocessable_content
        rescue StandardError => e
          Rails.logger.error "Book return failed: #{e.message}"
          render json: { errors: [ "Unable to return book. Please try again." ] }, status: :internal_server_error
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

      def filter_params
        permitted_params = params.permit({ return_date_range: [ :start, :end ] }, :overdue, :user_id, :book_copies, :book).transform_values { |v| v.to_s.strip.presence }.compact

        permitted_params.tap do |filters|
          # permitted_params[:return_date_range] = "{\"start\"=>\"2025-09-30\", \"end\"=>\"2025-10-10\"}"
          if permitted_params[:return_date_range].present?
            range = permitted_params[:return_date_range].gsub(/[{}"]/, "").split(",").map { |pair| pair.split("=>").map(&:strip) }.to_h
            filters[:return_date_range] = [
              (range["start"].strip.presence),
              (range["end"].strip.presence || Date.current + 14.days)
            ].flatten.compact
          end
        end
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
