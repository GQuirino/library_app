class AddMissingIndexes < ActiveRecord::Migration[8.0]
  def change
    # Books table indexes for filtering and searching
    add_index :books, :title unless index_exists?(:books, :title)
    add_index :books, :author unless index_exists?(:books, :author)
    add_index :books, :genre unless index_exists?(:books, :genre)

    # Composite indexes for common filter combinations
    add_index :books, [ :author, :genre ] unless index_exists?(:books, [ :author, :genre ])
    add_index :books, [ :title, :author ] unless index_exists?(:books, [ :title, :author ])
    add_index :books, [ :genre, :year ] unless index_exists?(:books, [ :genre, :year ])

    # Book copies table indexes
    add_index :book_copies, :available unless index_exists?(:book_copies, :available)
    add_index :book_copies, [ :book_id, :available ] unless index_exists?(:book_copies, [ :book_id, :available ])

    # Reservations table indexes for common queries
    add_index :reservations, :return_date unless index_exists?(:reservations, :return_date)
    add_index :reservations, :returned_at unless index_exists?(:reservations, :returned_at)

    # Composite indexes for reservation queries
    add_index :reservations, [ :user_id, :returned_at ] unless index_exists?(:reservations, [ :user_id, :returned_at ])
    add_index :reservations, [ :book_copy_id, :returned_at ] unless index_exists?(:reservations, [ :book_copy_id, :returned_at ])
    add_index :reservations, [ :return_date, :returned_at ] unless index_exists?(:reservations, [ :return_date, :returned_at ])

    # Index for overdue reservations (where returned_at is null and return_date < current_date)
    unless index_exists?(:reservations, [ :returned_at, :return_date ])
      add_index :reservations, [ :returned_at, :return_date ]
    end

    # Index for active reservations (where returned_at is null)
    unless index_exists?(:reservations, :returned_at)
      add_index :reservations, :returned_at, where: "returned_at IS NULL"
    end
  end
end
