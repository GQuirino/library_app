require 'rails_helper'

RSpec.describe Reservation, type: :model do
  let!(:user) { create(:user, :member) }
  let!(:book_copy) { create(:book_copy, :available) }
  let(:reservation) { described_class.new(user: user, book_copy: book_copy) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      reservation.set_reservation_days
      expect(reservation).to be_valid
    end

    it 'is invalid without a user' do
      reservation.user = nil
      reservation.set_reservation_days
      expect(reservation).not_to be_valid
    end

    it 'is invalid without a book_copy' do
      reservation.book_copy = nil
      reservation.set_reservation_days
      expect(reservation).not_to be_valid
    end

    it 'is invalid without a return_date' do
      expect(reservation).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:active) { create(:reservation, :open, user: user, book_copy: book_copy) }
    let!(:returned) { create(:reservation, :returned, user: user, book_copy: book_copy) }
    let!(:overdue) { create(:reservation, :overdue, user: user, book_copy: book_copy) }

    it 'returns active reservations' do
      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(returned)
    end

    it 'returns reservations for a user' do
      expect(described_class.for_user(user)).to include(active, returned, overdue)
    end

    it 'returns reservations for a book_copy' do
      expect(described_class.for_book_copy(book_copy)).to include(active, returned, overdue)
    end
  end

  describe '#set_reservation_days' do
    it 'sets the return_date to DEFAULT_RETURN_DAYS from today by default' do
      reservation.set_reservation_days
      expect(reservation.return_date).to eq(Date.today + Reservation::DEFAULT_RETURN_DAYS.days)
    end

    it 'sets the return_date to custom days from today' do
      reservation.set_reservation_days(5)
      expect(reservation.return_date).to eq(Date.today + 5.days)
    end
  end

  describe '#mark_as_returned!' do
    it 'marks the book_copy as available and sets returned_at' do
      reservation.set_reservation_days
      reservation.save!
      expect(book_copy).to receive(:mark_available!)
      reservation.mark_as_returned!
      expect(reservation.returned_at).to eq(Date.today)
    end
  end

  describe 'callbacks' do
    it 'marks book_copy as unavailable before create' do
      expect(book_copy).to receive(:mark_unavailable!)
      reservation.set_reservation_days
      reservation.save!
    end
  end
end
