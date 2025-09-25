require 'swagger_helper'

RSpec.describe 'Reservations API', type: :request do
  path '/api/v1/reservations' do
    get('List Reservations') do
      tags 'Reservations'
      description 'Retrieve a list of reservations with optional filtering and pagination'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :user_id, in: :query, type: :integer, description: 'Filter by user ID', required: false
      parameter name: :book_copies, in: :query, type: :string, description: 'Filter by book copy', required: false
      parameter name: :book, in: :query, type: :string, description: 'Filter by book', required: false
      parameter name: :return_date_range, in: :query, type: :object,
                properties: { start: { type: :string, format: :date }, end: { type: :string, format: :date } },
                description: 'Filter by return date range (JSON format)',
                example: { start: '2023-01-01', end: '2023-01-31' },
                required: false
      parameter name: :overdue, in: :query, type: :string, description: 'Filter overdue reservations (true/false)', required: false
      parameter name: :page, in: :query, type: :integer, description: 'Page number for pagination', required: false
      parameter name: :per_page, in: :query, type: :integer, description: 'Number of items per page', required: false

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 reservations: {
                   type: :array,
                   items: { '$ref': '#/components/schemas/Reservation' }
                 },
                 meta: { '$ref': '#/components/schemas/PaginationMeta' },
                 filters: {
                   type: :object,
                   properties: {
                     user_id: { type: :integer },
                     book_copies: { type: :string },
                     book: { type: :string },
                     return_date_range: { type: :string },
                     overdue: { type: :string }
                   }
                 }
               }

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }

        before do
          create_list(:reservation, 5)
        end

        run_test!
      end
    end
  end

  path '/api/v1/reservations/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Reservation ID'

    get('Show Reservation') do
      tags 'Reservations'
      description 'Retrieve a specific reservation by ID'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(200, 'reservation found') do
        schema '$ref': '#/components/schemas/Reservation'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:id) { create(:reservation).id }

        run_test!
      end
    end
  end

  path '/api/v1/reservations/create' do
    post('Create Reservation') do
      tags 'Reservations'
      description 'Create a new book reservation'
      security [ bearerAuth: [] ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'
      parameter name: :reservation, in: :body, schema: {
        type: :object,
        properties: {
          reservation: {
            type: :object,
            properties: {
              book_copy_id: { type: :integer, example: 1 },
              user_id: { type: :integer, example: 1, description: 'Optional - defaults to current user' },
              return_date: { type: :string, format: :date, example: '2025-10-15' }
            },
            required: [ 'book_copy_id', 'return_date' ]
          }
        }
      }

      response(201, 'reservation created') do
        schema '$ref': '#/components/schemas/Reservation'

        let(:user) { create(:user, :member) }
        let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }
        let(:book_copy) { create(:book_copy, available: true) }
        let(:reservation) do
          {
            reservation: {
              book_copy_id: book_copy.id,
              return_date: (Date.current + 14.days).to_s
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user_id']).to eq(user.id)
          expect(data['book_copy_id']).to eq(book_copy.id)
        end
      end
    end
  end

  path '/api/v1/reservations/{id}/return' do
    parameter name: :id, in: :path, type: :integer, description: 'Reservation ID'

    patch('Return Book') do
      tags 'Reservations'
      description 'Mark a book as returned (librarians only)'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(200, 'book returned successfully') do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'Book returned successfully' }
               }

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }
        let(:book_copy) { create(:book_copy, available: false) }
        let(:id) do
          create(:reservation,
            book_copy: book_copy,
            returned_at: nil,
            return_date: Date.current + 7.days
          ).id
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Book returned successfully')
        end
      end
    end
  end
end
