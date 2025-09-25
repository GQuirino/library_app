class BookCopy < ApplicationRecord
  belongs_to :book
  has_many :reservations, dependent: :destroy

  validates :book_serial_number, presence: true, uniqueness: true
  validates :available, inclusion: { in: [ true, false ] }

  scope :copies_for, ->(book) { where(book:) }
  scope :available, -> { where(available: true) }
  scope :unavailable, -> { where(available: false) }

  def mark_available!
    update!(available: true)
  end

  def mark_unavailable!
    # Only mark unavailable if all copies are reserved
    if BookCopy.copies_for(self.book).available.count == 1
      errors.add(:base, "Cannot mark as unavailable while there are available copies")
    else
      update!(available: false)
    end
  end
end
