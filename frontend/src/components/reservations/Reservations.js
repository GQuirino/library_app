
import React, { useState, useCallback, useMemo } from 'react';
import apiService, { ApiError } from '../../services/apiService';
import NavBar from '../navbar/NavBar';
import './Reservations.css';

// Custom hook for fetching reservations
function useReservations({
  filter,
  searchQuery,
  userId,
  bookId,
  bookCopyId,
  returnDateStart,
  returnDateEnd,
  currentPage,
  perPage
}) {
  const [reservations, setReservations] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [totalPages, setTotalPages] = useState(1);

  const fetchReservations = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      const params = { page: currentPage, per_page: perPage };
      if (filter !== 'all') {
        if (filter === 'overdue') params.overdue = true;
        else params.status = filter;
      }
      if (searchQuery.trim()) params.search = searchQuery.trim();
      if (userId.trim()) params.user_id = userId.trim();
      if (bookId.trim()) params.book_id = bookId.trim();
      if (bookCopyId.trim()) params.book_copy_id = bookCopyId.trim();
      if (returnDateStart && returnDateEnd) {
        params.return_date_range_start = returnDateStart;
        params.return_date_range_end = returnDateEnd;
      } else if (returnDateStart) {
        params.return_date_range_start = returnDateStart;
      } else if (returnDateEnd) {
        params.return_date_range_end = returnDateEnd;
      }
      const response = await apiService.getReservations(params);
      if (response.reservations) {
        setReservations(response.reservations);
        setTotalPages(Math.ceil((response.total || response.reservations.length) / perPage));
      } else if (Array.isArray(response)) {
        setReservations(response);
        setTotalPages(1);
      } else {
        setReservations([]);
        setTotalPages(1);
      }
    } catch (error) {
      if (error instanceof ApiError) setError(error.message);
      else setError('Failed to load reservations. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [filter, searchQuery, userId, bookId, bookCopyId, returnDateStart, returnDateEnd, currentPage, perPage]);

  React.useEffect(() => {
    fetchReservations();
    // eslint-disable-next-line
  }, [fetchReservations]);

  return { reservations, isLoading, error, setError, totalPages, fetchReservations };
}


// Presentational components
const ReservationsHeader = () => (
  <div className="reservations-header">
    <h1>All Reservations</h1>
    <p className="reservations-subtitle">
      Manage and track all book reservations in the library
    </p>
  </div>
);

const ReservationsControls = ({
  searchQuery, setSearchQuery, handleSearchSubmit,
  filter, setFilter, setCurrentPage,
  showAdvancedFilters, setShowAdvancedFilters
}) => (
  <div className="reservations-controls">
    <form onSubmit={handleSearchSubmit} className="search-form">
      <input
        type="text"
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        placeholder="Search by member name, book title, or author..."
        className="search-input"
      />
      <button type="submit" className="search-button">
        <svg className="search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </button>
    </form>
    <div className="filter-controls">
      <label htmlFor="filter-select">Status:</label>
      <select
        id="filter-select"
        value={filter}
        onChange={(e) => {
          setFilter(e.target.value);
          setCurrentPage(1);
        }}
        className="filter-select"
      >
        <option value="all">All Reservations</option>
        <option value="active">Active</option>
        <option value="overdue">Overdue</option>
      </select>
    </div>
    <div className="advanced-filters-toggle">
      <button
        type="button"
        onClick={() => setShowAdvancedFilters(!showAdvancedFilters)}
        className="toggle-button"
      >
        {showAdvancedFilters ? 'Hide' : 'Show'} Advanced Filters
        <svg 
          className={`toggle-icon ${showAdvancedFilters ? 'rotated' : ''}`} 
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>
    </div>
  </div>
);

const AdvancedFilters = ({
  userId, setUserId, bookId, setBookId, bookCopyId, setBookCopyId,
  returnDateStart, setReturnDateStart, returnDateEnd, setReturnDateEnd,
  clearAllFilters, setCurrentPage
}) => (
  <div className="advanced-filters">
    <div className="advanced-filters-header">
      <h3>Advanced Filters</h3>
      <button onClick={clearAllFilters} className="clear-filters-button">
        Clear All Filters
      </button>
    </div>
    <div className="advanced-filters-grid">
      <div className="filter-group">
        <label htmlFor="user-id-input">User ID:</label>
        <input
          id="user-id-input"
          type="number"
          value={userId}
          onChange={(e) => {
            setUserId(e.target.value);
            setCurrentPage(1);
          }}
          placeholder="Enter user ID"
          className="filter-input"
        />
      </div>
      <div className="filter-group">
        <label htmlFor="book-id-input">Book ID:</label>
        <input
          id="book-id-input"
          type="number"
          value={bookId}
          onChange={(e) => {
            setBookId(e.target.value);
            setCurrentPage(1);
          }}
          placeholder="Enter book ID"
          className="filter-input"
        />
      </div>
      <div className="filter-group">
        <label htmlFor="book-copy-id-input">Book Copy ID:</label>
        <input
          id="book-copy-id-input"
          type="number"
          value={bookCopyId}
          onChange={(e) => {
            setBookCopyId(e.target.value);
            setCurrentPage(1);
          }}
          placeholder="Enter book copy ID"
          className="filter-input"
        />
      </div>
      <div className="filter-group">
        <label htmlFor="return-date-start">Return Date From:</label>
        <input
          id="return-date-start"
          type="date"
          value={returnDateStart}
          onChange={(e) => {
            setReturnDateStart(e.target.value);
            setCurrentPage(1);
          }}
          className="filter-input"
        />
      </div>
      <div className="filter-group">
        <label htmlFor="return-date-end">Return Date To:</label>
        <input
          id="return-date-end"
          type="date"
          value={returnDateEnd}
          onChange={(e) => {
            setReturnDateEnd(e.target.value);
            setCurrentPage(1);
          }}
          className="filter-input"
        />
      </div>
    </div>
  </div>
);

const ResultsSummary = ({
  filteredCount, filter, searchQuery, userId, bookId, bookCopyId, returnDateStart, returnDateEnd,
  setFilter, setSearchQuery, setUserId, setBookId, setBookCopyId, setReturnDateStart, setReturnDateEnd
}) => (
  <div className="results-summary">
    <div className="summary-info">
      <p>
        Showing {filteredCount} reservation{filteredCount !== 1 ? 's' : ''}
        {filter !== 'all' && ` (${filter})`}
      </p>
    </div>
    {(searchQuery || userId || bookId || bookCopyId || returnDateStart || returnDateEnd || filter !== 'all') && (
      <div className="active-filters">
        <span className="active-filters-label">Active filters:</span>
        <div className="filter-tags">
          {filter !== 'all' && (
            <span className="filter-tag">
              Status: {filter}
              <button onClick={() => setFilter('all')} className="remove-filter">×</button>
            </span>
          )}
          {searchQuery && (
            <span className="filter-tag">
              Search: {searchQuery}
              <button onClick={() => setSearchQuery('')} className="remove-filter">×</button>
            </span>
          )}
          {userId && (
            <span className="filter-tag">
              User ID: {userId}
              <button onClick={() => setUserId('')} className="remove-filter">×</button>
            </span>
          )}
          {bookId && (
            <span className="filter-tag">
              Book ID: {bookId}
              <button onClick={() => setBookId('')} className="remove-filter">×</button>
            </span>
          )}
          {bookCopyId && (
            <span className="filter-tag">
              Copy ID: {bookCopyId}
              <button onClick={() => setBookCopyId('')} className="remove-filter">×</button>
            </span>
          )}
          {returnDateStart && (
            <span className="filter-tag">
              From: {returnDateStart}
              <button onClick={() => setReturnDateStart('')} className="remove-filter">×</button>
            </span>
          )}
          {returnDateEnd && (
            <span className="filter-tag">
              To: {returnDateEnd}
              <button onClick={() => setReturnDateEnd('')} className="remove-filter">×</button>
            </span>
          )}
        </div>
      </div>
    )}
  </div>
);

const ErrorBanner = ({ error, setError }) => error ? (
  <div className="error-banner">
    <p>{error}</p>
    <button onClick={() => setError(null)} className="dismiss-error">×</button>
  </div>
) : null;

const EmptyState = ({ searchQuery }) => (
  <div className="empty-state">
    <svg className="empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
    </svg>
    <h3>No reservations found</h3>
    <p>
      {searchQuery ? 'Try adjusting your search criteria.' : 'No reservations match the current filter.'}
    </p>
  </div>
);

const Loading = () => (
  <div className="loading-container">
    <div className="loading-spinner"></div>
    <p>Loading reservations...</p>
  </div>
);

const LoadingOverlay = () => (
  <div className="loading-overlay">
    <div className="loading-spinner"></div>
  </div>
);

const StatusBadge = ({ reservation }) => {
  const today = new Date();
  const returnDate = new Date(reservation.return_date);
  if (reservation.returned_at) {
    return <span className="status-badge status-returned">Returned</span>;
  } else if (returnDate < today) {
    return <span className="status-badge status-overdue">Overdue</span>;
  } else {
    return <span className="status-badge status-active">Active</span>;
  }
};

const ReservationCard = ({ reservation, formatDate, handleReturnBook }) => (
  <div className="reservation-card">
    <div className="reservation-header">
      <div className="reservation-status">
        <StatusBadge reservation={reservation} />
      </div>
      <div className="reservation-id">#{reservation.id}</div>
    </div>
    <div className="reservation-content">
      <div className="book-info">
        <h3 className="book-title">{reservation.book_title}</h3>
        <p className="book-author">by {reservation.book_author}</p>
        <p className="book-serial">Serial: {reservation.book_serial_number}</p>
      </div>
      <div className="member-info">
        <h4 className="member-name">{reservation.user_name}</h4>
        <p className="member-email">{reservation.user_email}</p>
      </div>
      <div className="reservation-dates">
        <div className="date-item">
          <span className="date-label">Reserved:</span>
          <span className="date-value">{formatDate(reservation.created_at)}</span>
        </div>
        <div className="date-item">
          <span className="date-label">Due:</span>
          <span className="date-value">{formatDate(reservation.return_date)}</span>
        </div>
        {reservation.returned_at && (
          <div className="date-item">
            <span className="date-label">Returned:</span>
            <span className="date-value">{formatDate(reservation.returned_at)}</span>
          </div>
        )}
      </div>
    </div>
    <div className="reservation-actions">
      {!reservation.returned_at && (
        <button
          onClick={() => handleReturnBook(reservation.id)}
          className="return-button"
        >
          Mark as Returned
        </button>
      )}
    </div>
  </div>
);

const ReservationsList = ({ reservations, formatDate, handleReturnBook }) => (
  <div className="reservations-grid">
    {reservations.map((reservation) => (
      <ReservationCard
        key={reservation.id}
        reservation={reservation}
        formatDate={formatDate}
        handleReturnBook={handleReturnBook}
      />
    ))}
  </div>
);

const Pagination = ({ currentPage, totalPages, setCurrentPage }) => (
  <div className="pagination">
    <button
      onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
      disabled={currentPage === 1}
      className="pagination-button"
    >
      Previous
    </button>
    <span className="pagination-info">
      Page {currentPage} of {totalPages}
    </span>
    <button
      onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
      disabled={currentPage === totalPages}
      className="pagination-button"
    >
      Next
    </button>
  </div>
);

const Reservations = ({ user, onLogout }) => {
  const [filter, setFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [perPage] = useState(20);
  const [userId, setUserId] = useState('');
  const [bookId, setBookId] = useState('');
  const [bookCopyId, setBookCopyId] = useState('');
  const [returnDateStart, setReturnDateStart] = useState('');
  const [returnDateEnd, setReturnDateEnd] = useState('');
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false);

  const {
    reservations,
    isLoading,
    error,
    setError,
    totalPages,
    fetchReservations
  } = useReservations({
    filter,
    searchQuery,
    userId,
    bookId,
    bookCopyId,
    returnDateStart,
    returnDateEnd,
    currentPage,
    perPage
  });

  const handleReturnBook = useCallback(async (reservationId) => {
    try {
      await apiService.returnBook(reservationId);
      await fetchReservations();
    } catch (error) {
      if (error instanceof ApiError) setError(error.message);
      else setError('Failed to return book. Please try again.');
    }
  }, [fetchReservations, setError]);

  const handleSearchSubmit = useCallback((e) => {
    e.preventDefault();
    setCurrentPage(1);
    fetchReservations();
  }, [fetchReservations]);

  const clearAllFilters = useCallback(() => {
    setFilter('all');
    setSearchQuery('');
    setUserId('');
    setBookId('');
    setBookCopyId('');
    setReturnDateStart('');
    setReturnDateEnd('');
    setCurrentPage(1);
  }, []);

  const handleLogout = useCallback(async () => {
    try {
      await apiService.logout();
    } catch (error) {
      if (error instanceof ApiError) {
        // eslint-disable-next-line no-console
        console.error('Logout error:', error.message);
      } else {
        // eslint-disable-next-line no-console
        console.error('Logout error:', error);
      }
    } finally {
      onLogout();
    }
  }, [onLogout]);

  const formatDate = useCallback((dateString) => {
    return new Date(dateString).toLocaleDateString();
  }, []);

  const filteredCount = useMemo(() => reservations.length, [reservations]);

  if (isLoading && reservations.length === 0) {
    return (
      <div className="reservations-container">
        <NavBar user={user} onLogout={handleLogout} />
        <div className="reservations-content">
          <Loading />
        </div>
      </div>
    );
  }

  return (
    <div className="reservations-container">
      <NavBar user={user} onLogout={handleLogout} />
      <div className="reservations-content">
        <ReservationsHeader />
        <ReservationsControls
          searchQuery={searchQuery}
          setSearchQuery={setSearchQuery}
          handleSearchSubmit={handleSearchSubmit}
          filter={filter}
          setFilter={setFilter}
          setCurrentPage={setCurrentPage}
          showAdvancedFilters={showAdvancedFilters}
          setShowAdvancedFilters={setShowAdvancedFilters}
        />
        {showAdvancedFilters && (
          <AdvancedFilters
            userId={userId}
            setUserId={setUserId}
            bookId={bookId}
            setBookId={setBookId}
            bookCopyId={bookCopyId}
            setBookCopyId={setBookCopyId}
            returnDateStart={returnDateStart}
            setReturnDateStart={setReturnDateStart}
            returnDateEnd={returnDateEnd}
            setReturnDateEnd={setReturnDateEnd}
            clearAllFilters={clearAllFilters}
            setCurrentPage={setCurrentPage}
          />
        )}
        <ResultsSummary
          filteredCount={filteredCount}
          filter={filter}
          searchQuery={searchQuery}
          userId={userId}
          bookId={bookId}
          bookCopyId={bookCopyId}
          returnDateStart={returnDateStart}
          returnDateEnd={returnDateEnd}
          setFilter={setFilter}
          setSearchQuery={setSearchQuery}
          setUserId={setUserId}
          setBookId={setBookId}
          setBookCopyId={setBookCopyId}
          setReturnDateStart={setReturnDateStart}
          setReturnDateEnd={setReturnDateEnd}
        />
        <ErrorBanner error={error} setError={setError} />
        {reservations.length === 0 && !isLoading ? (
          <EmptyState searchQuery={searchQuery} />
        ) : (
          <ReservationsList
            reservations={reservations}
            formatDate={formatDate}
            handleReturnBook={handleReturnBook}
          />
        )}
        {totalPages > 1 && (
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            setCurrentPage={setCurrentPage}
          />
        )}
        {isLoading && reservations.length > 0 && <LoadingOverlay />}
      </div>
    </div>
  );
};

export default Reservations;
