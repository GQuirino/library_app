module Api
  module V1
    class ReservationsController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/reservations
      def index
        authorize Reservation

        @reservations = Reservation.all

        if filter_params[:search].present?
            search = filter_params[:search]
            base = @reservations.joins(:user).joins(book_copy: :book)
            user_name_match = User.arel_table[:name].matches("%#{search}%")
            book_title_match = Book.arel_table[:title].matches("%#{search}%")
            book_author_match = Book.arel_table[:author].matches("%#{search}%")
            @reservations = base.where(
              user_name_match.or(book_title_match).or(book_author_match)
            )
        end

        @reservations = @reservations.filter_by(:user_id, filter_params[:user_id]) if filter_params[:user_id].present?
        @reservations = @reservations.filter_by(:book_copy, filter_params[:book_copies]) if filter_params[:book_copies].present?
        @reservations = @reservations.by_book(filter_params[:book]) if filter_params[:book].present?
        @reservations = @reservations.by_return_date_range(filter_params[:return_date_range_start], filter_params[:return_date_range_end]) if filter_params[:return_date_range_start].present? && filter_params[:return_date_range_end].present?

        @reservations = @reservations.overdue if filter_params[:overdue].present? && filter_params[:overdue] == "true"
        @reservations = @reservations.active if filter_params[:overdue].present? && filter_params[:overdue] == "false"

        @reservations = @reservations.page(params["page"])
                                     .per(params["per_page"] || 20)
                                     .order(return_date: :desc)

        render json: {
          reservations: @reservations.joins(book_copy: :book).joins(:user).select(
            "reservations.*",
            "books.title as book_title",
            "books.author as book_author",
            "book_copies.book_serial_number as book_serial_number",
            "users.name as user_name",
            "users.id as user_id",
            "users.email as user_email"
          ),
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
          # if book_copy_id not found search book_id and fetch the first available copy
          ActiveRecord::Base.transaction do
            book_copy = if create_reservation_params[:book_copy_id]
              BookCopy.find_by(id: create_reservation_params[:book_copy_id])
            elsif create_reservation_params[:book_id]
              book = Book.find(create_reservation_params[:book_id])
              book.book_copies.available.first if book
            end

            raise ActiveRecord::RecordNotFound  unless book_copy

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
          render json: { errors: [ "Book copy not found or not available" ] }, status: :not_found
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
        reservation_params = params.require(:reservation).permit(:user_id, :book_copy_id, :return_date, :book_id)

        # Check for empty/nil required fields
        if reservation_params[:book_copy_id].blank? && reservation_params[:book_id].blank?
          raise ActionController::ParameterMissing.new(:book_copy_id, :book_id)
        end

        if reservation_params[:return_date].blank?
          raise ActionController::ParameterMissing.new(:return_date)
        end

        reservation_params
      end

      def filter_params
        params.permit(:return_date_range_start, :return_date_range_end, :overdue, :user_id, :book_copies, :book, :search).transform_values { |v| v.to_s.strip.presence }.compact
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
