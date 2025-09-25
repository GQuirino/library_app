require 'swagger_helper'

RSpec.describe 'Books API', type: :request do
  path '/api/v1/books' do
    get('List Books') do
      tags 'Books'
      description 'Retrieve a list of books with optional filtering and pagination'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :title, in: :query, type: :string, description: 'Filter by book title', required: false
      parameter name: :author, in: :query, type: :string, description: 'Filter by author name', required: false
      parameter name: :publisher, in: :query, type: :string, description: 'Filter by publisher', required: false
      parameter name: :genre, in: :query, type: :string, description: 'Filter by book genre', required: false
      parameter name: :page, in: :query, type: :integer, description: 'Page number for pagination', required: false
      parameter name: :per_page, in: :query, type: :integer, description: 'Number of items per page', required: false

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 books: {
                   type: :array,
                   items: { '$ref': '#/components/schemas/Book' }
                 },
                 meta: { '$ref': '#/components/schemas/PaginationMeta' },
                 filters: {
                   type: :object,
                   properties: {
                     title: { type: :string },
                     author: { type: :string },
                     publisher: { type: :string },
                     genre: { type: :string }
                   }
                 }
               }

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }

        before do
          create_list(:book, 5)
        end

        run_test!
      end
    end

    post('Create Book') do
      tags 'Books'
      description 'Create a new book (librarians only)'
      security [ bearerAuth: [] ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              title: { type: :string, example: 'The Ruby Programming Language' },
              author: { type: :string, example: 'Matz Yukihiro' },
              publisher: { type: :string, example: 'O\'Reilly Media' },
              edition: { type: :string, example: '1st Edition' },
              year: { type: :integer, example: 2008 },
              isbn: { type: :string, example: '978-0-596-51617-8' },
              genre: { type: :string, example: 'Programming' }
            },
            required: [ 'title', 'author', 'publisher', 'edition', 'year' ]
          }
        }
      }

      response(201, 'book created') do
        schema '$ref': '#/components/schemas/Book'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book) do
          {
            book: {
              title: 'Test Book',
              author: 'Test Author',
              publisher: 'Test Publisher',
              edition: '1st Edition',
              year: 2024,
              isbn: '978-0-123456-78-9',
              genre: 'Fiction'
            }
          }
        end

        run_test!
      end

      response(403, 'forbidden - members cannot create books') do
        schema '$ref': '#/components/schemas/UnauthorizedError'

        let(:member) { create(:user, :member) }
        let(:Authorization) { "Bearer #{generate_jwt_token(member)}" }
        let(:book) do
          {
            book: {
              title: 'Test Book',
              author: 'Test Author',
              publisher: 'Test Publisher',
              edition: '1st Edition',
              year: 2024
            }
          }
        end

        run_test!
      end

      response(422, 'validation errors') do
        schema '$ref': '#/components/schemas/BooksValidationError'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book) do
          {
            book: {
              title: '',
              author: '',
              publisher: '',
              edition: '',
              year: nil
            }
          }
        end
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }

        run_test!
      end
    end
  end

  path '/api/v1/books/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Book ID'

    get('Show Book') do
      tags 'Books'
      description 'Retrieve a specific book by ID'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(200, 'book found') do
        schema '$ref': '#/components/schemas/Book'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:id) { create(:book).id }

        run_test!
      end

      response(401, 'unauthorized') do
        schema '$ref': '#/components/schemas/UnauthorizedError'
        let(:Authorization) { nil }

        let(:id) { create(:book).id }

        run_test!
      end
    end

    put('Update Book') do
      tags 'Books'
      description 'Update an existing book (librarians only)'
      security [ bearerAuth: [] ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              title: { type: :string },
              author: { type: :string },
              publisher: { type: :string },
              edition: { type: :string },
              year: { type: :integer },
              isbn: { type: :string },
              genre: { type: :string }
            }
          }
        }
      }

      response(200, 'book updated') do
        schema '$ref': '#/components/schemas/Book'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:id) { create(:book).id }
        let(:book) do
          {
            book: {
              title: 'Updated Title'
            }
          }
        end

        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref': '#/components/schemas/UnauthorizedError'

        let(:member) { create(:user, :member) }
        let(:Authorization) { "Bearer #{generate_jwt_token(member)}" }
        let(:id) { create(:book).id }
        let(:book) { { book: { title: 'Updated Title' } } }

        run_test!
      end
    end

    delete('Delete Book') do
      tags 'Books'
      description 'Delete a book (librarians only)'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(200, 'book deleted') do
        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:id) { create(:book).id }

        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref': '#/components/schemas/UnauthorizedError'

        let(:member) { create(:user, :member) }
        let(:Authorization) { "Bearer #{generate_jwt_token(member)}" }
        let(:id) { create(:book).id }

        run_test!
      end
    end
  end
end
