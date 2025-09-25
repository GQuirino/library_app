module Api
  module V1
    class BookCopiesController < ::ApplicationController
      before_action :authenticate_user!
      before_action :set_book, except: [ :show ]
      before_action :set_book_copy, only: [ :show, :update, :destroy ]

      # GET /books/:book_id/book_copies
      def index
        authorize @book

        @book_copies = @book.book_copies
                            .page(params["page"])
                            .per(params["per_page"] || 20)
                            .order(:book_serial_number)

        # Apply filters
        filter_params.each do |key, value|
          @book_copies = @book_copies.filter_by(key, value)
        end

        render json: {
          book_copies: @book_copies.map do |copy|
            {
              id: copy.id,
              book_serial_number: copy.book_serial_number,
              available: copy.available,
              book_id: copy.book_id,
              book_title: @book.title,
              created_at: copy.created_at,
              updated_at: copy.updated_at
            }
          end,
          meta: pagination_meta(@book_copies),
          book: {
            id: @book.id,
            title: @book.title,
            author: @book.author
          },
          filters: filter_params
        }
      end

      # GET /book_copies/:id
      def show
        authorize @book_copy.book

        render json: {
          book_copy: {
            id: @book_copy.id,
            book_serial_number: @book_copy.book_serial_number,
            available: @book_copy.available,
            created_at: @book_copy.created_at,
            updated_at: @book_copy.updated_at,
            book: {
              id: @book_copy.book.id,
              title: @book_copy.book.title,
              author: @book_copy.book.author,
              publisher: @book_copy.book.publisher,
              isbn: @book_copy.book.isbn,
              genre: @book_copy.book.genre,
              edition: @book_copy.book.edition,
              year: @book_copy.book.year
            }
          }
        }
      end

      # POST /books/:book_id/book_copies
      def create
        authorize @book, :create?

        @book_copy = @book.book_copies.build(book_copy_params)

        if @book_copy.save
          render json: {
            book_copy: {
              id: @book_copy.id,
              book_serial_number: @book_copy.book_serial_number,
              available: @book_copy.available,
              book_id: @book_copy.book_id,
              book_title: @book.title,
              created_at: @book_copy.created_at,
              updated_at: @book_copy.updated_at
            },
            message: "Book copy created successfully"
          }, status: :created
        else
          render json: {
            errors: @book_copy.errors.full_messages,
            message: "Failed to create book copy"
          }, status: :unprocessable_content
        end
      end

      # PUT/PATCH /books/:book_id/book_copies/:id
      def update
        authorize @book_copy.book

        if @book_copy.update(book_copy_params.except(:available))
          render json: {
            book_copy: {
              id: @book_copy.id,
              book_serial_number: @book_copy.book_serial_number,
              available: @book_copy.available,
              book_id: @book_copy.book_id,
              created_at: @book_copy.created_at,
              updated_at: @book_copy.updated_at
            },
            message: "Book copy updated successfully"
          }
        else
          render json: {
            errors: @book_copy.errors.full_messages,
            message: "Failed to update book copy"
          }, status: :unprocessable_content
        end
      end

      # DELETE /books/:book_id/book_copies/:id
      def destroy
        authorize @book_copy.book

        # Check if there are active reservations
        if @book_copy.reservations.active.exists?
          render json: {
            errors: [ "Cannot delete book copy with active reservations" ],
            message: "Failed to delete book copy"
          }, status: :unprocessable_content
          return
        end

        if @book_copy.destroy
          render json: {
            message: "Book copy deleted successfully"
          }, status: :ok
        else
          render json: {
            errors: @book_copy.errors.full_messages,
            message: "Failed to delete book copy"
          }, status: :unprocessable_content
        end
      end

      private

      def filter_params
        params.permit(:title, :author, :genre).transform_values { |v| v.to_s.strip.presence }.compact
      end

      def set_book
        @book = Book.find(params[:book_id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Book not found",
          message: "The requested book does not exist"
        }, status: :not_found
      end

      def set_book_copy
        if params[:book_id]
          @book_copy = BookCopy.joins(:book).find_by(id: params[:id], book: { id: params[:book_id] })
        else
          @book_copy = BookCopy.find(params[:id])
        end

        unless @book_copy
          render json: {
            error: "Book copy not found",
            message: "The requested book copy does not exist"
          }, status: :not_found
        end
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Book copy not found",
          message: "The requested book copy does not exist"
        }, status: :not_found
      end

      def book_copy_params
        params.require(:book_copy).permit(:book_serial_number, :available)
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
