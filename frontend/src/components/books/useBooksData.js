import { useState, useEffect } from 'react';
import apiService, { ApiError } from '../../services/apiService';

export default function useBooksData({ perPage }) {
  const [books, setBooks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchType, setSearchType] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalBooks, setTotalBooks] = useState(0);

  useEffect(() => {
    fetchBooks();
    // eslint-disable-next-line
  }, [currentPage, searchQuery, searchType]);

  const fetchBooks = async (customError = null) => {
    try {
      setIsLoading(true);
      setError(customError);
      const params = { page: currentPage, per_page: perPage };
      if (searchQuery.trim()) {
        if (searchType === 'all') {
          params.search = searchQuery.trim();
        } else {
          params[searchType] = searchQuery.trim();
        }
      }
      const response = await apiService.getBooks(params);
      if (response.books) {
        setBooks(response.books || []);
        setTotalPages(response.meta?.total_pages || 1);
        setTotalBooks(response.meta?.total_count || 0);
      } else if (Array.isArray(response)) {
        setBooks(response);
        setTotalPages(1);
        setTotalBooks(response.length);
      } else {
        setBooks([]);
        setTotalPages(1);
        setTotalBooks(0);
      }
    } catch (error) {
      setBooks([]);
      if (error instanceof ApiError) {
        setError(error.message);
      } else {
        setError('Failed to load books. Please try again.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return {
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
  };
}
