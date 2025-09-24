require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:member_user) { create(:user, :member) }
  let(:librarian_user) { create(:user, :librarian) }

  describe 'GET #index' do
    context 'when user is not authenticated' do
      before { sign_out :user }

      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not call any dashboard service' do
        expect(Dashboards::LibrarianDashboard).not_to receive(:call)
        expect(Dashboards::MemberDashboard).not_to receive(:call)

        get :index
      end
    end

    context 'when user is authenticated as a member' do
      before do
        sign_in member_user
        Rails.cache.clear
      end

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'calls MemberDashboard service with current user' do
        expect(Dashboards::MemberDashboard).to receive(:call).with(member_user).and_return({
          active_not_overdue_reservations: [],
          active_overdue_reservations: [],
          recent_reservation_history: []
        })

        get :index
      end

      it 'does not call LibrarianDashboard service' do
        expect(Dashboards::LibrarianDashboard).not_to receive(:call)

        get :index
      end

      it 'returns member dashboard data structure' do
        book_copy = create(:book_copy)

        open_reservation = create(:reservation, :open, user: member_user, book_copy: book_copy)
        overdue_reservation = create(:reservation, :overdue, user: member_user, book_copy: book_copy)
        returned_reservation = create(:reservation, :returned, user: member_user, book_copy: book_copy)
        active_with_overdue = create(:reservation, :active_with_overdue_date, user: member_user, book_copy: book_copy)

        get :index

        expect(response.content_type).to include('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('active_not_overdue_reservations')
        expect(parsed_response).to have_key('active_overdue_reservations')
        expect(parsed_response).to have_key('recent_reservation_history')

        # Verify data structure
        expect(parsed_response['active_not_overdue_reservations']).to be_an(Array)
        expect(parsed_response['active_overdue_reservations']).to be_an(Array)
        expect(parsed_response['recent_reservation_history']).to be_an(Array)

        # Verify correct data is returned
        # debugger
        expected_response = {
          'active_not_overdue_reservations' => [
            {
              'id' => open_reservation.id,
              'return_date' => open_reservation.return_date.as_json,
              'book_serial_number' => book_copy.book_serial_number,
              'title' => book_copy.book.title,
              'author' => book_copy.book.author
            }
          ],
          'active_overdue_reservations' => [
            {
              'id' => active_with_overdue.id,
              'return_date' => active_with_overdue.return_date.as_json,
              'book_serial_number' => book_copy.book_serial_number,
              'title' => book_copy.book.title,
              'author' => book_copy.book.author
            }
          ],
          'recent_reservation_history' => [
            {
              'id' => returned_reservation.id,
              'returned_at' => returned_reservation.returned_at.as_json,
              'return_date' => returned_reservation.return_date.as_json,
              'book_serial_number' => book_copy.book_serial_number,
              'title' => book_copy.book.title,
              'author' => book_copy.book.author
            },
            {
              'id' => overdue_reservation.id,
              'returned_at' => overdue_reservation.returned_at.as_json,
              'return_date' => overdue_reservation.return_date.as_json,
              'book_serial_number' => book_copy.book_serial_number,
              'title' => book_copy.book.title,
              'author' => book_copy.book.author
            }
          ]
        }
        expect(parsed_response['recent_reservation_history']).to eq(expected_response['recent_reservation_history'])
        expect(parsed_response['active_not_overdue_reservations']).to eq(expected_response['active_not_overdue_reservations'])
        expect(parsed_response['active_overdue_reservations']).to eq(expected_response['active_overdue_reservations'])
      end

      it 'excludes other users data' do
        other_user = create(:user, :member)
        book_copy = create(:book_copy)

        other_reservation = create(:reservation, :open, user: other_user, book_copy: book_copy)

        get :index

        parsed_response = JSON.parse(response.body)
        all_reservation_ids = []
        all_reservation_ids += parsed_response['active_not_overdue_reservations'].map { |r| r['id'] }
        all_reservation_ids += parsed_response['active_overdue_reservations'].map { |r| r['id'] }
        all_reservation_ids += parsed_response['recent_reservation_history'].map { |r| r['id'] }

        expect(all_reservation_ids).not_to include(other_reservation.id)
      end
    end

    context 'when user is authenticated as a librarian' do
      before do
        sign_in librarian_user
        Rails.cache.clear
      end

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'calls LibrarianDashboard service' do
        expect(Dashboards::LibrarianDashboard).to receive(:call).and_return({
          total_books: 0,
          total_borrowed_books: 0,
          books_due_today: 0,
          overdue_members: []
        })

        get :index
      end

      it 'does not call MemberDashboard service' do
        expect(Dashboards::MemberDashboard).not_to receive(:call)

        get :index
      end

      it 'returns librarian dashboard data structure' do
        # Create some test data
        create_list(:book_copy, 5)

        member1 = create(:user, :member)
        member2 = create(:user, :member)
        book_copy1 = create(:book_copy)
        book_copy2 = create(:book_copy)

        # Active reservations
        create(:reservation, :open, user: member1, book_copy: book_copy1)
        create(:reservation, user: member2, book_copy: book_copy2, return_date: Date.current, returned_at: nil) # Due today

        # Overdue reservation
        book_copy3 = create(:book_copy)
        create(:reservation, :active_with_overdue_date, user: member1, book_copy: book_copy3)

        get :index

        expect(response.content_type).to include('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('total_books')
        expect(parsed_response).to have_key('total_borrowed_books')
        expect(parsed_response).to have_key('books_due_today')
        expect(parsed_response).to have_key('overdue_members')


        # Verify correct counts
        expect(parsed_response['total_books']).to eq(8)
        expect(parsed_response['total_borrowed_books']).to eq(3)
        expect(parsed_response['books_due_today']).to eq(1)
        expect(parsed_response['overdue_members'].length).to eq(1)
      end

      it 'includes overdue member details in response' do
        overdue_member = create(:user, :member, name: 'John Doe', email: 'john@example.com')
        book_copy = create(:book_copy)

        create(:reservation,
          user: overdue_member,
          book_copy: book_copy,
          return_date: Date.current - 2.days,
          returned_at: nil
        )

        get :index

        parsed_response = JSON.parse(response.body)
        overdue_data = parsed_response['overdue_members'].first

        expect(overdue_data['id']).to eq(overdue_member.id)
        expect(overdue_data['name']).to eq('John Doe')
        expect(overdue_data['email']).to eq('john@example.com')
      end
    end

    context 'JSON response format' do
      it 'returns valid JSON for member dashboard' do
        sign_in member_user
        get :index

        expect { JSON.parse(response.body) }.not_to raise_error
        expect(response.content_type).to include('application/json')
      end

      it 'returns valid JSON for librarian dashboard' do
        sign_in librarian_user
        get :index

        expect { JSON.parse(response.body) }.not_to raise_error
        expect(response.content_type).to include('application/json')
      end
    end
  end
end
