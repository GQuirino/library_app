
import React, { useState } from 'react';
import NavBar from '../navbar/NavBar';
import useBooksData from './useBooksData';
import BookCard from './BookCard';
import ReservationModal from './ReservationModal';
import apiService, { ApiError } from '../../services/apiService';
import './Books.css';


const Books = ({ user, onLogout }) => {
  const [showReservationModal, setShowReservationModal] = useState(false);
  const [reservationLoading, setReservationLoading] = useState(false);
  const [reservationSuccess, setReservationSuccess] = useState(null);
  const [selectedBook, setSelectedBook] = useState(null);
  const perPage = 12;
  const {
    books,
    isLoading,
    error,
    setError,
    searchQuery,
    setSearchQuery,
    searchType,
    setSearchType,
    currentPage,
    setCurrentPage,
    totalPages,
    totalBooks,
    fetchBooks,
  } = useBooksData({ perPage });

  const handleSearch = (e) => {
    e.preventDefault();
    setCurrentPage(1);
    fetchBooks();
  };

  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value);
    if (e.target.value === '') {
      setCurrentPage(1);
      setTimeout(() => {
        if (searchQuery === '') {
          fetchBooks();
        }
      }, 300);
    }
  };

  const handlePageChange = (newPage) => {
    setCurrentPage(newPage);
  };

  const handleSearchTypeChange = (e) => {
    setSearchType(e.target.value);
    setCurrentPage(1);
  };

  const handleReserveBook = async (book) => {
    try {
      setReservationLoading(true);
      setSelectedBook(book);
      const returnDate = new Date();
      returnDate.setDate(returnDate.getDate() + 14);
      const reservationData = {
        book_id: book.id,
        user_id: user.id,
        return_date: returnDate.toISOString().split('T')[0]
      };
      const response = await apiService.createReservation(reservationData);
      const bookCopyResponse = await apiService.getBookCopy(response.book_copy_id);
      setReservationSuccess({
        book: book,
        bookCopy: bookCopyResponse.book_copy,
        returnDate: returnDate,
        reservation: response
      });
      setShowReservationModal(true);
      fetchBooks();
    } catch (error) {
      if (error instanceof ApiError) {
        setError(error.message);
      } else {
        setError('Failed to reserve book. Please try again.');
      }
    } finally {
      setReservationLoading(false);
    }
  };

  const closeModal = () => {
    setShowReservationModal(false);
    setReservationSuccess(null);
    setSelectedBook(null);
  };

  const renderPagination = () => {
    if (totalPages <= 1) return null;
    const pages = [];
    const maxVisiblePages = 5;
    let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
    let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
    if (endPage - startPage + 1 < maxVisiblePages) {
      startPage = Math.max(1, endPage - maxVisiblePages + 1);
    }
    pages.push(
      <button
        key="prev"
        onClick={() => handlePageChange(currentPage - 1)}
        disabled={currentPage === 1}
        className="books-pagination-btn books-pagination-btn--nav"
      >
        Previous
      </button>
    );
    for (let i = startPage; i <= endPage; i++) {
      pages.push(
        <button
          key={i}
          onClick={() => handlePageChange(i)}
          className={`books-pagination-btn ${
            i === currentPage ? 'books-pagination-btn--active' : ''
          }`}
        >
          {i}
        </button>
      );
    }
    pages.push(
      <button
        key="next"
        onClick={() => handlePageChange(currentPage + 1)}
        disabled={currentPage === totalPages}
        className="books-pagination-btn books-pagination-btn--nav"
      >
        Next
      </button>
    );
    return (
      <div className="books-pagination">
        {pages}
      </div>
    );
  };

  return (
    <div className="books-container">
      <NavBar user={user} onLogout={onLogout} />

      <div className="books-main">
        <div className="books-content">
          <div className="books-header">
            <h1 className="books-title">Library Books</h1>
            
            {/* Search Section */}
            <div className="books-search-section">
              <form onSubmit={handleSearch} className="books-search-form">
                <div className="books-search-controls">
                  <select
                    value={searchType}
                    onChange={handleSearchTypeChange}
                    className="books-search-type"
                  >
                    <option value="all">All Fields</option>
                    <option value="title">Title</option>
                    <option value="author">Author</option>
                    <option value="genre">Genre</option>
                  </select>
                  
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={handleSearchChange}
                    placeholder={`Search by ${searchType === 'all' ? 'title, author, or genre' : searchType}...`}
                    className="books-search-input"
                  />
                  
                  <button
                    type="submit"
                    className="books-search-btn"
                  >
                    <svg className="books-search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    Search
                  </button>
                </div>
              </form>
              
              {/* Results Info */}
              {!isLoading && (
                <div className="books-results-info">
                  {searchQuery ? (
                    <p>Found {totalBooks} books matching "{searchQuery}"</p>
                  ) : (
                    <p>Showing {totalBooks} books total</p>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Loading State */}
          {isLoading && (
            <div className="books-loading">
              <div className="books-loading-spinner"></div>
              <span className="books-loading-text">Loading books...</span>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="books-error">
              <div className="books-error-content">
                <div className="books-error-icon">
                  <svg className="books-error-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z" />
                  </svg>
                </div>
                <div className="books-error-message-wrapper">
                  <p className="books-error-message">{error}</p>
                </div>
              </div>
            </div>
          )}

          {/* Books Grid */}
          {!isLoading && !error && (
            books.length > 0 ? (
              <>
                <div className="books-grid">
                  {books.map((book) => (
                    <BookCard
                      key={book.id}
                      book={book}
                      onReserve={handleReserveBook}
                      reservationLoading={reservationLoading}
                      selectedBook={selectedBook}
                    />
                  ))}
                </div>
                {renderPagination()}
              </>
            ) : (
              <div className="books-empty">
                <svg className="books-empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
                <h3 className="books-empty-title">
                  {searchQuery ? 'No books found' : 'No books available'}
                </h3>
                <p className="books-empty-description">
                  {searchQuery 
                    ? 'Try adjusting your search terms or search criteria.'
                    : 'There are currently no books in the library catalog.'}
                </p>
              </div>
            )
          )}
        </div>
      </div>

      {/* Reservation Success Modal */}
      <ReservationModal
        show={showReservationModal && reservationSuccess}
        onClose={closeModal}
        reservationSuccess={reservationSuccess}
      />
    </div>
  );
};

export default Books;
