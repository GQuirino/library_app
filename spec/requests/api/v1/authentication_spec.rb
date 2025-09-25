require 'swagger_helper'

RSpec.describe 'Authentication API', type: :request do
  path '/login' do
    post('User Login') do
      tags 'Authentication'
      description 'Authenticate user and receive JWT token'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: 'user@example.com' },
              password: { type: :string, example: 'password123' }
            },
            required: [ 'email', 'password' ]
          }
        }
      }

      response(200, 'successful login') do
        schema type: :object,
               properties: {
                 status: {
                   type: :object,
                   properties: {
                     code: { type: :integer, example: 200 },
                     message: { type: :string, example: 'Logged in successfully.' }
                   }
                 },
                 data: {
                   type: :object,
                   properties: {
                     user: { '$ref': '#/components/schemas/User' }
                   }
                 }
               }

        let(:user) { { user: { email: 'test@example.com', password: 'password' } } }
        let(:Authorization) {  }

        before do
          create(:user, email: 'test@example.com', password: 'password')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(response.status).to eq(200)
          expect(data['token']).to be_present
          expect(data['user']).to be_present
        end
      end

      response(401, 'invalid credentials') do
        schema '$ref': '#/components/schemas/Error'

        let(:user) { { user: { email: 'wrong@example.com', password: 'wrongpassword' } } }
        let(:Authorization) { }

        run_test!
      end

      response(401, 'invalid parameters') do
        schema '$ref': '#/components/schemas/UserValidationError'

        let(:user) { { user: { email: '', password: '' } } }
        let(:Authorization) { }

        run_test!
      end
    end
  end

  path '/logout' do
    delete('User Logout') do
      tags 'Authentication'
      description 'Logout user and invalidate JWT token'
      security [ bearerAuth: [] ]
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, description: 'Bearer token for authentication'

      response(200, 'successful logout') do
        schema type: :object,
               properties: {
                 status: {
                   type: :object,
                   properties: {
                     code: { type: :integer, example: 200 },
                     message: { type: :string, example: 'Logged out successfully.' }
                   }
                 }
               }

        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }

        run_test!
      end
    end
  end

  path '/signup' do
    post('User Registration') do
      tags 'Authentication'
      description 'Register a new user account'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: 'newuser@example.com' },
              password: { type: :string, example: 'password123' },
              password_confirmation: { type: :string, example: 'password123' },
              name: { type: :string, example: 'John Doe' },
              birthdate: { type: :string, format: :date, example: '1990-01-01' },
              address: { type: :object, example: { street: '123 Main St', city: 'Anytown', state: 'CA', zip: '12345' } },
              phone_number: { type: :string, example: '555-123-4567' }
            },
            required: [ 'email', 'password', 'password_confirmation', 'name', 'birthdate', 'address', 'phone_number' ]
          }
        }
      }

      response(201, 'successful registration') do
        schema type: :object,
               properties: {
                 status: {
                   type: :object,
                   properties: {
                     code: { type: :integer, example: 201 },
                     message: { type: :string, example: 'Signed up successfully.' }
                   }
                 },
                 data: {
                   type: :object,
                   properties: {
                     user: { '$ref': '#/components/schemas/User' }
                   }
                 }
               }

        let(:user) do
          {
            user: {
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              name: 'John Doe',
              birthdate: '1990-01-01',
              address: { street: '123 Main St', city: 'Anytown', state: 'CA', zip: '12345' },
              phone_number: '555-123-4567'
            }
          }
        end
        let(:Authorization) { }

        run_test!
      end

      response(422, 'validation errors') do
        schema '$ref': '#/components/schemas/UserValidationError'

        let(:user) do
          {
            user: {
              email: '',
              password: '',
              password_confirmation: ''
            }
          }
        end
        let(:Authorization) { }


        run_test!
      end
    end
  end
end
