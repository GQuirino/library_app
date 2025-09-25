# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Library Management API',
        version: 'v1',
        description: 'A comprehensive API for managing library operations including books, book copies, reservations, and user management.',
        contact: {
          name: 'Library API Team',
          email: 'api-support@library.com'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'JWT token for authentication. Include the token in the Authorization header with "Bearer " prefix.'
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              email: { type: :string, format: :email, example: 'user@example.com' },
              name: { type: :string, example: 'John Doe' },
              address: {
                type: :object,
                properties: {
                  street: { type: :string, example: '123 Main St' },
                  city: { type: :string, example: 'Anytown' },
                  state: { type: :string, example: 'CA' },
                  zip: { type: :string, example: '12345' }
                }
              },
              role: {
                type: :string,
                enum: [ 'member', 'librarian' ],
                example: 'member',
                description: 'User role in the library system'
              },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: [ 'id', 'email', 'name', 'role' ]
          },
          Book: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              title: { type: :string, example: 'The Ruby Programming Language' },
              author: { type: :string, example: 'Matz Yukihiro' },
              publisher: { type: :string, example: 'O\'Reilly Media' },
              edition: { type: :string, example: '1st Edition' },
              year: { type: :integer, example: 2008 },
              isbn: { type: :string, example: '978-0-596-51617-8' },
              genre: { type: :string, example: 'Programming' },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: [ 'id', 'title', 'author', 'publisher', 'edition', 'year' ]
          },
          BookCopy: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              book_id: { type: :integer, example: 1 },
              available: { type: :boolean, example: true },
              condition: {
                type: :string,
                enum: [ 'excellent', 'good', 'fair', 'poor' ],
                example: 'good'
              },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: [ 'id', 'book_id', 'available' ]
          },
          Reservation: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              user_id: { type: :integer, example: 1 },
              book_copy_id: { type: :integer, example: 1 },
              return_date: { type: :string, format: :date, example: '2025-10-15' },
              returned_at: { type: :string, format: 'date-time', nullable: true },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: [ 'id', 'user_id', 'book_copy_id', 'return_date' ]
          },
          Dashboard: {
            type: :object,
            properties: {
              total_books: { type: :integer, example: 150 },
              available_books: { type: :integer, example: 120 },
              borrowed_books: { type: :integer, example: 30 },
              overdue_books: { type: :integer, example: 5 },
              total_reservations: { type: :integer, example: 45 },
              active_reservations: { type: :integer, example: 30 },
              users_with_overdue_books: {
                type: :array,
                items: { '$ref': '#/components/schemas/User' }
              }
            }
          },
          ErrorLogout: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: { type: :string },
                example: [ 'User has no active session.' ]
              }
            }
          },
          Error: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: { type: :string },
                example: [ 'Email has already been taken' ]
              }
            }
          },
          UnauthorizedError: {
            type: :object,
            properties: {
              message: { type: :string, example: 'Not authorized' }
            }
          },
          ValidationError: {
            type: :object,
            properties: {
              message: { type: :string, example: 'Validation failed' },
              errors: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: { type: :string }
                },
                example: {
                  email: [ 'has already been taken' ],
                  password: [ 'is too short (minimum is 6 characters)' ]
                }
              }
            }
          },
          PaginationMeta: {
            type: :object,
            properties: {
              current_page: { type: :integer, example: 1 },
              next_page: { type: :integer, nullable: true, example: 2 },
              prev_page: { type: :integer, nullable: true, example: nil },
              total_pages: { type: :integer, example: 5 },
              total_count: { type: :integer, example: 100 }
            }
          }
        }
      },
      security: [
        { bearerAuth: [] }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
