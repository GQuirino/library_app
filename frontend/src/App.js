import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';
import apiService from './services/apiService';

// Import components
import Landing from './components/Landing';
import Login from './components/Login';
import SignUp from './components/SignUp';
import Books from './components/books/Books';
import Reservations from './components/reservations/Reservations';
import MemberDashboard from './components/dashboard/MemberDashboard';
import LibrarianDashboard from './components/dashboard/LibrarianDashboard';

function App() {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Check if user is logged in when app loads
  useEffect(() => {
    const savedUser = localStorage.getItem('user');
    const isAuthenticated = apiService.isAuthenticated();
    
    if (savedUser && isAuthenticated) {
      try {
        setUser(JSON.parse(savedUser));
      } catch (error) {
        localStorage.removeItem('user');
        apiService.clearAuth();
      }
    } else {
      // Clear everything if token is missing
      localStorage.removeItem('user');
      apiService.clearAuth();
    }
    setIsLoading(false);
  }, []);

  // Handle login
  const handleLogin = (userData) => {
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
  };

  // Handle logout
  const handleLogout = () => {
    setUser(null);
    localStorage.removeItem('user');
    apiService.clearAuth(); // Clear the token as well
  };

  // Protected route component
  const ProtectedRoute = ({ children }) => {
    if (isLoading) {
      return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
        </div>
      );
    }
    
    // Check both user state and token presence
    return (user && apiService.isAuthenticated()) ? children : <Navigate to="/login" replace />;
  };

  // Public route component (redirect to dashboard if already logged in)
  const PublicRoute = ({ children }) => {
    if (isLoading) {
      return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
        </div>
      );
    }
    
    return user ? <Navigate to="/dashboard" replace /> : children;
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <Router>
      <div className="App min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <Routes>
          {/* Public Routes */}
          <Route
            path="/"
            element={
              <PublicRoute>
                <Landing />
              </PublicRoute>
            }
          />
          <Route
            path="/login"
            element={
              <PublicRoute>
                <Login onLogin={handleLogin} />
              </PublicRoute>
            }
          />
          <Route
            path="/signup"
            element={
              <PublicRoute>
                <SignUp />
              </PublicRoute>
            }
          />

          {/* Protected Routes */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <MemberDashboard user={user} onLogout={handleLogout} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/books"
            element={
              <ProtectedRoute>
                <Books user={user} onLogout={handleLogout} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/librarian"
            element={
              <ProtectedRoute>
                <LibrarianDashboard user={user} onLogout={handleLogout} />
              </ProtectedRoute>
            }
          />
          <Route
            path="/reservations"
            element={
              <ProtectedRoute>
                <Reservations user={user} onLogout={handleLogout} />
              </ProtectedRoute>
            }
          />

          {/* Catch all route */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
