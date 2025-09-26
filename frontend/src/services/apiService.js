// API service for handling all backend communications
import config from '../config/api';
import tokenService from './tokenService';

class ApiService {
  constructor() {
    this.baseURL = config.API_BASE_URL;
    this.endpoints = config.endpoints;
    this.defaults = config.defaults;
    this.tokenService = tokenService;
  }

  // Generic request method
  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    
    // Determine if this endpoint requires authentication
    const requiresAuth = !this.isPublicEndpoint(endpoint);
    
    const requestConfig = {
      headers: {
        ...this.defaults.headers,
        ...(requiresAuth ? this.tokenService.getAuthHeader() : {}),
        ...options.headers,
      },
      ...options,
    };

    try {
      const response = await fetch(url, requestConfig);
      
      // Handle different response types
      if (!response.ok) {
        const error = await this.handleError(response);
        throw error;
      }

      // Handle empty responses
      if (response.status === 204) {
        return null;
      }

      return await response.json();
    } catch (error) {
      // Re-throw API errors
      if (error.name === 'ApiError') {
        throw error;
      }
      
      // Handle network errors
      if (error.name === 'TypeError' && error.message.includes('fetch')) {
        throw new ApiError(
          'Unable to connect to server. Please check if the backend is running.',
          'NETWORK_ERROR',
          0
        );
      }
      
      // Handle other errors
      throw new ApiError(
        'An unexpected error occurred. Please try again.',
        'UNKNOWN_ERROR',
        0
      );
    }
  }

  // Check if endpoint is public (doesn't require authentication)
  isPublicEndpoint(endpoint) {
    const publicEndpoints = [
      this.endpoints.login,
      this.endpoints.signup,
      this.endpoints.logout
    ];
    return publicEndpoints.includes(endpoint);
  }

  async handleError(response) {
    let errorData;
    
    try {
      errorData = await response.json();
    } catch {
      errorData = { message: 'An error occurred' };
    }

    // Handle 401 Unauthorized - token expired or invalid
    if (response.status === 401) {
      this.tokenService.removeToken();
      // Emit custom event for 401 errors that auth context can listen to
      window.dispatchEvent(new CustomEvent('unauthorized'));
    }

    // Handle 422 validation errors - your backend sends {"errors": ["message"]}
    if (response.status === 422 && errorData.errors) {
      const errorMessage = Array.isArray(errorData.errors) 
        ? errorData.errors.join(', ') 
        : errorData.errors;

      const error = new ApiError(
        errorMessage,
        'VALIDATION_ERROR',
        422,
        errorData.errors
      );
      return error;
    }

    const error = new ApiError(
      errorData.message || errorData.error || `HTTP error! status: ${response.status}`,
      response.status === 422 ? 'VALIDATION_ERROR' : 'API_ERROR',
      response.status,
      errorData.errors || null
    );

    return error;
  }

  // Authentication methods
  async signup(userData) {
    console.log('Signing up user with data:', userData);
    console.log('endpoint:', this.endpoints.signup);
    const response = await this.request(this.endpoints.signup, {
      method: 'POST',
      body: JSON.stringify({
        user: {
          name: userData.name,
          email: userData.email,
          password: userData.password,
          password_confirmation: userData.confirmPassword,
          phone_number: userData.phoneNumber,
          birthdate: userData.birthdate,
          address: {
            street: userData.address.street,
            city: userData.address.city,
            state: userData.address.state,
            zip: userData.address.zip
          }
        }
      })
    });

    // Store token if present in response (auto-login after signup)
    if (response.token) {
      this.tokenService.setToken(response.token);
    }

    return response;
  }

  async login(credentials) {
    const response = await this.request(this.endpoints.login, {
      method: 'POST',
      body: JSON.stringify({
        user: {
          email: credentials.email,
          password: credentials.password
        }
      })
    });

    // Store token if present in response
    if (response.token) {
      this.tokenService.setToken(response.token);
    }

    return response;
  }

  async logout() {
    try {
      const response = await this.request(this.endpoints.logout, {
        method: 'DELETE'
      });
      return response;
    } finally {
      // Always remove token on logout, even if API call fails
      this.tokenService.removeToken();
    }
  }

  // Check if user is authenticated
  isAuthenticated() {
    return this.tokenService.hasToken();
  }

  // Clear authentication (useful for handling 401 errors)
  clearAuth() {
    this.tokenService.removeToken();
  }

  // Dashboard methods
  async getDashboardData() {
    return this.request(this.endpoints.dashboard);
  }

  async getLibrarianDashboard() {
    return this.request(this.endpoints.dashboard);
  }

  // Books methods
  async getBooks(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `${this.endpoints.books}?${queryString}` : this.endpoints.books;
    return this.request(endpoint);
  }

  async getBook(id) {
    return this.request(this.endpoints.book(id));
  }

  async createBook(bookData) {
    return this.request(this.endpoints.books, {
      method: 'POST',
      body: JSON.stringify({ book: bookData })
    });
  }

  async updateBook(id, bookData) {
    return this.request(this.endpoints.book(id), {
      method: 'PATCH',
      body: JSON.stringify({ book: bookData })
    });
  }

  async deleteBook(id) {
    return this.request(this.endpoints.book(id), {
      method: 'DELETE'
    });
  }

  // Book Copies methods
  async getBookCopies(bookId) {
    return this.request(this.endpoints.bookCopies(bookId));
  }

  async getBookCopy(id) {
    return this.request(this.endpoints.bookCopy(id));
  }

  async createBookCopy(bookId, bookCopyData) {
    return this.request(this.endpoints.bookCopies(bookId), {
      method: 'POST',
      body: JSON.stringify({ book_copy: bookCopyData })
    });
  }

  async updateBookCopy(bookId, id, bookCopyData) {
    return this.request(this.endpoints.bookCopy(bookId, id), {
      method: 'PATCH',
      body: JSON.stringify({ book_copy: bookCopyData })
    });
  }

  async deleteBookCopy(bookId, id) {
    return this.request(this.endpoints.bookCopy(bookId, id), {
      method: 'DELETE'
    });
  }

  // Reservations methods
  async getReservations(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `${this.endpoints.reservations}?${queryString}` : this.endpoints.reservations;
    return this.request(endpoint);
  }

  async getReservation(id) {
    return this.request(this.endpoints.reservation(id));
  }

  async createReservation(reservationData) {
    return this.request(this.endpoints.createReservation, {
      method: 'POST',
      body: JSON.stringify({ reservation: reservationData })
    });
  }

  async returnBook(reservationId) {
    return this.request(this.endpoints.returnBook(reservationId), {
      method: 'PATCH'
    });
  }
}

// Custom Error class for API errors
class ApiError extends Error {
  constructor(message, code, status, validationErrors = null) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.status = status;
    this.validationErrors = validationErrors;
  }

  // Helper method to check if error is validation error
  isValidationError() {
    return this.code === 'VALIDATION_ERROR';
  }

  // Helper method to check if error is network error
  isNetworkError() {
    return this.code === 'NETWORK_ERROR';
  }

  // Helper method to get formatted validation errors
  getFormattedValidationErrors() {
    if (!this.validationErrors) return {};

    if (Array.isArray(this.validationErrors)) {
      return { general: this.validationErrors.join(' ') };
    }

    const formattedErrors = {};
    Object.keys(this.validationErrors).forEach(key => {
      const messages = this.validationErrors[key];
      if (Array.isArray(messages)) {
        formattedErrors[key] = messages[0]; // Take first error message
      } else {
        formattedErrors[key] = messages;
      }
    });
    
    return formattedErrors;
  }
}

// Export singleton instance
const apiService = new ApiService();
export { apiService, ApiError };
export default apiService;
