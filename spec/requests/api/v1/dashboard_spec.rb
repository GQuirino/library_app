require 'swagger_helper'

RSpec.describe 'Dashboard API', type: :request do
  path '/api/v1/dashboard' do
    get('Get Dashboard Data') do
      tags 'Dashboard'
      description 'Retrieve dashboard statistics and data based on user role'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(200, 'successful - librarian dashboard') do
        schema '$ref': '#/components/schemas/Dashboard'

        let(:librarian) { create(:user, :librarian) }
        let(:Authorization) { "Bearer #{generate_jwt_token(librarian)}" }

        before do
          # Create test data
          create_list(:book, 5)
          create_list(:reservation, 3, :active)
          create_list(:reservation, 2, :overdue)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('total_books')
          expect(data).to have_key('active_reservations')
        end
      end

      response(200, 'successful - member dashboard') do
        schema type: :object,
               properties: {
                 user_reservations: {
                   type: :array,
                   items: { '$ref': '#/components/schemas/Reservation' }
                 },
                 active_count: { type: :integer, example: 2 },
                 overdue_count: { type: :integer, example: 1 }
               }

        let(:member) { create(:user, :member) }
        let(:Authorization) { "Bearer #{generate_jwt_token(member)}" }

        before do
          create_list(:reservation, 2, user: member, returned_at: nil)
        end

        run_test!
      end
    end
  end
end
