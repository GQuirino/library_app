require 'rails_helper'

RSpec.describe Api::V1::ReservationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:member_user) { create(:user, :member) }
  let(:librarian_user) { create(:user, :librarian) }
  let(:book) { create(:book) }
  let(:book_copy) { create(:book_copy, book: book, available: true) }
  let(:unavailable_book_copy) { create(:book_copy, book: book, available: false) }
  let(:reservation) { create(:reservation, user: member_user, book_copy: book_copy, returned_at: nil) }

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        book_copy_id: book_copy.id,
        return_date: Date.current + 14.days
      }
    end

    let(:invalid_attributes) do
      {
        book_copy_id: nil,
        return_date: nil
      }
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        post :create, params: { reservation: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as member' do
      before { sign_in member_user }

      it 'allows members to create reservations' do
        post :create, params: { reservation: valid_attributes }
        expect(response).to have_http_status(:created)
      end

      it 'creates a new reservation with valid attributes' do
        expect {
          post :create, params: { reservation: valid_attributes }
        }.to change(Reservation, :count).by(1)

        expect(response).to have_http_status(:created)

        created_reservation = Reservation.last
        expect(created_reservation.user).to eq(member_user)
        expect(created_reservation.book_copy).to eq(book_copy)
        expect(created_reservation.return_date).to eq(Date.current + 14.days)
      end

      it 'returns the created reservation in JSON format' do
        post :create, params: { reservation: valid_attributes }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['user_id']).to eq(member_user.id)
        expect(parsed_response['book_copy_id']).to eq(book_copy.id)
        expect(parsed_response['return_date']).to eq((Date.current + 14.days).iso8601)
        expect(parsed_response['returned_at']).to be_nil
      end

      it 'sets the current_user as the reservation user automatically' do
        post :create, params: { reservation: valid_attributes.merge(user_id: nil) }

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['user_id']).to eq(member_user.id)
      end

      it 'does not ignores user_id parameter' do
        other_user = create(:user, :member)

        post :create, params: {
          reservation: valid_attributes.merge(user_id: other_user.id)
        }

        created_reservation = Reservation.last
        expect(created_reservation.user).not_to eq(member_user)
        expect(created_reservation.user).to eq(other_user)
      end

      it 'returns errors for invalid attributes' do
        post :create, params: { reservation: invalid_attributes }

        expect(response).to have_http_status(:bad_request)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['errors']).to be_an(Array)
        expect(parsed_response['errors']).to include("param is missing or the value is empty or invalid: book_copy_id")
      end

      it 'prevents creating multiple active reservations for same book copy' do
        # Create first reservation
        post :create, params: { reservation: valid_attributes }
        expect(response).to have_http_status(:created)

        # Try to create second reservation for same book copy
        other_user = create(:user, :member)
        sign_in other_user

        post :create, params: { reservation: valid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'prevents creating reservation with past return date' do
        post :create, params: {
          reservation: {
            book_copy_id: book_copy.id,
            return_date: Date.current - 1.day
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['errors']).to include("Validation failed: Return date must be in the future")
      end

      it 'handles non-existent book copy' do
        post :create, params: {
          reservation: {
            book_copy_id: 999999,
            return_date: Date.current + 7.days
          }
        }

        expect(response).to have_http_status(:not_found)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['errors']).to include("Book copy not found")
      end
    end

    context 'when user is authenticated as librarian' do
      before { sign_in librarian_user }

      it 'allows librarians to create reservations' do
        post :create, params: { reservation: valid_attributes }
        expect(response).to have_http_status(:created)
      end

      it 'creates reservation with librarian as the user' do
        post :create, params: { reservation: valid_attributes }

        created_reservation = Reservation.last
        expect(created_reservation.user).to eq(librarian_user)
      end
    end

    context 'authorization' do
      it 'uses ReservationPolicy for authorization' do
        sign_in member_user
        expect(controller).to receive(:authorize).with(Reservation)

        post :create, params: { reservation: valid_attributes }
      end
    end
  end

  describe 'PATCH #return_book' do
    let!(:active_reservation) do
      create(:reservation,
        user: member_user,
        book_copy: book_copy,
        return_date: Date.current + 7.days,
        returned_at: nil
      )
    end

    let!(:already_returned_reservation) do
      create(:reservation,
        user: member_user,
        book_copy: unavailable_book_copy,
        return_date: Date.current - 1.day,
        returned_at: Date.current
      )
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        patch :return_book, params: { id: active_reservation.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as member' do
      before { sign_in member_user }

      it 'returns forbidden status (members cannot return books via API)' do
        patch :return_book, params: { id: active_reservation.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not mark the reservation as returned' do
        original_returned_at = active_reservation.returned_at
        patch :return_book, params: { id: active_reservation.id }

        active_reservation.reload
        expect(active_reservation.returned_at).to eq(original_returned_at)
      end
    end

    context 'when user is authenticated as librarian' do
      before { sign_in librarian_user }

      it 'allows librarians to mark books as returned' do
        patch :return_book, params: { id: active_reservation.id }
        expect(response).to have_http_status(:ok)
      end

      it 'marks the reservation as returned' do
        expect(active_reservation.returned_at).to be_nil

        patch :return_book, params: { id: active_reservation.id }

        expect(response).to have_http_status(:ok)
        active_reservation.reload
        expect(active_reservation.returned_at).not_to be_nil
        expect(active_reservation.returned_at).to eq(Date.current)
      end

      it 'returns success message' do
        patch :return_book, params: { id: active_reservation.id }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to eq('Book returned successfully')
      end

      it 'makes the book copy available again' do
        book_copy.update!(available: false)

        patch :return_book, params: { id: active_reservation.id }

        expect(response).to have_http_status(:ok)
        book_copy.reload
        expect(book_copy.available).to be true
      end

      it 'handles already returned reservations' do
        patch :return_book, params: { id: already_returned_reservation.id }

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['errors']).to include('Book has already been returned')
      end

      it 'returns 404 for non-existent reservation' do
        patch :return_book, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it 'handles reservation that cannot be marked as returned' do
        # Mock the mark_as_returned! method to return false
        allow(Reservation).to receive(:find).and_return(active_reservation)
        allow(active_reservation).to receive(:mark_as_returned!).and_return(false)
        allow(active_reservation).to receive(:errors).and_return(
          double(full_messages: [ 'Unable to return book' ])
        )

        patch :return_book, params: { id: active_reservation.id }

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['errors']).to include('Unable to return book')
      end

      context 'with overdue reservations' do
        let!(:overdue_reservation) do
          create(:reservation, :active_with_overdue_date,
            user: member_user,
            book_copy: book_copy
          )
        end

        it 'successfully returns overdue books' do
          patch :return_book, params: { id: overdue_reservation.id }

          expect(response).to have_http_status(:ok)
          overdue_reservation.reload
          expect(overdue_reservation.returned_at).not_to be_nil
        end
      end
    end

    context 'authorization' do
      it 'uses ReservationPolicy for authorization' do
        sign_in librarian_user
        expect(controller).to receive(:authorize).with(Reservation, :update?)

        patch :return_book, params: { id: active_reservation.id }
      end
    end
  end

  describe 'GET #index' do
    let(:book1) { create(:book, title: 'Ruby Programming') }
    let(:book2) { create(:book, title: 'JavaScript Guide') }
    let(:book_copy1) { create(:book_copy, book: book1, available: false) }
    let(:book_copy2) { create(:book_copy, book: book2, available: false) }
    let(:book_copy3) { create(:book_copy, book: book1, available: false) }

    let(:user1) { create(:user, :member, name: 'John Doe') }
    let(:user2) { create(:user, :member, name: 'Jane Smith') }

    # Create test reservations with different states and dates
    let!(:active_reservation1) do
      create(:reservation,
        user: user1,
        book_copy: book_copy1,
        return_date: Date.current + 7.days,
        returned_at: nil
      )
    end

    let!(:active_reservation2) do
      create(:reservation,
        user: user2,
        book_copy: book_copy2,
        return_date: Date.current + 14.days,
        returned_at: nil
      )
    end

    let!(:overdue_reservation) do
      create(:reservation,
        user: user1,
        book_copy: book_copy3,
        return_date: Date.current - 3.days,
        returned_at: nil
      )
    end

    let!(:returned_reservation) do
      create(:reservation,
        user: user2,
        book_copy: create(:book_copy, book: book2, available: true),
        return_date: Date.current - 1.day,
        returned_at: Date.current
      )
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as member' do
      before { sign_in member_user }

      it 'returns forbidden status (members cannot view all reservations)' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authenticated as librarian' do
      before { sign_in librarian_user }

      describe 'without filters' do
        it 'returns all reservations within the default date range' do
          get :index

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations']).to be_an(Array)
          expect(parsed_response['reservations'].length).to eq(4)
        end

        it 'includes pagination metadata' do
          get :index

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['meta']).to include('current_page', 'next_page', 'prev_page', 'total_pages', 'total_count')
          expect(parsed_response['meta']['current_page']).to eq(1)
          expect(parsed_response['meta']['total_count']).to eq(4)
        end

        it 'orders reservations by return_date desc' do
          get :index

          parsed_response = JSON.parse(response.body)
          reservations = parsed_response['reservations']

          return_dates = reservations.map { |r| Date.parse(r['return_date']) }
          expect(return_dates).to eq(return_dates.sort.reverse)
        end
      end

      describe 'user_id filter' do
        it 'filters reservations by user_id' do
          get :index, params: { user_id: user1.id }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(2)
          parsed_response['reservations'].each do |reservation|
            expect(reservation['user_id']).to eq(user1.id)
          end
        end

        it 'returns empty array for non-existent user' do
          get :index, params: { user_id: 999999 }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['reservations']).to be_empty
        end

        it 'includes user_id in filters metadata' do
          get :index, params: { user_id: user1.id }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['filters']['user_id']).to eq(user1.id.to_s)
        end
      end

      describe 'book_copies filter' do
        it 'filters reservations by book_copy_id' do
          get :index, params: { book_copies: book_copy1.id }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(1)
          expect(parsed_response['reservations'].first['book_copy_id']).to eq(book_copy1.id)
        end
      end

      describe 'book filter' do
        it 'filters reservations by book_id' do
          get :index, params: { book: book1.id }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(2)
          parsed_response['reservations'].each do |reservation|
            expect([ book_copy1.id, book_copy3.id ]).to include(reservation['book_copy_id'])
          end
        end
      end

      describe 'overdue filter' do
        it 'filters to show only overdue reservations when overdue=true' do
          create(:reservation, :active_with_overdue_date)
          get :index, params: { overdue: 'true' }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(2)
          expect(parsed_response['reservations'].first['id']).to eq(overdue_reservation.id)
        end

        it 'shows all reservations when overdue is not specified' do
          get :index

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['reservations'].length).to eq(4)
        end

        it 'filters to show only active reservations when overdue=false' do
          get :index, params: { overdue: 'false' }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          # Should show active reservations (non-returned)
          active_ids = [ active_reservation1.id, active_reservation2.id, overdue_reservation.id ]
          returned_ids = parsed_response['reservations'].map { |r| r['id'] }

          expect(returned_ids).to match_array(active_ids)
          expect(parsed_response['reservations'].length).to eq(3)
        end
      end

      describe 'return_date_range filter' do
        it 'filters reservations by return date range' do
          start_date = Date.current + 5.days
          end_date = Date.current + 15.days

          get :index, params: {
            return_date_range: {
              start: start_date.iso8601,
              end: end_date.iso8601
            }
          }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(2)

          parsed_response['reservations'].each do |reservation|
            return_date = Date.parse(reservation['return_date'])
            expect(return_date).to be_between(start_date, end_date)
          end
        end
      end

      describe 'combined filters' do
        it 'applies multiple filters simultaneously' do
          get :index, params: {
            user_id: user1.id,
            overdue: 'true'
          }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(1)
          reservation = parsed_response['reservations'].first
          expect(reservation['id']).to eq(overdue_reservation.id)
          expect(reservation['user_id']).to eq(user1.id)
        end

        it 'returns empty result when filters match no records' do
          get :index, params: {
            user_id: user2.id,
            overdue: 'true'
          }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['reservations']).to be_empty
        end
      end

      describe 'pagination' do
        before do
          # Create additional reservations to test pagination
          5.times do |i|
            user = create(:user, :member, name: "Test User #{i}")
            book_copy = create(:book_copy, book: book1, available: false)
            create(:reservation,
              user: user,
              book_copy: book_copy,
              return_date: Date.current + (i + 2).days
            )
          end
        end

        it 'paginates results with per_page parameter' do
          get :index, params: { per_page: 3, page: 1 }

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(3)
          expect(parsed_response['meta']['current_page']).to eq(1)
          expect(parsed_response['meta']['total_count']).to eq(9)
        end

        it 'returns second page of results' do
          get :index, params: { per_page: 3, page: 2 }

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['reservations'].length).to eq(3)
          expect(parsed_response['meta']['current_page']).to eq(2)
        end

        it 'uses default per_page when not specified' do
          get :index

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['reservations'].length).to be <= 20 # Default per_page
        end
      end

      describe 'filter validation and edge cases' do
        it 'handles empty filter parameters gracefully' do
          get :index, params: { user_id: '', book: '   ', overdue: nil }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['reservations'].length).to eq(4) # Shows all
        end

        it 'strips whitespace from filter parameters' do
          get :index, params: { user_id: "  #{user1.id}  " }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['filters']['user_id']).to eq(user1.id.to_s)
          expect(parsed_response['reservations'].length).to eq(2)
        end

        it 'includes applied filters in response metadata' do
          get :index, params: {
            user_id: user1.id,
            overdue: 'true',
            book: book1.id
          }

          parsed_response = JSON.parse(response.body)
          filters = parsed_response['filters']

          expect(filters['user_id']).to eq(user1.id.to_s)
          expect(filters['overdue']).to eq('true')
          expect(filters['book']).to eq(book1.id.to_s)
        end
      end

      context 'authorization' do
        it 'uses ReservationPolicy for authorization' do
          expect(controller).to receive(:authorize).with(Reservation)
          get :index
        end
      end
    end

    describe 'response format' do
      before { sign_in librarian_user }

      it 'returns well-structured JSON response' do
        get :index

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response).to have_key('reservations')
        expect(parsed_response).to have_key('meta')
        expect(parsed_response).to have_key('filters')

        expect(parsed_response['reservations']).to be_an(Array)
        expect(parsed_response['meta']).to be_a(Hash)
        expect(parsed_response['filters']).to be_a(Hash)
      end

      it 'includes all necessary reservation fields' do
        get :index

        parsed_response = JSON.parse(response.body)
        reservation = parsed_response['reservations'].first

        expect(reservation).to have_key('id')
        expect(reservation).to have_key('user_id')
        expect(reservation).to have_key('book_copy_id')
        expect(reservation).to have_key('return_date')
        expect(reservation).to have_key('returned_at')
      end
    end
  end

  describe 'GET #show' do
    let!(:reservation) { create(:reservation, user: member_user, book_copy: book_copy) }

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        get :show, params: { id: reservation.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as member' do
      before { sign_in member_user }

      it 'returns forbidden status (members cannot view individual reservations via API)' do
        get :show, params: { id: reservation.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authenticated as librarian' do
      before { sign_in librarian_user }

      it 'returns the requested reservation' do
        get :show, params: { id: reservation.id }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['id']).to eq(reservation.id)
        expect(parsed_response['user_id']).to eq(reservation.user_id)
        expect(parsed_response['book_copy_id']).to eq(reservation.book_copy_id)
      end

      it 'returns 404 for non-existent reservation' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it 'uses ReservationPolicy for authorization' do
        expect(controller).to receive(:authorize).with(Reservation)
        get :show, params: { id: reservation.id }
      end
    end
  end

  describe 'JSON response format' do
    before { sign_in member_user }

    it 'returns valid JSON for successful reservation creation' do
      post :create, params: {
        reservation: {
          book_copy_id: book_copy.id,
          return_date: Date.current + 7.days
        }
      }

      expect { JSON.parse(response.body) }.not_to raise_error
      expect(response.content_type).to include('application/json')
    end

    it 'returns valid JSON for error responses' do
      post :create, params: { reservation: { book_copy_id: nil } }

      expect { JSON.parse(response.body) }.not_to raise_error
      expect(response.content_type).to include('application/json')
    end
  end
end
