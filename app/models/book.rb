class Book < ApplicationRecord
    has_many :book_copies, dependent: :destroy

    validates :title, :author, :publisher, :edition, :year, presence: true
end
