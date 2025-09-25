require 'rails_helper'

RSpec.describe Api::V1::BookCopiesController, type: :controller do
  let(:librarian_user) { create(:user, :librarian) }
  let(:member_user) { create(:user, :member) }
  let(:book) { create(:book) }
  let(:book_copy) { create(:book_copy, book: book) }
  let(:valid_attributes) do
    {
      book_serial_number: 'TEST123',
      available: true
    }
  end
  let(:invalid_attributes) do
    {
      book_serial_number: '',
      available: nil
    }
  end

  describe 'GET #index' do
    context 'when user is authenticated' do
      before do
        sign_in member_user
        create_list(:book_copy, 3, book: book)
      end

      it 'returns successful response' do
        get :index, params: { book_id: book.id }
        expect(response).to have_http_status(:ok)
      end

      it 'returns book copies with pagination metadata' do
        get :index, params: { book_id: book.id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('book_copies')
        expect(parsed_response).to have_key('meta')
        expect(parsed_response).to have_key('book')
        expect(parsed_response['book_copies']).to be_an(Array)
        expect(parsed_response['meta']).to have_key('current_page')
      end

      it 'returns not found for non-existent book' do
        get :index, params: { book_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        get :index, params: { book_id: book.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    context 'when user is authenticated' do
      before { sign_in member_user }

      it 'returns successful response for existing book copy' do
        get :show, params: { id: book_copy.id }
        expect(response).to have_http_status(:ok)
      end

      it 'includes book information' do
        user = create(:user, :member)

        get :show, params: { id: book_copy.id }

        parsed_response = JSON.parse(response.body)
        expected_response =  {
        id: book_copy.id,
        book_serial_number: book_copy.book_serial_number,
        available: book_copy.available,
        created_at: book_copy.created_at,
        updated_at: book_copy.updated_at,
        book: {
          id: book_copy.book.id,
          title: book_copy.book.title,
          author: book_copy.book.author,
          publisher: book_copy.book.publisher,
          isbn: book_copy.book.isbn,
          genre: book_copy.book.genre,
          edition: book_copy.book.edition,
          year: book_copy.book.year
        }
      }

        expect(parsed_response).to eq("book_copy" => expected_response.as_json)
      end

      it 'returns not found for non-existent book copy' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        get :show, params: { id: book_copy.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    context 'when user is librarian' do
      before { sign_in librarian_user }

      it 'creates a new book copy with valid attributes' do
        expect {
          post :create, params: { book_id: book.id, book_copy: valid_attributes }
        }.to change(BookCopy, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns book copy data on successful creation' do
        post :create, params: { book_id: book.id, book_copy: valid_attributes }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copy']['book_serial_number']).to eq('TEST123')
        expect(parsed_response['message']).to eq('Book copy created successfully')
      end

      it 'returns errors for invalid attributes' do
        post :create, params: { book_id: book.id, book_copy: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('errors')
      end

      it 'prevents duplicate book serial numbers' do
        existing_copy = create(:book_copy, book_serial_number: 'DUPLICATE')

        post :create, params: {
          book_id: book.id,
          book_copy: { book_serial_number: 'DUPLICATE', available: true }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when user is member' do
      before { sign_in member_user }

      it 'denies access' do
        post :create, params: { book_id: book.id, book_copy: valid_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        post :create, params: { book_id: book.id, book_copy: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user is librarian' do
      before { sign_in librarian_user }

      it 'updates book copy with valid attributes' do
        patch :update, params: {
          book_id: book.id,
          id: book_copy.id,
          book_copy: { book_serial_number: 'UPDATED123' }
        }

        expect(response).to have_http_status(:ok)
        book_copy.reload
        expect(book_copy.book_serial_number).to eq('UPDATED123')
      end

      it 'returns errors for invalid attributes' do
        patch :update, params: {
          book_id: book.id,
          id: book_copy.id,
          book_copy: { book_serial_number: '' }
        }

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('errors')
      end
    end

    context 'when user is member' do
      before { sign_in member_user }

      it 'denies access' do
        patch :update, params: {
          book_id: book.id,
          id: book_copy.id,
          book_copy: { book_serial_number: 'UPDATED123' }
        }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is librarian' do
      before { sign_in librarian_user }

      it 'deletes book copy without active reservations' do
        copy_to_delete = create(:book_copy, book: book)

        expect {
          delete :destroy, params: { book_id: book.id, id: copy_to_delete.id }
        }.to change(BookCopy, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'prevents deletion when there are active reservations' do
        user = create(:user, :member)
        create(:reservation, book_copy: book_copy, user: user, returned_at: nil)

        expect {
          delete :destroy, params: { book_id: book.id, id: book_copy.id }
        }.not_to change(BookCopy, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'allows deletion when reservations are returned' do
        user = create(:user, :member)
        create(:reservation, book_copy: book_copy, user: user, returned_at: 1.day.ago)

        expect {
          delete :destroy, params: { book_id: book.id, id: book_copy.id }
        }.to change(BookCopy, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is member' do
      before { sign_in member_user }

      it 'denies access' do
        delete :destroy, params: { book_id: book.id, id: book_copy.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'Edge cases and error handling' do
    before { sign_in librarian_user }

    it 'handles non-existent book for nested routes' do
      get :index, params: { book_id: 999999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'handles non-existent book copy' do
      get :show, params: { id: 999999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'handles book copy that does not belong to specified book' do
      other_book = create(:book)
      other_copy = create(:book_copy, book: other_book)

      get :show, params: { book_id: book.id, id: other_copy.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'error handling with invalid book_id' do
    before { sign_in librarian_user }

    it 'returns 404 when book does not exist' do
      get :index, params: { book_id: 999999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'includes error message for missing book' do
      get :index, params: { book_id: 999999 }

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['error']).to eq('Book not found')
      expect(parsed_response['message']).to eq('The requested book does not exist')
    end
  end
end
