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
          double(full_messages: ['Unable to return book'])
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
