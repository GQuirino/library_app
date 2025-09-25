module Dashboards
  class MemberDashboard
    def self.call(user)
      {
        active_not_overdue_reservations: active_not_overdue_reservations(user.id),
        active_overdue_reservations: active_overdue_reservations(user.id),
        recent_reservation_history: recent_reservation_history(user.id)
      }
    end

    private

    # Currently borrowed books (not returned)
    def self.active_not_overdue_reservations(user_id)
      Rails.cache.fetch("dashboard:member:current_books:#{user_id}:#{Date.current}", expires_in: 15.minutes) do
        Reservation.not_overdue
                   .for_user(user_id)
                   .select(
                     "reservations.id as id",
                     "reservations.return_date",
                     "book_copies.book_serial_number",
                     "books.title",
                     "books.author"
                   )
                   .joins(book_copy: :book)
                   .limit(20)
      end
    end

    # Overdue books for the user
    def self.active_overdue_reservations(user_id)
      Rails.cache.fetch("dashboard:member:overdue_books:#{user_id}:#{Date.current}", expires_in: 15.minutes) do
        Reservation.overdue
                   .for_user(user_id)
                   .select(
                     "reservations.id as id",
                     "reservations.return_date",
                     "book_copies.book_serial_number",
                     "books.title",
                     "books.author"
                   )
                   .joins(book_copy: :book)
                   .limit(20)
      end
    end

    # Recent reservation history (last 10 returned books)
    def self.recent_reservation_history(user_id)
      Rails.cache.fetch("dashboard:member:history:#{user_id}", expires_in: 1.hour) do
        Reservation.ended
                   .for_user(user_id)
                   .select(
                     "reservations.id as id",
                     "reservations.return_date",
                     "reservations.returned_at",
                     "book_copies.book_serial_number",
                     "books.title",
                     "books.author"
                   )
                   .joins(book_copy: :book)
                   .limit(10)
      end
    end

    # Total count of books ever borrowed
    def self.total_borrowed_count(user_id)
      Rails.cache.fetch("dashboard:member:total_count:#{user_id}", expires_in: 1.hour) do
        Reservation.where(user_id: user_id).count
      end
    end
  end
end
