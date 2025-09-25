class Book < ApplicationRecord
    has_many :book_copies, dependent: :destroy

    validates :title, :author, :publisher, :edition, :year, presence: true

    # Filter scopes
    scope :filter_by, ->(column, value) { where("#{column} ILIKE ?", "%#{value}%") }
end
