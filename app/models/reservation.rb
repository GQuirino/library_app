class Reservation < ApplicationRecord
  DEFAULT_RETURN_DAYS = 14

  belongs_to :book_copy
  belongs_to :user

  validates :book_copy, :user, presence: true
  validates :return_date, presence: true, comparison: { greater_than: Date.current, message: "must be in the future" }, if: :new_record?
  validate :book_copy_is_available, if: :new_record?

  before_create :mark_book_copy_unavailable!

  scope :active, -> { where(returned_at: nil) }
  scope :due_date, ->(date) { where(return_date: date) }
  scope :overdue, -> { active.where("return_date < ?", Date.current) }
  scope :not_overdue, -> { active.where("return_date >= ?", Date.current) }
  scope :for_user, ->(user_id) { where(user_id:) }
  scope :for_book_copy, ->(book_copy) { where(book_copy:) }
  scope :ended, -> { where.not(returned_at: nil) }
  scope :by_return_date_range, ->(start_date, end_date) { where(return_date: Date.parse(start_date)..Date.parse(end_date)) }
  scope :by_book, ->(book_id) { joins(book_copy: :book).where(books: { id: book_id }) }
  scope :filter_by, ->(column, value) { where(column => value) }

  def mark_as_returned!
    book_copy.mark_available!
    update!(returned_at: Date.current)
  end

  private

  def mark_book_copy_unavailable!
    book_copy&.mark_unavailable!
  end

  def book_copy_is_available
    return unless book_copy  # If book_copy is nil, validation doesn't run

    if Reservation.active.for_book_copy(book_copy).exists?
      errors.add(:book_copy, "is already reserved")
    end
  end
end
