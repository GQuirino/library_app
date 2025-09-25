require 'rails_helper'

RSpec.describe Api::V1::BooksController, type: :controller do
  let(:librarian_user) { create(:user, :librarian) }
  let(:member_user) { create(:user, :member) }
  let(:book) { create(:book) }

  describe 'GET #index' do
    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as a member' do
      before { sign_in member_user }

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'returns paginated books list' do
        create_list(:book, 3)
        get :index

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('books')
        expect(parsed_response).to have_key('meta')
        expect(parsed_response['books'].length).to eq(3)
      end

      it 'includes book copies count in response' do
        book_with_copies = create(:book)
        create_list(:book_copy, 3, book: book_with_copies)
        create_list(:book_copy, 2, book: book_with_copies, available: false)

        get :index

        parsed_response = JSON.parse(response.body)
        book_data = parsed_response['books'].find { |b| b['id'] == book_with_copies.id }

        expect(book_data['total_copies']).to eq(5)
        expect(book_data['available_copies']).to eq(3)
      end

      it 'supports pagination parameters' do
        create_list(:book, 25)
        get :index, params: { page: 2, per_page: 10 }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(10)
        expect(parsed_response['meta']['current_page']).to eq(2)
        expect(parsed_response['meta']['total_count']).to eq(25)
      end

      it 'orders books by title' do
        book_c = create(:book, title: 'C Book')
        book_a = create(:book, title: 'A Book')
        book_b = create(:book, title: 'B Book')

        get :index

        parsed_response = JSON.parse(response.body)
        titles = parsed_response['books'].map { |b| b['title'] }
        expect(titles).to eq([ 'A Book', 'B Book', 'C Book' ])
      end

      it 'includes all required book fields' do
        test_book = create(:book,
          title: 'Test Title',
          author: 'Test Author',
          publisher: 'Test Publisher',
          isbn: '123-4567890123',
          genre: 'Fiction',
          edition: 'First Edition',
          year: 2023
        )

        get :index

        parsed_response = JSON.parse(response.body)
        book_data = parsed_response['books'].find { |b| b['id'] == test_book.id }

        expect(book_data).to include(
          'id' => test_book.id,
          'title' => 'Test Title',
          'author' => 'Test Author',
          'publisher' => 'Test Publisher',
          'edition' => 'First Edition',
          'year' => 2023,
          'total_copies' => 0,
          'available_copies' => 0,
          'isbn' => '123-4567890123',
          'genre' => 'Fiction'
        )
        expect(book_data).to have_key('created_at')
        expect(book_data).to have_key('updated_at')
      end
    end

    context 'when user is authenticated as a librarian' do
      before { sign_in librarian_user }

      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'returns same data structure as member' do
        create(:book)
        get :index

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('books')
        expect(parsed_response).to have_key('meta')
      end
    end
  end

  describe 'GET #show' do
    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        get :show, params: { id: book.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as a member' do
      before { sign_in member_user }

      it 'returns successful response for existing book' do
        get :show, params: { id: book.id }
        expect(response).to have_http_status(:ok)
      end

      it 'returns book details with book copies' do
        book_copy1 = create(:book_copy, book: book, book_serial_number: 'BC001', available: true)
        book_copy2 = create(:book_copy, book: book, book_serial_number: 'BC002', available: false)

        get :show, params: { id: book.id }

        parsed_response = JSON.parse(response.body)
        book_data = parsed_response['book']

        expect(book_data).to include(
          'id' => book.id,
          'title' => book.title,
          'author' => book.author
        )
        expect(book_data['book_copies'].length).to eq(2)

        copy_data = book_data['book_copies'].find { |c| c['book_serial_number'] == 'BC001' }
        expect(copy_data['available']).to eq(true)
      end

      it 'returns 404 for non-existent book' do
        get :show, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['error']).to eq('Book not found')
      end
    end

    context 'when user is authenticated as a librarian' do
      before { sign_in librarian_user }

      it 'returns successful response' do
        get :show, params: { id: book.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: 'New Book Title',
        author: 'New Author',
        publisher: 'New Publisher',
        isbn: '123-4567890123',
        genre: 'Fiction',
        edition: 'First Edition',
        year: 2023
      }
    end

    let(:invalid_attributes) do
      {
        title: '',
        author: '',
        publisher: 'Publisher',
        isbn: '',
        genre: ''
      }
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        post :create, params: { book: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as a member' do
      before { sign_in member_user }

      it 'returns forbidden status' do
        post :create, params: { book: valid_attributes }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create a book' do
        expect {
          post :create, params: { book: valid_attributes }
        }.not_to change(Book, :count)
      end
    end

    context 'when user is authenticated as a librarian' do
      before { sign_in librarian_user }

      context 'with valid parameters' do
        it 'creates a new book' do
          expect {
            post :create, params: { book: valid_attributes }
          }.to change(Book, :count).by(1)
        end

        it 'returns successful response' do
          post :create, params: { book: valid_attributes }
          expect(response).to have_http_status(:created)
        end

        it 'returns the created book data' do
          post :create, params: { book: valid_attributes }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['book']).to include(
            'title' => 'New Book Title',
            'author' => 'New Author',
            'publisher' => 'New Publisher',
            'edition' => 'First Edition',
            'year' => 2023,
            'isbn' => '123-4567890123',
            'genre' => 'Fiction'
          )
          expect(parsed_response['message']).to eq('Book created successfully')
        end

        it 'assigns correct attributes to the book' do
          post :create, params: { book: valid_attributes }

          created_book = Book.last
          expect(created_book.title).to eq('New Book Title')
          expect(created_book.author).to eq('New Author')
          expect(created_book.publisher).to eq('New Publisher')
          expect(created_book.isbn).to eq('123-4567890123')
          expect(created_book.genre).to eq('Fiction')
          expect(created_book.edition).to eq('First Edition')
          expect(created_book.year).to eq(2023)
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new book' do
          expect {
            post :create, params: { book: invalid_attributes }
          }.not_to change(Book, :count)
        end

        it 'returns unprocessable entity status' do
          post :create, params: { book: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns validation errors' do
          post :create, params: { book: invalid_attributes }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to have_key('errors')
          expect(parsed_response['message']).to eq('Failed to create book')
        end
      end
    end
  end

  describe 'PUT/PATCH #update' do
    let(:new_attributes) do
      {
        title: 'Updated Title',
        author: 'Updated Author',
        year: 2024
      }
    end

    let(:invalid_attributes) do
      {
        title: '',
        author: ''
      }
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        put :update, params: { id: book.id, book: new_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as a member' do
      before { sign_in member_user }

      it 'returns forbidden status' do
        put :update, params: { id: book.id, book: new_attributes }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not update the book' do
        original_title = book.title
        put :update, params: { id: book.id, book: new_attributes }
        book.reload
        expect(book.title).to eq(original_title)
      end
    end

    context 'when user is authenticated as a librarian' do
      before { sign_in librarian_user }

      context 'with valid parameters' do
        it 'updates the book' do
          put :update, params: { id: book.id, book: new_attributes }
          book.reload
          expect(book.title).to eq('Updated Title')
          expect(book.author).to eq('Updated Author')
          expect(book.year).to eq(2024)
        end

        it 'returns successful response' do
          put :update, params: { id: book.id, book: new_attributes }
          expect(response).to have_http_status(:ok)
        end

        it 'returns the updated book data' do
          put :update, params: { id: book.id, book: new_attributes }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['book']).to include(
            'title' => 'Updated Title',
            'author' => 'Updated Author',
            'year' => 2024
          )
          expect(parsed_response['message']).to eq('Book updated successfully')
        end
      end

      context 'with invalid parameters' do
        it 'does not update the book' do
          original_title = book.title
          put :update, params: { id: book.id, book: invalid_attributes }
          book.reload
          expect(book.title).to eq(original_title)
        end

        it 'returns unprocessable entity status' do
          put :update, params: { id: book.id, book: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns validation errors' do
          put :update, params: { id: book.id, book: invalid_attributes }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to have_key('errors')
          expect(parsed_response['message']).to eq('Failed to update book')
        end
      end

      it 'returns 404 for non-existent book' do
        put :update, params: { id: 99999, book: new_attributes }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        delete :destroy, params: { id: book.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated as a member' do
      before { sign_in member_user }

      it 'returns forbidden status' do
        delete :destroy, params: { id: book.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not delete the book' do
        book_id = book.id
        delete :destroy, params: { id: book_id }
        expect(Book.exists?(book_id)).to be(true)
      end
    end

    context 'when user is authenticated as a librarian' do
      before { sign_in librarian_user }

      it 'deletes the book' do
        book_id = book.id
        delete :destroy, params: { id: book_id }
        expect(Book.exists?(book_id)).to be(false)
      end

      it 'returns successful response' do
        delete :destroy, params: { id: book.id }
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        delete :destroy, params: { id: book.id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to eq('Book deleted successfully')
      end

      it 'returns 404 for non-existent book' do
        delete :destroy, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
      end

      context 'when book has associated book copies' do
        let!(:book_with_copies) { create(:book) }
        let!(:book_copy) { create(:book_copy, book: book_with_copies) }

        it 'deletes the book and associated copies' do
          book_id = book_with_copies.id
          copy_id = book_copy.id

          delete :destroy, params: { id: book_id }

          expect(Book.exists?(book_id)).to be(false)
          expect(BookCopy.exists?(copy_id)).to be(false)
        end
      end

      context 'when book has active reservations' do
        let!(:book_with_reservation) { create(:book) }
        let!(:book_copy) { create(:book_copy, book: book_with_reservation) }
        let!(:reservation) { create(:reservation, :open, book_copy: book_copy) }

        it 'prevents deletion and returns error' do
          book_id = book_with_reservation.id

          delete :destroy, params: { id: book_id }

          expect(response).to have_http_status(:unprocessable_content)
          expect(Book.exists?(book_id)).to be(true)

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['message']).to eq('Failed to delete book')
        end
      end
    end
  end

  describe 'authorization' do
    context 'Pundit policies' do
      it 'uses BookPolicy for authorization' do
        sign_in member_user
        expect(controller).to receive(:authorize).with(Book)
        get :index
      end

      it 'authorizes specific book instance for show action' do
        sign_in member_user
        expect(controller).to receive(:authorize).with(book)
        get :show, params: { id: book.id }
      end

      it 'authorizes book instance for update action' do
        sign_in librarian_user
        expect(controller).to receive(:authorize).with(book)
        put :update, params: { id: book.id, book: { title: 'New Title' } }
      end
    end
  end

  describe 'private methods' do
    describe '#pagination_meta' do
      before { sign_in member_user }

      it 'includes pagination metadata in response' do
        create_list(:book, 25)
        get :index, params: { page: 2, per_page: 10 }

        parsed_response = JSON.parse(response.body)
        meta = parsed_response['meta']

        expect(meta).to include(
          'current_page' => 2,
          'total_pages' => 3,
          'total_count' => 25,
          'next_page' => 3,
          'prev_page' => 1
        )
      end
    end

    describe '#book_params' do
      before { sign_in librarian_user }

      it 'permits only allowed parameters' do
        post :create, params: {
          book: {
            title: 'Test',
            author: 'Author',
            publisher: 'Publisher',
            edition: 'First',
            year: 2023,
            isbn: '123-4567890123',
            genre: 'Fiction',
            forbidden_param: 'should not be allowed'
          }
        }

        created_book = Book.last
        expect(created_book.title).to eq('Test')
        expect { created_book.forbidden_param }.to raise_error(NoMethodError)
      end
    end
  end

  describe 'error handling' do
    before { sign_in librarian_user }

    it 'handles database errors gracefully' do
      allow(Book).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

      get :show, params: { id: 99999 }

      expect(response).to have_http_status(:not_found)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['error']).to eq('Book not found')
    end
  end

  describe 'JSON response format' do
    before { sign_in member_user }

    it 'returns properly formatted JSON' do
      get :index

      expect(response.content_type).to include('application/json')
      expect { JSON.parse(response.body) }.not_to raise_error
    end

    it 'includes consistent timestamp format' do
      test_book = create(:book)
      get :show, params: { id: test_book.id }

      parsed_response = JSON.parse(response.body)
      book_data = parsed_response['book']

      expect(book_data['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(book_data['updated_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end

    describe 'filtering functionality' do
    before { sign_in member_user }

    let!(:fantasy_book) { create(:book, title: 'The Lord of the Rings', author: 'J.R.R. Tolkien', genre: 'Fantasy') }
    let!(:science_book) { create(:book, title: 'A Brief History of Time', author: 'Stephen Hawking', genre: 'Science') }
    let!(:mystery_book) { create(:book, title: 'The Murder of Roger Ackroyd', author: 'Agatha Christie', genre: 'Mystery') }
    let!(:another_tolkien) { create(:book, title: 'The Hobbit', author: 'J.R.R. Tolkien', genre: 'Fantasy') }

    describe 'title filtering' do
      it 'filters books by title (case insensitive)' do
        get :index, params: { title: 'lord' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['title']).to eq('The Lord of the Rings')
      end

      it 'filters books by partial title match' do
        get :index, params: { title: 'the' }

        parsed_response = JSON.parse(response.body)
        titles = parsed_response['books'].map { |b| b['title'] }
        expect(titles).to include('The Lord of the Rings', 'The Murder of Roger Ackroyd', 'The Hobbit')
        expect(titles).not_to include('A Brief History of Time')
      end

      it 'returns empty array when no titles match' do
        get :index, params: { title: 'nonexistent' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books']).to be_empty
      end

      it 'includes applied title filter in response' do
        get :index, params: { title: 'lord' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['filters']['title']).to eq('lord')
      end
    end

    describe 'author filtering' do
      it 'filters books by author (case insensitive)' do
        get :index, params: { author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(2)
        authors = parsed_response['books'].map { |b| b['author'] }.uniq
        expect(authors).to eq(['J.R.R. Tolkien'])
      end

      it 'filters books by partial author match' do
        get :index, params: { author: 'christie' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['author']).to eq('Agatha Christie')
      end

      it 'returns empty array when no authors match' do
        get :index, params: { author: 'nonexistent author' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books']).to be_empty
      end

      it 'includes applied author filter in response' do
        get :index, params: { author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['filters']['author']).to eq('tolkien')
      end
    end

    describe 'genre filtering' do
      it 'filters books by genre (case insensitive)' do
        get :index, params: { genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(2)
        genres = parsed_response['books'].map { |b| b['genre'] }.uniq
        expect(genres).to eq(['Fantasy'])
      end

      it 'filters books by exact genre match' do
        get :index, params: { genre: 'Science' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['genre']).to eq('Science')
      end

      it 'returns empty array when no genres match' do
        get :index, params: { genre: 'Horror' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books']).to be_empty
      end

      it 'includes applied genre filter in response' do
        get :index, params: { genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['filters']['genre']).to eq('fantasy')
      end
    end

    describe 'multiple filters' do
      it 'applies multiple filters simultaneously' do
        get :index, params: { author: 'tolkien', genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(2)
        
        books = parsed_response['books']
        expect(books.all? { |b| b['author'] == 'J.R.R. Tolkien' }).to be true
        expect(books.all? { |b| b['genre'] == 'Fantasy' }).to be true
      end

      it 'narrows results with multiple filters' do
        get :index, params: { title: 'lord', author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['title']).to eq('The Lord of the Rings')
      end

      it 'returns empty when filters don\'t match any books' do
        get :index, params: { author: 'tolkien', genre: 'science' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books']).to be_empty
      end

      it 'includes all applied filters in response' do
        get :index, params: { title: 'lord', author: 'tolkien', genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        filters = parsed_response['filters']
        expect(filters['title']).to eq('lord')
        expect(filters['author']).to eq('tolkien')
        expect(filters['genre']).to eq('fantasy')
      end
    end

    describe 'filters with pagination' do
      it 'applies filters before pagination' do
        get :index, params: { author: 'tolkien', per_page: 1, page: 1 }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['meta']['total_count']).to eq(2)
        expect(parsed_response['meta']['total_pages']).to eq(2)
      end

      it 'maintains filters across pagination pages' do
        get :index, params: { author: 'tolkien', per_page: 1, page: 2 }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['author']).to eq('J.R.R. Tolkien')
        expect(parsed_response['filters']['author']).to eq('tolkien')
      end
    end

    describe 'empty and whitespace filters' do
      it 'ignores empty string filters' do
        get :index, params: { title: '', author: 'tolkien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(2)
        expect(parsed_response['filters']).to eq({ 'author' => 'tolkien' })
      end

      it 'ignores whitespace-only filters' do
        get :index, params: { title: '   ', genre: 'fantasy' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(2)
        expect(parsed_response['filters']).to eq({ 'genre' => 'fantasy' })
      end

      it 'trims whitespace from filter values' do
        get :index, params: { author: '  tolkien  ' }

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['books'].length).to eq(2)
        expect(parsed_response['filters']['author']).to eq('tolkien')
      end
    end

    describe 'special characters in filters' do
      let!(:special_book) { create(:book, title: 'Book with "Quotes" & Symbols', author: 'O\'Brien, John', genre: 'Sci-Fi') }

      it 'handles quotes in filter values' do
        get :index, params: { title: 'quotes' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['title']).to eq('Book with "Quotes" & Symbols')
      end

      it 'handles apostrophes in filter values' do
        get :index, params: { author: 'brien' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['author']).to eq('O\'Brien, John')
      end

      it 'handles hyphens in filter values' do
        get :index, params: { genre: 'sci-fi' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(1)
        expect(parsed_response['books'].first['genre']).to eq('Sci-Fi')
      end
    end

    describe 'performance with filters' do
      it 'efficiently handles large datasets with filters' do
        # Create many books
        create_list(:book, 50, author: 'Test Author', genre: 'Test Genre')
        create_list(:book, 30, author: 'Other Author', genre: 'Other Genre')

        expect {
          get :index, params: { author: 'test author', per_page: 20 }
          expect(response).to have_http_status(:ok)
        }.not_to raise_error

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['books'].length).to eq(20)
        expect(parsed_response['meta']['total_count']).to eq(50)
      end
    end
  end
end
