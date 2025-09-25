# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_25_024245) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "book_copies", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.string "book_serial_number"
    t.boolean "available"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available"], name: "index_book_copies_on_available"
    t.index ["book_id", "available"], name: "index_book_copies_on_book_id_and_available"
    t.index ["book_id"], name: "index_book_copies_on_book_id"
    t.index ["book_serial_number"], name: "index_book_copies_on_book_serial_number", unique: true
  end

  create_table "books", force: :cascade do |t|
    t.string "title"
    t.string "author"
    t.string "publisher"
    t.string "edition"
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "isbn"
    t.string "genre"
    t.index ["author", "genre"], name: "index_books_on_author_and_genre"
    t.index ["author"], name: "index_books_on_author"
    t.index ["genre", "year"], name: "index_books_on_genre_and_year"
    t.index ["genre"], name: "index_books_on_genre"
    t.index ["title", "author"], name: "index_books_on_title_and_author"
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "book_copy_id", null: false
    t.bigint "user_id", null: false
    t.date "return_date"
    t.date "returned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_copy_id", "returned_at"], name: "index_reservations_on_book_copy_id_and_returned_at"
    t.index ["book_copy_id"], name: "index_reservations_on_book_copy_id"
    t.index ["return_date", "returned_at"], name: "index_reservations_on_return_date_and_returned_at"
    t.index ["return_date"], name: "index_reservations_on_return_date"
    t.index ["returned_at", "return_date"], name: "index_reservations_on_returned_at_and_return_date"
    t.index ["returned_at"], name: "index_reservations_on_returned_at"
    t.index ["user_id", "returned_at"], name: "index_reservations_on_user_id_and_returned_at"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 1, null: false
    t.string "name"
    t.date "birthdate"
    t.jsonb "address", default: {}
    t.string "phone_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "book_copies", "books"
  add_foreign_key "reservations", "book_copies"
  add_foreign_key "reservations", "users"
end
