
import React from 'react';
import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';
import './NavBar.css';


const NavBar = ({ user, onLogout }) => {
  return (
    <nav className="navbar">
      <div className="navbar-content">
        <div className="navbar-wrapper">
          <div className="navbar-left">
            <div className="navbar-logo">
              <div className="navbar-logo-icon">
                <svg className="navbar-logo-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
            </div>
            <div className="navbar-title-wrapper">
              <h1 className="navbar-title">Library Management System</h1>
            </div>
          </div>
          <div className="navbar-center">
            <nav className="navbar-nav">
              <Link to="/dashboard" className="navbar-nav-link">
                <svg className="navbar-nav-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
                Dashboard
              </Link>
              <Link to="/books" className="navbar-nav-link">
                <svg className="navbar-nav-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
                Books
              </Link>
              {user?.role === 'librarian' && (
                <Link to="/reservations" className="navbar-nav-link">
                  <svg className="navbar-nav-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  Reservations
                </Link>
              )}
            </nav>
          </div>
          <div className="navbar-right">
            <div className="navbar-user">
              <div className="navbar-user-avatar">
                <span className="navbar-user-initial">
                  {user?.name?.charAt(0) || 'U'}
                </span>
              </div>
              <span className="navbar-user-welcome">Welcome, {user?.name || 'User'}!</span>
            </div>
            <button
              onClick={onLogout}
              className="navbar-logout-btn"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
};

NavBar.propTypes = {
  user: PropTypes.object,
  onLogout: PropTypes.func.isRequired,
};

export default NavBar;
