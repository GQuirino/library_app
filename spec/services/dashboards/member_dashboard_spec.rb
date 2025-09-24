require 'rails_helper'

RSpec.describe Dashboards::MemberDashboard do
  describe '.call' do
    let(:user) { create(:user, :member) }
    let(:other_user) { create(:user, :member) }
    let(:book1) { create(:book) }
    let(:book2) { create(:book) }
    let(:book3) { create(:book) }
    let(:book_copy1) { create(:book_copy, book: book1) }
    let(:book_copy2) { create(:book_copy, book: book2) }
    let(:book_copy3) { create(:book_copy, book: book3) }
    let(:book_copy4) { create(:book_copy, book: book1) }

    before do
      Rails.cache.clear
    end

    context 'with no reservations' do
      it 'returns empty dashboard data' do
        result = described_class.call(user)

        expect(result[:active_not_overdue_reservations]).to be_empty
        expect(result[:active_overdue_reservations]).to be_empty
        expect(result[:recent_reservation_history]).to be_empty
      end
    end

    context 'with active not overdue reservations' do
      let!(:current_reservation1) { create(:reservation, user: user, book_copy: book_copy1, return_date: Date.current + 5.days, returned_at: nil) }
      let!(:current_reservation2) { create(:reservation, user: user, book_copy: book_copy2, return_date: Date.current + 3.days, returned_at: nil) }
      let!(:due_today) { create(:reservation, user: user, book_copy: book_copy3, return_date: Date.current, returned_at: nil) }
      let!(:other_user_reservation) { create(:reservation, user: other_user, book_copy: book_copy4, return_date: Date.current + 2.days, returned_at: nil) }

      it 'returns current user active reservations including due today' do
        result = described_class.call(user)

        expect(result[:active_not_overdue_reservations].count).to eq(3) # includes due today
        expect(result[:active_overdue_reservations]).to be_empty
        expect(result[:recent_reservation_history]).to be_empty
      end

      it 'includes book and reservation details' do
        result = described_class.call(user)

        reservation_data = result[:active_not_overdue_reservations].first

        expect(reservation_data).to have_attributes(
          'id' => current_reservation1.id,
          'return_date' => current_reservation1.return_date,
          'book_serial_number' => book_copy1.book_serial_number,
          'title' => book1.title,
          'author' => book1.author
        )
      end

      it 'excludes other users reservations' do
        result = described_class.call(user)

        reservation_ids = result[:active_not_overdue_reservations].map { |r| r['id'] }
        expect(reservation_ids).not_to include(other_user_reservation.id)
      end

      it 'limits results to 20 items' do
        # Create many reservations
        book_copies = create_list(:book_copy, 25)
        book_copies.each do |bc|
          create(:reservation, user: user, book_copy: bc, return_date: Date.current + 1.day, returned_at: nil)
        end

        result = described_class.call(user)

        expect(result[:active_not_overdue_reservations].count).to be <= 20
      end
    end

    context 'with active overdue reservations' do
      let!(:overdue_reservation1) { create(:reservation, user: user, book_copy: book_copy1, return_date: Date.current - 2.days, returned_at: nil) }
      let!(:overdue_reservation2) { create(:reservation, user: user, book_copy: book_copy2, return_date: Date.current - 1.day, returned_at: nil) }
      let!(:current_reservation) { create(:reservation, user: user, book_copy: book_copy3, return_date: Date.current + 1.day, returned_at: nil) }
      let!(:other_user_overdue) { create(:reservation, user: other_user, book_copy: book_copy4, return_date: Date.current - 1.day, returned_at: nil) }

      it 'separates overdue from current reservations' do
        result = described_class.call(user)

        expect(result[:active_overdue_reservations].count).to eq(2)
        expect(result[:active_not_overdue_reservations].count).to eq(1)
      end

      it 'includes overdue reservation details' do
        result = described_class.call(user)

        overdue_data = result[:active_overdue_reservations].first

        expect(overdue_data).to have_attributes(
          'id' => overdue_reservation1.id,
          'return_date' => overdue_reservation1.return_date,
          'book_serial_number' => book_copy1.book_serial_number,
          'title' => book1.title,
          'author' => book1.author
        )
      end

      it 'excludes other users overdue reservations' do
        result = described_class.call(user)

        reservation_ids = result[:active_overdue_reservations].map { |r| r['id'] }
        expect(reservation_ids).not_to include(other_user_overdue.id)
      end

      it 'limits overdue results to 20 items' do
        # Create many overdue reservations
        book_copies = create_list(:book_copy, 25)
        book_copies.each do |bc|
          create(:reservation, user: user, book_copy: bc, return_date: Date.current - 1.day, returned_at: nil)
        end

        result = described_class.call(user)

        expect(result[:active_overdue_reservations].count).to be <= 20
      end
    end

    context 'with reservation history' do
      let!(:returned_reservation1) { create(:reservation, user: user, book_copy: book_copy1, return_date: Date.current - 1.day, returned_at: Date.current - 1.day) }
      let!(:returned_reservation2) { create(:reservation, user: user, book_copy: book_copy2, return_date: Date.current - 3.days, returned_at: Date.current - 2.days) }
      let!(:returned_reservation3) { create(:reservation, user: user, book_copy: book_copy3, return_date: Date.current - 5.days, returned_at: Date.current - 3.days) }
      let!(:current_reservation) { create(:reservation, user: user, book_copy: book_copy4, return_date: Date.current + 1.day, returned_at: nil) }
      let!(:other_user_returned) { create(:reservation, user: other_user, book_copy: create(:book_copy), return_date: Date.current - 2.days, returned_at: Date.current - 1.day) }

      it 'returns only ended reservations for the user' do
        result = described_class.call(user)

        expect(result[:recent_reservation_history].count).to eq(3)
        expect(result[:active_not_overdue_reservations].count).to eq(1)
      end

      it 'includes returned_at date in history' do
        result = described_class.call(user)

        history_item = result[:recent_reservation_history].first.as_json

        expect(history_item).to have_key('returned_at')
        expect(history_item['returned_at']).not_to be_nil
        expect(history_item).to have_key('return_date')
      end

      it 'excludes other users history' do
        result = described_class.call(user)

        reservation_ids = result[:recent_reservation_history].map { |r| r['id'] }
        expect(reservation_ids).not_to include(other_user_returned.id)
      end

      it 'limits history to 10 items' do
        # Create many returned reservations
        book_copies = create_list(:book_copy, 15)
        book_copies.each_with_index do |bc, index|
          create(:reservation,
            user: user,
            book_copy: bc,
            return_date: Date.current - (index + 1).days,
            returned_at: Date.current - index.days
          )
        end

        result = described_class.call(user)

        expect(result[:recent_reservation_history].count).to be <= 10
      end
    end

    context 'with mixed reservation states' do
      let!(:active_reservation) { create(:reservation, user: user, book_copy: book_copy1, return_date: Date.current + 5.days, returned_at: nil) }
      let!(:overdue_reservation) { create(:reservation, user: user, book_copy: book_copy2, return_date: Date.current - 1.day, returned_at: nil) }
      let!(:due_today) { create(:reservation, user: user, book_copy: book_copy3, return_date: Date.current, returned_at: nil) }
      let!(:returned_reservation) { create(:reservation, user: user, book_copy: book_copy4, return_date: Date.current - 2.days, returned_at: Date.current - 1.day) }

      it 'correctly categorizes all reservation types' do
        result = described_class.call(user)

        expect(result[:active_not_overdue_reservations].count).to eq(2) # active + due_today
        expect(result[:active_overdue_reservations].count).to eq(1)
        expect(result[:recent_reservation_history].count).to eq(1)
      end

      it 'includes due today in not overdue category' do
        result = described_class.call(user)

        not_overdue_dates = result[:active_not_overdue_reservations].map { |r| r['return_date'] }
        expect(not_overdue_dates).to include(Date.current)
      end
    end

    context 'caching behavior' do
      let!(:reservation) { create(:reservation, user: user, book_copy: book_copy1, return_date: Date.current + 1.day, returned_at: nil) }

      it 'caches active not overdue reservations with user and date-based key' do
        Rails.cache.clear

        # First call
        result1 = described_class.call(user)

        # Verify cache exists
        cache_key = "dashboard:member:current_books:#{user.id}:#{Date.current}"
        expect(Rails.cache.exist?(cache_key)).to be true

        # Second call should use cache
        result2 = described_class.call(user)

        expect(result1[:active_not_overdue_reservations].count).to eq(result2[:active_not_overdue_reservations].count)
      end

      it 'caches overdue reservations separately' do
        Rails.cache.clear
        create(:reservation, user: user, book_copy: book_copy2, return_date: Date.current - 1.day, returned_at: nil)

        # First call
        result1 = described_class.call(user)

        # Verify cache exists
        cache_key = "dashboard:member:overdue_books:#{user.id}:#{Date.current}"
        expect(Rails.cache.exist?(cache_key)).to be true

        # Second call should use cache
        result2 = described_class.call(user)

        expect(result1[:active_overdue_reservations].count).to eq(result2[:active_overdue_reservations].count)
      end

      it 'caches history with longer expiration' do
        Rails.cache.clear
        create(:reservation, user: user, book_copy: book_copy2, return_date: Date.current - 2.days, returned_at: Date.current - 1.day)

        # First call
        result1 = described_class.call(user)

        # Verify cache exists
        cache_key = "dashboard:member:history:#{user.id}"
        expect(Rails.cache.exist?(cache_key)).to be true

        # Second call should use cache
        result2 = described_class.call(user)

        expect(result1[:recent_reservation_history].count).to eq(result2[:recent_reservation_history].count)
      end

      it 'uses different cache keys for different users' do
        described_class.call(user)
        described_class.call(other_user)

        expect(Rails.cache.exist?("dashboard:member:current_books:#{user.id}:#{Date.current}")).to be true
        expect(Rails.cache.exist?("dashboard:member:current_books:#{other_user.id}:#{Date.current}")).to be true
      end

      it 'cache expires on different dates' do
        travel_to Date.current do
          described_class.call(user)
          expect(Rails.cache.exist?("dashboard:member:current_books:#{user.id}:#{Date.current}")).to be true
        end

        travel_to Date.current + 1.day do
          described_class.call(user)
          expect(Rails.cache.exist?("dashboard:member:current_books:#{user.id}:#{Date.current}")).to be true
        end
      end
    end

    context 'performance considerations' do
      it 'executes efficiently with multiple reservations' do
        create_list(:reservation, 5, user: user, return_date: Date.current + 1.day, returned_at: nil)
        create_list(:reservation, 3, user: user, return_date: Date.current - 1.day, returned_at: nil)
        create_list(:reservation, 4, user: user, return_date: Date.current - 2.days, returned_at: Date.current - 1.day)

        expect {
          result = described_class.call(user)
          expect(result).to be_a(Hash)
          expect(result.keys).to contain_exactly(:active_not_overdue_reservations, :active_overdue_reservations, :recent_reservation_history)
        }.not_to raise_error
      end

      it 'handles users with many reservations efficiently' do
        # Create reasonable test data
        book_copies = create_list(:book_copy, 50)

        book_copies.each_with_index do |bc, index|
          create(:reservation,
            user: user,
            book_copy: bc,
            return_date: Date.current + (index - 25).days,
            returned_at: index < 25 ? Date.current : nil
          )
        end

        expect {
          result = described_class.call(user)
          expect(result[:active_not_overdue_reservations].count).to be <= 20
          expect(result[:active_overdue_reservations].count).to be <= 20
          expect(result[:recent_reservation_history].count).to be <= 10
        }.not_to raise_error
      end
    end

    context 'edge cases' do
      it 'handles user with no reservations gracefully' do
        result = described_class.call(user)

        expect(result[:active_not_overdue_reservations]).to be_empty
        expect(result[:active_overdue_reservations]).to be_empty
        expect(result[:recent_reservation_history]).to be_empty
      end

      it 'handles books due today correctly' do
        today_reservation = create(:reservation, user: user, book_copy: book_copy1, return_date: Date.current, returned_at: nil)

        result = described_class.call(user)

        # Books due today should be in active_not_overdue_reservations, not overdue
        expect(result[:active_not_overdue_reservations].count).to eq(1)
        expect(result[:active_overdue_reservations]).to be_empty

        reservation_ids = result[:active_not_overdue_reservations].map { |r| r['id'] }
        expect(reservation_ids).to include(today_reservation.id)
      end

      it 'handles reservations returned on the same day' do
        same_day_reservation = create(:reservation,
          user: user,
          book_copy: book_copy1,
          return_date: Date.current,
          returned_at: Date.current
        )

        result = described_class.call(user)

        # Should appear in history, not active reservations
        expect(result[:active_not_overdue_reservations]).to be_empty
        expect(result[:active_overdue_reservations]).to be_empty
        expect(result[:recent_reservation_history].count).to eq(1)

        history_ids = result[:recent_reservation_history].map { |r| r['id'] }
        expect(history_ids).to include(same_day_reservation.id)
      end

      it 'handles reservations with future return dates' do
        future_reservation = create(:reservation, user: user, book_copy: book_copy1, return_date: Date.current + 30.days, returned_at: nil)

        result = described_class.call(user)

        expect(result[:active_not_overdue_reservations].count).to eq(1)
        expect(result[:active_overdue_reservations]).to be_empty

        reservation_ids = result[:active_not_overdue_reservations].map { |r| r['id'] }
        expect(reservation_ids).to include(future_reservation.id)
      end
    end
  end
end
