import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import apiService, { ApiError } from '../../services/apiService';
import NavBar from '../navbar/NavBar';
import './LibrarianDashboard.css';

const LibrarianDashboard = ({ user, onLogout }) => {
  const navigate = useNavigate();
  const [dashboardData, setDashboardData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  // Fetch dashboard data when component mounts
  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const data = await apiService.getDashboardData();
      setDashboardData(data);
    } catch (error) {
      console.error('Librarian dashboard data fetch error:', error);
      if (error instanceof ApiError) {
        setError(error.message);
      } else {
        setError('Failed to load dashboard data. Please try again.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleRefresh = async () => {
    try {
      setRefreshing(true);
      setError(null);
      const data = await apiService.getDashboardData();
      setDashboardData(data);
    } catch (error) {
      console.error('Dashboard refresh error:', error);
      if (error instanceof ApiError) {
        setError(error.message);
      } else {
        setError('Failed to refresh dashboard data. Please try again.');
      }
    } finally {
      setRefreshing(false);
    }
  };

  const handleLogout = async () => {
    try {
      await apiService.logout();
    } catch (error) {
      if (error instanceof ApiError) {
        console.error('Logout error:', error.message);
      } else {
        console.error('Logout error:', error);
      }
    } finally {
      onLogout();
    }
  };

  const handleTotalBooksClick = () => {
    navigate('/books');
  };

  if (isLoading && !dashboardData) {
    return (
      <div className="librarian-dashboard">
        <NavBar user={user} onLogout={handleLogout} />
        <div className="librarian-dashboard-content">
          <div className="loading-container">
            <div className="loading-spinner"></div>
            <p>Loading dashboard data...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error && !dashboardData) {
    return (
      <div className="librarian-dashboard">
        <NavBar user={user} onLogout={handleLogout} />
        <div className="librarian-dashboard-content">
          <div className="error-container">
            <div className="error-message">
              <h3>Error Loading Dashboard</h3>
              <p>{error}</p>
              <button onClick={fetchDashboardData} className="retry-button">
                Try Again
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="librarian-dashboard">
      <NavBar user={user} onLogout={handleLogout} />
      
      <div className="librarian-dashboard-content">
        <div className="dashboard-header">
          <h1>Librarian Dashboard</h1>
          <p className="welcome-message">Welcome back, {user?.name}!</p>
          <button 
            onClick={handleRefresh}
            disabled={refreshing}
            className="refresh-button"
          >
            {refreshing ? 'Refreshing...' : 'Refresh Data'}
          </button>
        </div>

        {error && (
          <div className="error-banner">
            <p>{error}</p>
            <button onClick={() => setError(null)} className="dismiss-error">
              ×
            </button>
          </div>
        )}

        <div className="stats-grid">
          {/* Total Books Card */}
          <div 
            className="stat-card total-books clickable-card" 
            onClick={handleTotalBooksClick}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                handleTotalBooksClick();
              }
            }}
          >
            <div className="stat-icon">
              📚
            </div>
            <div className="stat-content">
              <div className="stat-value">{dashboardData?.total_books || 0}</div>
              <div className="stat-label">Total Books</div>
              <div className="stat-description">Available book copies in library</div>
            </div>
            <div className="click-indicator">
              <svg className="click-arrow" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>

          {/* Total Borrowed Books Card */}
          <div className="stat-card borrowed-books">
            <div className="stat-icon">
              📖
            </div>
            <div className="stat-content">
              <div className="stat-value">{dashboardData?.total_borrowed_books || 0}</div>
              <div className="stat-label">Currently Borrowed</div>
              <div className="stat-description">Books checked out by members</div>
            </div>
          </div>

          {/* Books Due Today Card */}
          <div className="stat-card due-today">
            <div className="stat-icon">
              ⏰
            </div>
            <div className="stat-content">
              <div className="stat-value">{dashboardData?.books_due_today || 0}</div>
              <div className="stat-label">Due Today</div>
              <div className="stat-description">Books that should be returned today</div>
            </div>
          </div>

          {/* Overdue Members Card */}
          <div className="stat-card overdue-members">
            <div className="stat-icon">
              ⚠️
            </div>
            <div className="stat-content">
              <div className="stat-value">{dashboardData?.overdue_members?.length || 0}</div>
              <div className="stat-label">Overdue Members</div>
              <div className="stat-description">Members with overdue books</div>
            </div>
          </div>
        </div>

        {/* Overdue Members List */}
        {dashboardData?.overdue_members && dashboardData.overdue_members.length > 0 && (
          <div className="overdue-section">
            <h2>Members with Overdue Books</h2>
            <div className="overdue-list">
              {dashboardData.overdue_members.map((member) => (
                <div key={member.id} className="overdue-member-card">
                  <div className="member-info">
                    <div className="member-name">{member.name}</div>
                    <div className="member-email">{member.email}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default LibrarianDashboard;
