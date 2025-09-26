import { useState, useEffect } from 'react';
import apiService, { ApiError } from '../../services/apiService';

export default function useDashboardData() {
  const [dashboardData, setDashboardData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let isMounted = true;
    setIsLoading(true);
    setError(null);
    apiService.getDashboardData()
      .then((data) => {
        if (isMounted) setDashboardData(data);
      })
      .catch((err) => {
        if (isMounted) setError(err instanceof ApiError ? err.message : 'Failed to load dashboard data. Please try again.');
      })
      .finally(() => {
        if (isMounted) setIsLoading(false);
      });
    return () => { isMounted = false; };
  }, []);

  return { dashboardData, isLoading, error };
}
