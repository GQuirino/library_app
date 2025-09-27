import React, { useEffect, useState } from 'react';
import apiService from '../../services/apiService';

function BookCopiesModal({ show, onClose, book }) {
  const [loading, setLoading] = useState(false);
  const [copies, setCopies] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!show || !book) return;
    setLoading(true);
    setError(null);
    setCopies([]);
    apiService.bookCopiesbyBook(book.id)
      .then((data) => {
        setCopies(data.book_copies || []);
      })
      .catch((err) => {
        setError(err.message || 'Failed to load book copies.');
      })
      .finally(() => setLoading(false));
  }, [show, book]);

  if (!show) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-xl shadow-lg w-full max-w-lg p-6 relative">
        <button
          className="absolute top-3 right-3 text-gray-400 hover:text-gray-700 text-2xl"
          onClick={onClose}
          aria-label="Close"
        >
          &times;
        </button>
        <h2 className="text-xl font-bold mb-4">
          Book Copies {book ? `- ${book.title}` : ""}
        </h2>
        {loading ? (
          <div className="text-center py-8">Loading copies...</div>
        ) : error ? (
          <div className="text-red-600 text-center py-8">{error}</div>
        ) : copies.length > 0 ? (
          <table className="w-full border mt-2">
            <thead>
              <tr>
                <th className="border px-3 py-2 text-left">ID</th>
                <th className="border px-3 py-2 text-left">Serial Number</th>
                <th className="border px-3 py-2 text-left">Available</th>
                <th className="border px-3 py-2 text-left">Created At</th>
              </tr>
            </thead>
            <tbody>
              {copies.map((copy) => (
                <tr key={copy.id}>
                  <td className="border px-3 py-2">{copy.id}</td>
                  <td className="border px-3 py-2">{copy.book_serial_number}</td>
                  <td className="border px-3 py-2">
                    {copy.available ? (
                      <span className="text-green-600 font-semibold">Yes</span>
                    ) : (
                      <span className="text-red-600 font-semibold">No</span>
                    )}
                  </td>
                  <td className="border px-3 py-2">{new Date(copy.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="text-center py-8">No copies found for this book.</div>
        )}
      </div>
    </div>
  );
}

export default BookCopiesModal;
