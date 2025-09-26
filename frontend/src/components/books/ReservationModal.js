import React from 'react';

const ReservationModal = ({ show, onClose, reservationSuccess }) => {
  if (!show || !reservationSuccess) return null;
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">Book Reserved Successfully!</h2>
          <button className="modal-close" onClick={onClose}>×</button>
        </div>
        <div className="modal-body">
          <div className="reservation-success-icon">
            <svg className="success-checkmark" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div className="reservation-details">
            <h3 className="reservation-book-title">{reservationSuccess.book.title}</h3>
            <p className="reservation-book-author">by {reservationSuccess.book.author}</p>
            <div className="reservation-info">
              <div className="reservation-info-item">
                <span className="reservation-info-label">Book Copy Serial:</span>
                <span className="reservation-info-value">{reservationSuccess.bookCopy.book_serial_number}</span>
              </div>
              <div className="reservation-info-item">
                <span className="reservation-info-label">Estimated Return Date:</span>
                <span className="reservation-info-value">
                  {reservationSuccess.returnDate.toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })}
                </span>
              </div>
            </div>
          </div>
        </div>
        <div className="modal-footer">
          <button className="modal-btn modal-btn-primary" onClick={onClose}>
            Great, Thank You!
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReservationModal;
