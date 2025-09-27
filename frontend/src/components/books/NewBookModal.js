import React, { useState } from 'react';
import apiService from '../../services/apiService';

function NewBookModal({
  show,
  onClose,
  fetchBooks, // Pass fetchBooks from parent if you want to refresh the list after adding
}) {
  const [newBook, setNewBook] = useState({
    title: "",
    author: "",
    isbn: "",
    year: "",
    genre: "",
    edition: "",
    publisher: "",
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);
  const [error, setError] = useState(null);

  const handleNewBookChange = (e) => {
    setNewBook({ ...newBook, [e.target.name]: e.target.value });
  };

  const handleNewBookSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    setError(null);

    try {
      const response = await apiService.createBook({
        title: newBook.title,
        author: newBook.author,
        isbn: newBook.isbn,
        year: newBook.year,
        genre: newBook.genre,
        edition: newBook.edition,
        publisher: newBook.publisher,
      });
      setMessage(response.message || "Book created successfully");
      setNewBook({
        title: "",
        author: "",
        isbn: "",
        year: "",
        genre: "",
        edition: "",
        publisher: "",
      });
      if (fetchBooks) fetchBooks();
    } catch (err) {
      setError("Network error");
    } finally {
      setLoading(false);
    }
  };

  if (!show) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-xl shadow-lg w-full max-w-md p-6 relative">
        <button
          className="absolute top-3 right-3 text-gray-400 hover:text-gray-700 text-2xl"
          onClick={() => {
            onClose();
            setMessage(null);
            setError(null);
          }}
          aria-label="Close"
        >
          &times;
        </button>
        <h2 className="text-xl font-bold mb-4">Add New Book</h2>
        <form onSubmit={handleNewBookSubmit} className="space-y-3">
          <input
            className="w-full border rounded px-3 py-2"
            name="title"
            placeholder="Title"
            value={newBook.title}
            onChange={handleNewBookChange}
            required
          />
          <input
            className="w-full border rounded px-3 py-2"
            name="author"
            placeholder="Author"
            value={newBook.author}
            onChange={handleNewBookChange}
            required
          />
          <input
            className="w-full border rounded px-3 py-2"
            name="isbn"
            placeholder="ISBN"
            value={newBook.isbn}
            onChange={handleNewBookChange}
            required
          />
          <input
            className="w-full border rounded px-3 py-2"
            name="year"
            placeholder="Year"
            type="number"
            value={newBook.year}
            onChange={handleNewBookChange}
            required
          />
          <input
            className="w-full border rounded px-3 py-2"
            name="genre"
            placeholder="Genre"
            value={newBook.genre}
            onChange={handleNewBookChange}
            required
          />
          <input
            className="w-full border rounded px-3 py-2"
            name="edition"
            placeholder="Edition"
            value={newBook.edition}
            onChange={handleNewBookChange}
            required
          />
          <input
            className="w-full border rounded px-3 py-2"
            name="publisher"
            placeholder="Publisher"
            value={newBook.publisher}
            onChange={handleNewBookChange}
            required
          />
          <button
            type="submit"
            className="w-full bg-indigo-600 text-white font-semibold rounded py-2 mt-2 hover:bg-indigo-700 transition"
            disabled={loading}
          >
            {loading ? "Adding..." : "Add Book"}
          </button>
        </form>
        {message && (
          <div className="mt-4 text-green-600 text-center">{message}</div>
        )}
        {error && (
          <div className="mt-4 text-red-600 text-center">{error}</div>
        )}
      </div>
    </div>
  );
}

export default NewBookModal;
