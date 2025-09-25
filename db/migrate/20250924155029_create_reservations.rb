class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations do |t|
      t.references :book_copy, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :return_date
      t.date :returned_at

      t.timestamps
    end
  end
end
