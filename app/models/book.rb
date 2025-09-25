class Book < ApplicationRecord
    has_many :book_copies, dependent: :destroy

    validates :title, :author, :publisher, :edition, :year, presence: true

    scope :filter_by, ->(column, value) do
      where(arel_table[column.to_sym].matches("%#{value}%"))
    end
end
