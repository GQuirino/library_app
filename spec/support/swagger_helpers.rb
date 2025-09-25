module SwaggerHelpers
  def generate_jwt_token(user)
    # This helper generates a JWT token for testing purposes
    # You may need to adjust this based on your JWT implementation
    payload = {
      sub: user.id,
      scp: 'user',
      aud: nil,
      iat: Time.current.to_i,
      exp: (Time.current + 24.hours).to_i,
      jti: SecureRandom.uuid
    }

    JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY'])
  end
end

RSpec.configure do |config|
  config.include SwaggerHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
end
