
import React from 'react';
import { Navigate } from 'react-router-dom';
import NavBar from '../navbar/NavBar';
import useDashboardData from './useDashboardData';
import './MemberDashboard.css';
import apiService, { ApiError } from '../../services/apiService';

const MemberDashboardSummaryCard = ({ icon, label, value, color }) => (
	<div className={`dashboard-summary-card dashboard-summary-card--${color}`}>
		<div className="dashboard-summary-card-icon">{icon}</div>
		<div className="dashboard-summary-card-text">
			<p className={`dashboard-summary-card-label dashboard-summary-card-label--${color}`}>{label}</p>
			<p className={`dashboard-summary-card-value dashboard-summary-card-value--${color}`}>{value}</p>
		</div>
	</div>
);

const MemberDashboard = ({ user, onLogout }) => {
	const { dashboardData, isLoading, error } = useDashboardData();

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

	if (user?.role === 'librarian') {
		return <Navigate to="/librarian" replace />;
	}

	return (
		<div className="dashboard-container">
			<NavBar user={user} onLogout={handleLogout} />
			<div className="dashboard-main">
				<div className="dashboard-content">
					<div className="dashboard-card">
						<div className="dashboard-card-content">
							<h2 className="dashboard-title">Dashboard</h2>
							{isLoading && (
								<div className="dashboard-loading">
									<div className="dashboard-loading-spinner"></div>
									<span className="dashboard-loading-text">Loading dashboard data...</span>
								</div>
							)}
							{error && (
								<div className="dashboard-error">
									<div className="dashboard-error-content">
										<div className="dashboard-error-icon">
											<svg className="dashboard-error-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z" />
											</svg>
										</div>
										<div className="dashboard-error-message-wrapper">
											<p className="dashboard-error-message">{error}</p>
										</div>
									</div>
								</div>
							)}
							{dashboardData && !isLoading && user?.role === 'member' && (
								<div className="dashboard-data">
									<div className="dashboard-summary">
										<MemberDashboardSummaryCard
											icon={
												<svg className="dashboard-summary-card-svg dashboard-summary-card-svg--blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
													<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
												</svg>
											}
											label="Active Reservations"
											value={
												(dashboardData.active_not_overdue_reservations?.length || 0) +
												(dashboardData.active_overdue_reservations?.length || 0)
											}
											color="blue"
										/>
										<MemberDashboardSummaryCard
											icon={
												<svg className="dashboard-summary-card-svg dashboard-summary-card-svg--red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
													<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
												</svg>
											}
											label="Overdue"
											value={dashboardData.active_overdue_reservations?.length || 0}
											color="red"
										/>
										<MemberDashboardSummaryCard
											icon={
												<svg className="dashboard-summary-card-svg dashboard-summary-card-svg--green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
													<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
												</svg>
											}
											label="Recently Returned"
											value={dashboardData.recent_reservation_history?.length || 0}
											color="green"
										/>
									</div>
									{/* Active Reservations (Not Overdue) */}
									{dashboardData.active_not_overdue_reservations && dashboardData.active_not_overdue_reservations.length > 0 && (
										<div className="dashboard-section">
											<h3 className="dashboard-section-title">Current Reservations</h3>
											<div className="dashboard-section-list">
												{dashboardData.active_not_overdue_reservations.map((reservation) => (
													<div key={reservation.id} className="dashboard-reservation dashboard-reservation--active">
														<div className="dashboard-reservation-content">
															<h4 className="dashboard-reservation-title">{reservation.title}</h4>
															<p className="dashboard-reservation-author">by {reservation.author}</p>
															<p className="dashboard-reservation-serial">Serial: {reservation.book_serial_number}</p>
														</div>
														<div className="dashboard-reservation-meta">
															<p className="dashboard-reservation-meta-label dashboard-reservation-meta-label--blue">Due Date</p>
															<p className="dashboard-reservation-meta-value dashboard-reservation-meta-value--normal">{new Date(reservation.return_date).toLocaleDateString()}</p>
														</div>
													</div>
												))}
											</div>
										</div>
									)}
									{/* Overdue Reservations */}
									{dashboardData.active_overdue_reservations && dashboardData.active_overdue_reservations.length > 0 && (
										<div className="dashboard-section">
											<h3 className="dashboard-section-title dashboard-section-title--warning">
												<svg className="dashboard-section-title-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
													<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z" />
												</svg>
												Overdue Books
											</h3>
											<div className="dashboard-section-list">
												{dashboardData.active_overdue_reservations.map((reservation) => (
													<div key={reservation.id} className="dashboard-reservation dashboard-reservation--overdue">
														<div className="dashboard-reservation-content">
															<h4 className="dashboard-reservation-title">{reservation.title}</h4>
															<p className="dashboard-reservation-author">by {reservation.author}</p>
															<p className="dashboard-reservation-serial">Serial: {reservation.book_serial_number}</p>
														</div>
														<div className="dashboard-reservation-meta">
															<p className="dashboard-reservation-meta-label dashboard-reservation-meta-label--red">Overdue</p>
															<p className="dashboard-reservation-meta-value dashboard-reservation-meta-value--overdue">{new Date(reservation.return_date).toLocaleDateString()}</p>
														</div>
													</div>
												))}
											</div>
										</div>
									)}
									{/* Recent History */}
									{dashboardData.recent_reservation_history && dashboardData.recent_reservation_history.length > 0 && (
										<div className="dashboard-section">
											<h3 className="dashboard-section-title">Recently Returned Books</h3>
											<div className="dashboard-section-list">
												{dashboardData.recent_reservation_history.map((reservation) => (
													<div key={reservation.id} className="dashboard-reservation dashboard-reservation--history">
														<div className="dashboard-reservation-content">
															<h4 className="dashboard-reservation-title">{reservation.title}</h4>
															<p className="dashboard-reservation-author">by {reservation.author}</p>
															<p className="dashboard-reservation-serial">Serial: {reservation.book_serial_number}</p>
														</div>
														<div className="dashboard-reservation-meta">
															<p className="dashboard-reservation-meta-label dashboard-reservation-meta-label--green">Returned</p>
															<p className="dashboard-reservation-meta-value dashboard-reservation-meta-value--history">{new Date(reservation.return_date).toLocaleDateString()}</p>
														</div>
													</div>
												))}
											</div>
										</div>
									)}
									{/* Empty State */}
									{(!dashboardData.active_not_overdue_reservations || dashboardData.active_not_overdue_reservations.length === 0) &&
									 (!dashboardData.active_overdue_reservations || dashboardData.active_overdue_reservations.length === 0) &&
									 (!dashboardData.recent_reservation_history || dashboardData.recent_reservation_history.length === 0) && (
										<div className="dashboard-empty">
											<svg className="dashboard-empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
											</svg>
											<h3 className="dashboard-empty-title">No reservations yet</h3>
											<p className="dashboard-empty-description">Start browsing our book collection to make your first reservation.</p>
										</div>
									)}
								</div>
							)}
							{(!dashboardData || user?.role !== 'member') && !isLoading && !error && (
								<div className="dashboard-default">
									<svg className="dashboard-default-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
									</svg>
									<h3 className="dashboard-default-title">Welcome to the Library Management System</h3>
									<p className="dashboard-default-description">Your dashboard will display relevant information based on your role.</p>
								</div>
							)}
						</div>
					</div>
				</div>
			</div>
		</div>
	);
};

export default MemberDashboard;
