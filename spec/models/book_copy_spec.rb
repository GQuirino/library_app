require 'rails_helper'

RSpec.describe BookCopy, type: :model do
  let(:book) { create(:book) }
  let(:book_copy_available) { create(:book_copy, :available, book: book) }
  let(:book_copy_unavailable) { create(:book_copy, :unavailable, book: book) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(book_copy_available).to be_valid
    end

    it "is invalid without a book_serial_number" do
      book_copy_available.book_serial_number = nil
      expect(book_copy_available).not_to be_valid
    end

    it "is invalid with a non-unique book_serial_number" do
      BookCopy.create!(book: book, book_serial_number: "SN123", available: true)
      duplicate = BookCopy.new(book: book, book_serial_number: "SN123", available: true)
      expect(duplicate).not_to be_valid
    end

    it "is invalid if available is not true or false" do
      book_copy_available.available = nil
      expect(book_copy_available).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:copy1) { BookCopy.create!(book: book, book_serial_number: "SN1", available: true) }
    let!(:copy2) { BookCopy.create!(book: book, book_serial_number: "SN2", available: false) }


    it ".copies_for returns copies for a book" do
      expect(BookCopy.copies_for(book)).to match_array([ copy1, copy2 ])
    end

    it ".available returns available copies" do
      expect(BookCopy.available).to include(copy1)
      expect(BookCopy.available).not_to include(copy2)
    end

    it ".unavailable returns unavailable copies" do
      expect(BookCopy.unavailable).to include(copy2)
      expect(BookCopy.unavailable).not_to include(copy1)
    end
  end

  describe "#mark_available!" do
    it "marks the copy as available if no active reservations" do
      create(:reservation, :overdue, book_copy: book_copy_unavailable)

      expect { book_copy_unavailable.mark_available! }.to change { book_copy_unavailable.reload.available }.to(true)
      expect(book_copy_unavailable.errors[:base]).to be_empty
    end
  end

  describe "#mark_unavailable!" do
    before do
      BookCopy.create!(book: book, book_serial_number: "SN999", available: true)
    end

    it "marks the copy as unavailable if not the last available copy" do
      book_copy_available.update(available: true)

      expect { book_copy_available.mark_unavailable! }.to change { book_copy_available.reload.available }.to(false)
      expect(book_copy_available.errors[:base]).to be_empty
    end

    it "does not mark as unavailable if it is the last available copy" do
      BookCopy.where.not(id: book_copy_available.id).update_all(available: false)
      expect { book_copy_available.mark_unavailable! rescue nil }.not_to change { book_copy_available.reload.available }
      expect(book_copy_available.errors[:base]).to include("Cannot mark as unavailable while there are available copies")
    end
  end
end
