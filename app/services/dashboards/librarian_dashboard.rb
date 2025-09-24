module Dashboards
  class LibrarianDashboard
    def self.call
      # Use a single query to get all reservation counts
      reservation_stats = calculate_reservation_stats

      {
        total_books: total_books,
        total_borrowed_books: reservation_stats[:borrowed_count],
        books_due_today: reservation_stats[:due_today_count],
        overdue_members: overdue_members
      }
    end

    private

    # Cache the total books count since it does not change frequently
    def self.total_books
      Rails.cache.fetch("dashboard:librarian:total_books", expires_in: 1.hour) do
        BookCopy.count
      end
    end

    def self.calculate_reservation_stats
      Rails.cache.fetch("dashboard:librarian:reservation_stats:#{Date.current}", expires_in: 10.minutes) do
        today = Date.current

        # Use separate queries for better readability and safety
        borrowed_count = Reservation.active.count
        due_today_count = Reservation.active.due_date(today).count

        {
          borrowed_count: borrowed_count,
          due_today_count: due_today_count
        }
      end
    end

    def self.overdue_members
      Rails.cache.fetch("dashboard:librarian:overdue_members:#{Date.current}", expires_in: 10.minutes) do
        User.joins(:reservations)
            .where(role: :member)
            .where("reservations.return_date < ? AND reservations.returned_at IS NULL", Date.current)
            .select(:id, :name, :email)
            .distinct
            .limit(50) # Prevent large result sets
      end
    end
  end
end
