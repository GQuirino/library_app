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

  def self.due_today
    due_date(Date.current)
  end

  def mark_as_returned!
    book_copy.mark_available!
    update!(returned_at: Date.current)
  end

  def set_reservation_days(days = DEFAULT_RETURN_DAYS)
    self.return_date = Date.current + days.days
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
