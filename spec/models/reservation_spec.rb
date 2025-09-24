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
    let!(:overdue_returned) { create(:reservation, :active_with_overdue_date, user: user, book_copy: book_copy) }
    let!(:due_today) { create(:reservation, user: user, book_copy: book_copy, return_date: Date.today) }

    it 'returns active reservations' do
      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(returned)
    end

    it 'returns reservations for a user' do
      expect(described_class.for_user(user.id)).to include(active, returned, overdue)
    end

    it 'returns reservations for a book_copy' do
      expect(described_class.for_book_copy(book_copy)).to include(active, returned, overdue)
    end

    it 'returns reservations by due date' do
      expect(described_class.due_date(Date.today)).to include(due_today)
      expect(described_class.due_date(Date.today)).not_to include(active, returned, overdue)
    end

    describe '.overdue' do
      it 'returns only active reservations that are overdue' do
        overdue_reservations = described_class.overdue

        expect(overdue_reservations).to include(overdue_returned)
        expect(overdue_reservations).not_to include(overdue)
      end

      it 'does not include reservations due today' do
        expect(described_class.overdue).not_to include(due_today)
      end
    end

    describe '.not_overdue' do
      let!(:not_overdue_active) { create(:reservation, user: user, book_copy: create(:book_copy), return_date: Date.current + 2.days, returned_at: nil) }
      let!(:overdue_active) { create(:reservation, user: user, book_copy: create(:book_copy), return_date: Date.current - 1.day, returned_at: nil) }
      let!(:not_overdue_returned) { create(:reservation, user: user, book_copy: create(:book_copy), return_date: Date.current + 1.day, returned_at: Date.current) }

      it 'returns only active reservations that are not overdue' do
        not_overdue_reservations = described_class.not_overdue

        expect(not_overdue_reservations).to include(not_overdue_active)
        expect(not_overdue_reservations).not_to include(overdue_active) # overdue
        expect(not_overdue_reservations).not_to include(not_overdue_returned) # returned, so not active
      end

      it 'includes reservations due today' do
        today_reservation = create(:reservation, user: user, book_copy: create(:book_copy), return_date: Date.current, returned_at: nil)

        expect(described_class.not_overdue).to include(today_reservation)
      end

      it 'includes reservations due in the future' do
        future_reservation = create(:reservation, user: user, book_copy: create(:book_copy), return_date: Date.current + 5.days, returned_at: nil)

        expect(described_class.not_overdue).to include(future_reservation)
      end
    end

    describe 'scope combinations' do
      let!(:overdue_active) { create(:reservation, user: user, book_copy: create(:book_copy), return_date: Date.current - 1.day, returned_at: nil) }
      let!(:not_overdue_active) { create(:reservation, user: user, book_copy: create(:book_copy), return_date: Date.current + 1.day, returned_at: nil) }

      it 'overdue and not_overdue scopes are mutually exclusive for active reservations' do
        all_active = described_class.active
        overdue_count = described_class.overdue.count
        not_overdue_count = described_class.not_overdue.count

        expect(overdue_count + not_overdue_count).to eq(all_active.count)
      end

      it 'can chain scopes with for_user' do
        other_user = create(:user, :member)
        other_user_overdue = create(:reservation, user: other_user, book_copy: create(:book_copy), return_date: Date.current - 1.day, returned_at: nil)

        user_overdue = described_class.for_user(user.id).overdue
        expect(user_overdue).to include(overdue_active)
        expect(user_overdue).not_to include(other_user_overdue)
      end
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
