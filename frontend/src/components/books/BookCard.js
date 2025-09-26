import React from 'react';

const BookCard = ({ book, onReserve, reservationLoading, selectedBook }) => (
  <div className="book-card">
    <div className="book-card-header">
      <h3 className="book-card-title">{book.title}</h3>
      <p className="book-card-author">by {book.author}</p>
    </div>
    <div className="book-card-content">
      {book.genre && (
        <p className="book-card-genre">
          <span className="book-card-label">Genre:</span> {book.genre}
        </p>
      )}
      {book.isbn && (
        <p className="book-card-isbn">
          <span className="book-card-label">ISBN:</span> {book.isbn}
        </p>
      )}
      {book.publication_year && (
        <p className="book-card-year">
          <span className="book-card-label">Published:</span> {book.publication_year}
        </p>
      )}
    </div>
    <div className="book-card-footer">
      <div className="book-card-availability">
        {book.available_copies > 0 ? (
          <span className="book-card-available">
            {book.available_copies} available
          </span>
        ) : (
          <span className="book-card-unavailable">
            Currently unavailable
          </span>
        )}
      </div>
      <button
        className="book-card-reserve-btn"
        disabled={book.available_copies === 0 || reservationLoading}
        onClick={() => onReserve(book)}
      >
        {reservationLoading && selectedBook?.id === book.id
          ? 'Reserving...'
          : book.available_copies > 0 ? 'Reserve' : 'Unavailable'}
      </button>
    </div>
  </div>
);

export default BookCard;
