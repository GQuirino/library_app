class AddFieldsToBooks < ActiveRecord::Migration[8.0]
  def change
    change_table :books do |t|
      t.string :isbn
      t.string :genre
    end
  end
end
