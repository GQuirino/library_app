module Api
  module V1
    class BooksController < ::ApplicationController
      before_action :authenticate_user!
      before_action :set_book, only: [ :show, :update, :destroy ]

      # GET /books
      def index
        authorize Book

        @books = Book.includes(:book_copies)

        # Apply filters
        filter_params.each do |key, value|
          @books = @books.filter_by(key, value)
        end

        @books = @books.page(params[:page])
                      .per(params[:per_page] || 20)
                      .order(:title)

        render json: {
          books: @books.map do |book|
            {
              id: book.id,
              title: book.title,
              author: book.author,
              publisher: book.publisher,
              isbn: book.isbn,
              genre: book.genre,
              edition: book.edition,
              year: book.year,
              total_copies: book.book_copies.count,
              available_copies: book.book_copies.available.count,
              created_at: book.created_at,
              updated_at: book.updated_at
            }
          end,
          meta: pagination_meta(@books),
          filters: filter_params
        }
      end

      # GET /books/:id
      def show
        authorize @book

        render json: {
          book: {
            id: @book.id,
            title: @book.title,
            author: @book.author,
            publisher: @book.publisher,
            isbn: @book.isbn,
            genre: @book.genre,
            edition: @book.edition,
            year: @book.year,
            created_at: @book.created_at,
            updated_at: @book.updated_at,
            book_copies: @book.book_copies.map do |copy|
              {
                id: copy.id,
                book_serial_number: copy.book_serial_number,
                available: copy.available,
                created_at: copy.created_at,
                updated_at: copy.updated_at
              }
            end
          }
        }
      end

      # POST /books
      def create
        authorize Book
        @book = Book.new(book_params)

        if @book.save
          render json: {
            book: {
              id: @book.id,
              title: @book.title,
              author: @book.author,
              publisher: @book.publisher,
              isbn: @book.isbn,
              genre: @book.genre,
              edition: @book.edition,
              year: @book.year,
              created_at: @book.created_at,
              updated_at: @book.updated_at
            },
            message: "Book created successfully"
          }, status: :created
        else
          render json: {
            errors: @book.errors.full_messages,
            message: "Failed to create book"
          }, status: :unprocessable_content
        end
      end

      # PUT/PATCH /books/:id
      def update
        authorize @book

        if @book.update(book_params)
          render json: {
            book: {
              id: @book.id,
              title: @book.title,
              author: @book.author,
              publisher: @book.publisher,
              isbn: @book.isbn,
              genre: @book.genre,
              edition: @book.edition,
              year: @book.year,
              created_at: @book.created_at,
              updated_at: @book.updated_at
            },
            message: "Book updated successfully"
          }
        else
          render json: {
            errors: @book.errors.full_messages,
            message: "Failed to update book"
          }, status: :unprocessable_content
        end
      end

      # DELETE /books/:id
      def destroy
        authorize @book

        if Reservation.active.for_book_copy(@book.book_copies).exists?
          render json: {
            errors: [ "Cannot delete book with active reservations" ],
            message: "Failed to delete book"
          }, status: :unprocessable_content
          return
        end

        if @book.destroy
          render json: {
            message: "Book deleted successfully"
          }, status: :ok
        else
          render json: {
            errors: @book.errors.full_messages,
            message: "Failed to delete book"
          }, status: :unprocessable_content
        end
      end

      private

      def set_book
        @book = Book.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Book not found",
          message: "The requested book does not exist"
        }, status: :not_found
      end

      def book_params
        params.require(:book).permit(:title, :author, :publisher, :edition, :year, :isbn, :genre)
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

      def filter_params
        params.permit(:title, :author, :genre).transform_values{ |v| v.to_s.strip.presence }.compact
      end
    end
  end
end
