class AddIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :book_copies, :book_serial_number, unique: true
  end
end
