class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  # Default Role is 'member'
  enum :role, { librarian: 0, member: 1 }

  has_many :reservations, dependent: :destroy

  validates :name, :birthdate, :address, :phone_number, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validate :address_format

  scope :librarians, -> { where(role: :librarian) }
  scope :members, -> { where(role: :member) }
  scope :with_open_reservations, -> { joins(:reservations).where(reservations: { returned_at: nil }) }
  scope :with_overdue_reservations, -> { joins(:reservations).where("reservations.return_date < ? AND reservations.returned_at IS NULL", Date.today) }

  private

  def address_format
    required_keys = %w[street city zip state]
    errors.add(:address, "must be a hash") unless address.is_a?(Hash)
    errors.add(:address, "can't be blank") if address.blank?
    return if errors.any?

    missing_keys = required_keys - address.keys.map(&:to_s)
    errors.add(:address, "must contain the keys: #{missing_keys.join(', ')}") if missing_keys.any?
  end
end
