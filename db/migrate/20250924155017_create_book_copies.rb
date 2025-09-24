class CreateBookCopies < ActiveRecord::Migration[8.0]
  def change
    create_table :book_copies do |t|
      t.references :book, null: false, foreign_key: true
      t.string :book_serial_number
      t.boolean :available

      t.timestamps
    end
  end
end
