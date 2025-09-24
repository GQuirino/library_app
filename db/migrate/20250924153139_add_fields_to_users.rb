class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :birthdate, :date
    add_column :users, :address, :jsonb, default: {}
    add_column :users, :phone_number, :string
  end
end
