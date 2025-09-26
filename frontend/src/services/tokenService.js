// Token management service for handling authentication tokens
class TokenService {
  constructor() {
    this.tokenKey = 'auth_token';
  }

  // Store token in localStorage
  setToken(token) {
    if (token) {
      localStorage.setItem(this.tokenKey, token);
    }
  }

  // Get token from localStorage
  getToken() {
    return localStorage.getItem(this.tokenKey);
  }

  // Remove token from localStorage
  removeToken() {
    localStorage.removeItem(this.tokenKey);
  }

  // Check if token exists
  hasToken() {
    return !!this.getToken();
  }

  // Get Authorization header with Bearer token
  getAuthHeader() {
    const token = this.getToken();
    return token ? { 'Authorization': `Bearer ${token}` } : {};
  }
}

// Export singleton instance
const tokenService = new TokenService();
export default tokenService;
