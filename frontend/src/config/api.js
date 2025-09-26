// API configuration
const config = {
  // API Base URL - can be overridden by environment variable
  API_BASE_URL: process.env.REACT_APP_API_URL || 'http://localhost:3001',
  
  // API Endpoints
  endpoints: {
    // Authentication
    signup: '/signup',
    login: '/login',
    logout: '/logout',
    
    // Dashboard
    dashboard: '/api/v1/dashboard',
    
    // Books
    books: '/api/v1/books',
    book: (id) => `/api/v1/books/${id}`,
    
    // Book Copies
    bookCopies: (bookId) => `/api/v1/books/${bookId}/book_copies`,
    bookCopy: (id) => `/api/v1/book_copies/${id}`,
    
    // Reservations
    reservations: '/api/v1/reservations',
    reservation: (id) => `/api/v1/reservations/${id}`,
    createReservation: '/api/v1/reservations/create',
    returnBook: (reservationId) => `/api/v1/reservations/${reservationId}/return`,
  },
  
  // Request defaults
  defaults: {
    timeout: 10000, // 10 seconds
    retries: 3,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
  }
};

export default config;
