class Reservation < ApplicationRecord
  DEFAULT_RETURN_DAYS = 14

  belongs_to :book_copy
  belongs_to :user

  validates :book_copy, :user, presence: true
  validates :return_date, presence: true

  before_create :mark_book_copy_unavailable!

  scope :active, -> { where(returned_at: nil) }
  scope :overdue, -> { where('return_date < ? AND return_date IS NULL', Date.today) }
  scope :for_user, ->(user) { where(user:) }
  scope :for_book_copy, ->(book_copy) { where(book_copy:) }

  def mark_as_returned!
    book_copy.mark_available!
    update!(returned_at: Date.today)
  end

  def set_reservation_days(days = DEFAULT_RETURN_DAYS)
    self.return_date = Date.today + days.days
  end

  private

  def mark_book_copy_unavailable!
    book_copy&.mark_unavailable!
  end
end
