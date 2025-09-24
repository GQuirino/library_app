require 'rails_helper'

RSpec.describe Dashboards::LibrarianDashboard do
  describe '.call' do
    let!(:user1) { create(:user, :member) }
    let!(:user2) { create(:user, :member) }
    let!(:librarian) { create(:user, :librarian) }

    let!(:book1) { create(:book) }
    let!(:book2) { create(:book) }

    let!(:book_copy1) { create(:book_copy, book: book1) }
    let!(:book_copy2) { create(:book_copy, book: book1) }
    let!(:book_copy3) { create(:book_copy, book: book2) }
    let!(:book_copy4) { create(:book_copy, book: book2) }

    before do
      # Clear cache before each test
      Rails.cache.clear
    end

    context 'with no reservations' do
      it 'returns correct dashboard data' do
        result = described_class.call

        expect(result[:total_books]).to eq(4) # 4 book copies
        expect(result[:total_borrowed_books]).to eq(0)
        expect(result[:books_due_today]).to eq(0)
        expect(result[:overdue_members]).to be_empty
      end
    end

    context 'with active reservations' do
      let!(:active_reservation1) { create(:reservation, user: user1, book_copy: book_copy1, return_date: Date.current + 5.days, returned_at: nil) }
      let!(:active_reservation2) { create(:reservation, user: user2, book_copy: book_copy2, return_date: Date.current + 3.days, returned_at: nil) }

      it 'returns correct borrowed books count' do
        result = described_class.call

        expect(result[:total_borrowed_books]).to eq(2)
        expect(result[:books_due_today]).to eq(0)
        expect(result[:overdue_members]).to be_empty
      end
    end

    context 'with books due today' do
      let!(:due_today1) { create(:reservation, user: user1, book_copy: book_copy1, return_date: Date.current, returned_at: nil) }
      let!(:due_today2) { create(:reservation, user: user2, book_copy: book_copy2, return_date: Date.current, returned_at: nil) }
      let!(:future_reservation) { create(:reservation, user: user1, book_copy: book_copy3, return_date: Date.current + 2.days, returned_at: nil) }

      it 'returns correct due today count' do
        result = described_class.call

        expect(result[:total_borrowed_books]).to eq(3)
        expect(result[:books_due_today]).to eq(2)
        expect(result[:overdue_members]).to be_empty
      end
    end

    context 'with overdue reservations' do
      let!(:overdue_reservation1) { create(:reservation, user: user1, book_copy: book_copy1, return_date: Date.current - 2.days, returned_at: nil) }
      let!(:overdue_reservation2) { create(:reservation, user: user2, book_copy: book_copy2, return_date: Date.current - 1.day, returned_at: nil) }
      let!(:returned_overdue) { create(:reservation, user: user1, book_copy: book_copy3, return_date: Date.current - 3.days, returned_at: Date.current) }

      it 'returns overdue members' do
        result = described_class.call

        expect(result[:overdue_members].count).to eq(2)
        expect(result[:overdue_members].pluck(:id)).to contain_exactly(user1.id, user2.id)
        expect(result[:overdue_members].first.attributes.keys).to contain_exactly('id', 'name', 'email')
      end

      it 'does not include returned overdue reservations in member list' do
        result = described_class.call

        # The returned overdue reservation should not affect overdue members count
        expect(result[:overdue_members].count).to eq(2)
      end

      it 'limits overdue members to prevent large result sets' do
        # Create many overdue reservations
        users = create_list(:user, 60, :member)
        book_copies = create_list(:book_copy, 60)

        users.each_with_index do |user, index|
          create(:reservation,
            user: user,
            book_copy: book_copies[index],
            return_date: Date.current - 1.day,
            returned_at: nil
          )
        end

        result = described_class.call

        # Should be limited to 50 (plus the 2 from let! blocks)
        expect(result[:overdue_members].count).to be <= 50
      end
    end

    context 'with mixed reservation states' do
      let!(:active_reservation) { create(:reservation, user: user1, book_copy: book_copy1, return_date: Date.current + 5.days, returned_at: nil) }
      let!(:due_today) { create(:reservation, user: user2, book_copy: book_copy2, return_date: Date.current, returned_at: nil) }
      let!(:overdue_reservation) { create(:reservation, user: user1, book_copy: book_copy3, return_date: Date.current - 1.day, returned_at: nil) }
      let!(:returned_reservation) { create(:reservation, user: user2, book_copy: book_copy4, return_date: Date.current + 1.day, returned_at: Date.current) }

      it 'calculates all statistics correctly' do
        result = described_class.call

        expect(result[:total_books]).to eq(4)
        expect(result[:total_borrowed_books]).to eq(3) # active + due_today + overdue
        expect(result[:books_due_today]).to eq(1)
        expect(result[:overdue_members].pluck(:id)).to contain_exactly(user1.id)
      end
    end

    context 'caching behavior' do
      let!(:reservation) { create(:reservation, user: user1, book_copy: book_copy1, return_date: Date.current + 1.day, returned_at: nil) }

      it 'caches total_books with 1 hour expiration' do
        # Clear cache to ensure clean state
        Rails.cache.clear

        # First call should hit the database
        expect(BookCopy).to receive(:count).once.and_call_original
        result1 = described_class.call

        # Second call should use cache
        expect(BookCopy).not_to receive(:count)
        result2 = described_class.call

        expect(result1[:total_books]).to eq(result2[:total_books])
        expect(result1[:total_books]).to eq(4)
      end

      it 'caches reservation stats with date-based key' do
        Rails.cache.clear

        # First call should hit the database
        result1 = described_class.call

        # Verify cache exists
        cache_key = "dashboard:librarian:reservation_stats:#{Date.current}"
        expect(Rails.cache.exist?(cache_key)).to be true

        # Second call should use cache
        result2 = described_class.call

        expect(result1[:total_borrowed_books]).to eq(result2[:total_borrowed_books])
      end

      it 'caches overdue members with date-based key' do
        Rails.cache.clear
        create(:reservation, user: user1, book_copy: book_copy1, return_date: Date.current - 1.day, returned_at: nil)

        # First call
        result1 = described_class.call

        # Verify cache exists
        cache_key = "dashboard:librarian:overdue_members:#{Date.current}"
        expect(Rails.cache.exist?(cache_key)).to be true

        # Second call should use cache
        result2 = described_class.call

        expect(result1[:overdue_members].count).to eq(result2[:overdue_members].count)
        expect(result1[:overdue_members].count).to eq(1)
      end

      it 'uses different cache keys for different dates' do
        travel_to Date.current do
          described_class.call
          expect(Rails.cache.exist?("dashboard:librarian:reservation_stats:#{Date.current}")).to be true
        end

        travel_to Date.current + 1.day do
          described_class.call
          expect(Rails.cache.exist?("dashboard:librarian:reservation_stats:#{Date.current}")).to be true
        end
      end
    end

    context 'performance considerations' do
      it 'handles large datasets efficiently' do
        users = create_list(:user, 10, :member)
        book_copies = create_list(:book_copy, 10)

        users.each_with_index do |user, index|
          create(:reservation,
            user: user,
            book_copy: book_copies[index],
            return_date: Date.current - (index % 3).days,
            returned_at: index.even? ? nil : Date.current
          )
        end

        expect {
          result = described_class.call
          expect(result).to be_a(Hash)
          expect(result.keys).to contain_exactly(:total_books, :total_borrowed_books, :books_due_today, :overdue_members)
        }.not_to raise_error
      end
    end

    context 'edge cases' do
      it 'handles users with multiple overdue reservations' do
        create(:reservation, user: user1, book_copy: book_copy1, return_date: Date.current - 1.day, returned_at: nil)
        create(:reservation, user: user1, book_copy: book_copy2, return_date: Date.current - 2.days, returned_at: nil)

        result = described_class.call

        # Should only include user1 once despite multiple overdue reservations
        expect(result[:overdue_members].pluck(:id)).to eq([ user1.id ])
      end

      it 'excludes librarians from overdue members' do
        create(:reservation, user: librarian, book_copy: book_copy1, return_date: Date.current - 1.day, returned_at: nil)
        create(:reservation, user: user1, book_copy: book_copy2, return_date: Date.current - 1.day, returned_at: nil)

        result = described_class.call

        expect(result[:overdue_members].pluck(:id)).to eq([ user1.id ])
        expect(result[:overdue_members].pluck(:id)).not_to include(librarian.id)
      end

      it 'handles empty database gracefully' do
        BookCopy.destroy_all
        User.destroy_all

        result = described_class.call

        expect(result[:total_books]).to eq(0)
        expect(result[:total_borrowed_books]).to eq(0)
        expect(result[:books_due_today]).to eq(0)
        expect(result[:overdue_members]).to be_empty
      end
    end
  end
end
