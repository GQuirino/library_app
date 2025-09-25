require 'swagger_helper'

RSpec.describe 'Book Copies API', type: :request do
  path '/api/v1/books/{book_id}/book_copies' do
    parameter name: :book_id, in: :path, type: :integer, description: 'Book ID'

    get('List Book Copies') do
      tags 'Book Copies'
      description 'Retrieve all copies of a specific book with optional filtering'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :page, in: :query, type: :integer, description: 'Page number for pagination', required: false
      parameter name: :per_page, in: :query, type: :integer, description: 'Number of items per page', required: false

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 book_copies: {
                   type: :array,
                   items: { '$ref': '#/components/schemas/BookCopy' }
                 },
                 meta: { '$ref': '#/components/schemas/PaginationMeta' }
               }

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book_id) { create(:book).id }

        before do
          create_list(:book_copy, 3, book_id: book_id)
        end

        run_test!
      end

      response(404, 'book not found') do
        schema '$ref': '#/components/schemas/Error'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book_id) { 999999 }

        run_test!
      end
    end

    post('Create Book Copy') do
      tags 'Book Copies'
      description 'Create a new copy of a book (librarians only)'
      security [ bearerAuth: [] ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :book_copy, in: :body, schema: {
        type: :object,
        properties: {
          book_copy: {
            type: :object,
            properties: {
              book_serial_number: { type: :string },
              available: { type: :boolean }
            }
          }
        }
      }

      response(201, 'book copy created') do
        schema '$ref': '#/components/schemas/BookCopy'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book_id) { create(:book).id }
        let(:book_copy) do
          {
            book_copy: {
              book_serial_number: 'BC001',
              available: true
            }
          }
        end

        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref': '#/components/schemas/UnauthorizedError'

        let(:member) { create(:user, :member) }
        let(:Authorization) { "Bearer #{generate_jwt_token(member)}" }
        let(:book_id) { create(:book).id }
        let(:book_copy) { { book_copy: { book_serial_number: 'BC004' } } }

        run_test!
      end
    end
  end

  path '/api/v1/books/{book_id}/book_copies/{id}' do
    parameter name: :book_id, in: :path, type: :integer, description: 'Book ID'
    parameter name: :id, in: :path, type: :integer, description: 'Book Copy ID'

    put('Update Book Copy') do
      tags 'Book Copies'
      description 'Update an existing book copy (librarians only)'
      security [ bearerAuth: [] ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :book_copy, in: :body, schema: {
        type: :object,
        properties: {
          book_copy: {
            type: :object,
            properties: {
              book_serial_number: { type: :string },
              available: { type: :boolean }
            }
          }
        }
      }

      response(200, 'book copy updated') do
        schema '$ref': '#/components/schemas/BookCopy'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book) { create(:book) }
        let(:book_id) { book.id }
        let(:id) { create(:book_copy, book: book).id }
        let(:book_copy) do
          {
            book_copy: {
              book_serial_number: 'BC003',
              available: false
            }
          }
        end

        run_test!
      end
    end

    delete('Delete Book Copy') do
      tags 'Book Copies'
      description 'Delete a book copy (librarians only)'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(204, 'book copy deleted') do
        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book) { create(:book) }
        let(:book_id) { book.id }
        let(:id) { create(:book_copy, book: book).id }

        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref': '#/components/schemas/UnauthorizedError'

        let(:member) { create(:user, :member) }
        let(:Authorization) { "Bearer #{generate_jwt_token(member)}" }
        let(:book) { create(:book) }
        let(:book_id) { book.id }
        let(:id) { create(:book_copy, book: book).id }

        run_test!
      end
    end
  end

  path '/api/v1/book_copies/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Book Copy ID'

    get('Show Book Copy') do
      tags 'Book Copies'
      description 'Retrieve a specific book copy by ID'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(200, 'book copy found') do
        schema '$ref': '#/components/schemas/BookCopy'

        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }
        let(:id) { create(:book_copy).id }

        run_test!
      end
    end
  end
end
