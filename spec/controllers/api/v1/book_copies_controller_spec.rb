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

  describe 'filtering functionality' do
    before { sign_in member_user }

    let!(:fantasy_book) { create(:book, title: 'The Hobbit', author: 'J.R.R. Tolkien', genre: 'Fantasy') }
    let!(:science_book) { create(:book, title: 'Brief History of Time', author: 'Stephen Hawking', genre: 'Science') }
    let!(:mystery_book) { create(:book, title: 'Murder Mystery', author: 'Agatha Christie', genre: 'Mystery') }

    let!(:fantasy_copy1) { create(:book_copy, book: fantasy_book, book_serial_number: 'FANT001') }
    let!(:fantasy_copy2) { create(:book_copy, book: fantasy_book, book_serial_number: 'FANT002') }
    let!(:science_copy1) { create(:book_copy, book: science_book, book_serial_number: 'SCI001') }
    let!(:mystery_copy1) { create(:book_copy, book: mystery_book, book_serial_number: 'MYS001') }

    describe 'title filtering' do
      it 'filters book copies by book title (case insensitive)' do
        get :index, params: { book_id: fantasy_book.id, title: 'hobbit' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['book_copies'].all? { |c| c['book_title'] == 'The Hobbit' }).to be true
      end

      it 'filters book copies by partial title match' do
        get :index, params: { book_id: science_book.id, title: 'brief' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(1)
        expect(parsed_response['book_copies'].first['book_title']).to eq('Brief History of Time')
      end

      it 'returns empty array when title does not match' do
        get :index, params: { book_id: fantasy_book.id, title: 'nonexistent' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies']).to be_empty
      end

      it 'includes applied title filter in response' do
        get :index, params: { book_id: fantasy_book.id, title: 'hobbit' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['filters']['title']).to eq('hobbit')
      end
    end

    describe 'author filtering' do
      it 'filters book copies by book author (case insensitive)' do
        get :index, params: { book_id: fantasy_book.id, author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['book_copies'].all? { |c| c['book_title'] == 'The Hobbit' }).to be true
      end

      it 'filters book copies by partial author match' do
        get :index, params: { book_id: science_book.id, author: 'hawking' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(1)
        expect(parsed_response['book_copies'].first['book_title']).to eq('Brief History of Time')
      end

      it 'returns empty array when author does not match' do
        get :index, params: { book_id: fantasy_book.id, author: 'unknown author' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies']).to be_empty
      end

      it 'includes applied author filter in response' do
        get :index, params: { book_id: fantasy_book.id, author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['filters']['author']).to eq('tolkien')
      end
    end

    describe 'genre filtering' do
      it 'filters book copies by book genre (case insensitive)' do
        get :index, params: { book_id: fantasy_book.id, genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['book_copies'].all? { |c| c['book_title'] == 'The Hobbit' }).to be true
      end

      it 'filters book copies by exact genre match' do
        get :index, params: { book_id: science_book.id, genre: 'Science' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(1)
        expect(parsed_response['book_copies'].first['book_title']).to eq('Brief History of Time')
      end

      it 'returns empty array when genre does not match' do
        get :index, params: { book_id: fantasy_book.id, genre: 'horror' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies']).to be_empty
      end

      it 'includes applied genre filter in response' do
        get :index, params: { book_id: fantasy_book.id, genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['filters']['genre']).to eq('fantasy')
      end
    end

    describe 'multiple filters' do
      it 'applies multiple filters simultaneously' do
        get :index, params: { book_id: fantasy_book.id, author: 'tolkien', genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['book_copies'].all? { |c| c['book_title'] == 'The Hobbit' }).to be true
      end

      it 'narrows results with multiple filters' do
        get :index, params: { book_id: fantasy_book.id, title: 'hobbit', author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['book_copies'].all? { |c| c['book_title'] == 'The Hobbit' }).to be true
      end

      it 'returns empty when filters do not match book' do
        get :index, params: { book_id: fantasy_book.id, author: 'tolkien', genre: 'science' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies']).to be_empty
      end

      it 'includes all applied filters in response' do
        get :index, params: { book_id: fantasy_book.id, title: 'hobbit', author: 'tolkien', genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        filters = parsed_response['filters']
        expect(filters['title']).to eq('hobbit')
        expect(filters['author']).to eq('tolkien')
        expect(filters['genre']).to eq('fantasy')
      end
    end

    describe 'filters with pagination' do
      let!(:book_with_many_copies) { create(:book, title: 'Popular Book', author: 'Famous Author', genre: 'Fiction') }

      before do
        15.times do |i|
          create(:book_copy, book: book_with_many_copies, book_serial_number: "POP#{i.to_s.rjust(3, '0')}")
        end
      end

      it 'applies filters before pagination' do
        get :index, params: {
          book_id: book_with_many_copies.id,
          author: 'famous',
          per_page: 5,
          page: 1
        }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(5)
        expect(parsed_response['meta']['total_count']).to eq(15)
        expect(parsed_response['meta']['total_pages']).to eq(3)
      end

      it 'maintains filters across pagination pages' do
        get :index, params: {
          book_id: book_with_many_copies.id,
          author: 'famous',
          per_page: 5,
          page: 2
        }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(5)
        expect(parsed_response['book_copies'].all? { |c| c['book_title'] == 'Popular Book' }).to be true
        expect(parsed_response['filters']['author']).to eq('famous')
      end
    end

    describe 'empty and whitespace filters' do
      it 'ignores empty string filters' do
        get :index, params: { book_id: fantasy_book.id, title: '', author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['filters']).to eq({ 'author' => 'tolkien' })
      end

      it 'ignores whitespace-only filters' do
        get :index, params: { book_id: fantasy_book.id, title: '   ', genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['filters']).to eq({ 'genre' => 'fantasy' })
      end

      it 'trims whitespace from filter values' do
        get :index, params: { book_id: fantasy_book.id, author: '  tolkien  ' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(2)
        expect(parsed_response['filters']['author']).to eq('tolkien')
      end
    end

    describe 'special characters in filters' do
      let!(:special_book) do
        create(:book,
          title: 'Book with "Quotes" & Symbols',
          author: 'O\'Brien, John',
          genre: 'Sci-Fi'
        )
      end
      let!(:special_copy) { create(:book_copy, book: special_book, book_serial_number: 'SPEC001') }

      it 'handles quotes in filter values' do
        get :index, params: { book_id: special_book.id, title: 'quotes' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(1)
        expect(parsed_response['book_copies'].first['book_title']).to eq('Book with "Quotes" & Symbols')
      end

      it 'handles apostrophes in filter values' do
        get :index, params: { book_id: special_book.id, author: 'brien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(1)
        expect(parsed_response['book_copies'].first['book_title']).to eq('Book with "Quotes" & Symbols')
      end

      it 'handles hyphens in filter values' do
        get :index, params: { book_id: special_book.id, genre: 'sci-fi' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(1)
        expect(parsed_response['book_copies'].first['book_title']).to eq('Book with "Quotes" & Symbols')
      end
    end

    describe 'filter behavior with no results' do
      it 'returns empty array and correct metadata when no copies match filters' do
        get :index, params: { book_id: fantasy_book.id, title: 'nonexistent book' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies']).to be_empty
        expect(parsed_response['meta']['total_count']).to eq(0)
        expect(parsed_response['meta']['current_page']).to eq(1)
        expect(parsed_response['book']).to include('title' => 'The Hobbit')
        expect(parsed_response['filters']['title']).to eq('nonexistent book')
      end

      it 'maintains book information even when no copies match' do
        get :index, params: { book_id: science_book.id, genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies']).to be_empty
        expect(parsed_response['book']).to include(
          'id' => science_book.id,
          'title' => 'Brief History of Time',
          'author' => 'Stephen Hawking'
        )
      end
    end

    describe 'performance with filters' do
      let!(:large_book) { create(:book, title: 'Large Book', author: 'Prolific Author', genre: 'Reference') }

      before do
        50.times do |i|
          create(:book_copy, book: large_book, book_serial_number: "REF#{i.to_s.rjust(3, '0')}")
        end
      end

      it 'efficiently handles large datasets with filters' do
        expect {
          get :index, params: {
            book_id: large_book.id,
            author: 'prolific',
            per_page: 20
          }
          expect(response).to have_http_status(:ok)
        }.not_to raise_error

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies'].length).to eq(20)
        expect(parsed_response['meta']['total_count']).to eq(50)
      end

      it 'applies filters efficiently without loading unnecessary data' do
        # This test ensures that filtering happens at the database level
        get :index, params: {
          book_id: large_book.id,
          title: 'nonexistent',
          per_page: 10
        }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['book_copies']).to be_empty
        expect(parsed_response['meta']['total_count']).to eq(0)
      end
    end

    describe 'error handling with invalid book_id' do
      it 'returns 404 when book does not exist' do
        get :index, params: { book_id: 999999, title: 'any title' }
        expect(response).to have_http_status(:not_found)
      end

      it 'includes error message for missing book' do
        get :index, params: { book_id: 999999, author: 'any author' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['error']).to eq('Book not found')
        expect(parsed_response['message']).to eq('The requested book does not exist')
      end
    end

    describe 'authorization with filters' do
      context 'when user is not authenticated' do
        before { sign_out member_user }

        it 'returns unauthorized even with valid filters' do
          get :index, params: { book_id: fantasy_book.id, title: 'hobbit' }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when user has different roles' do
        it 'allows members to use filters' do
          sign_in member_user
          get :index, params: { book_id: fantasy_book.id, author: 'tolkien' }
          expect(response).to have_http_status(:ok)
        end

        it 'allows librarians to use filters' do
          sign_in librarian_user
          get :index, params: { book_id: fantasy_book.id, genre: 'fantasy' }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
