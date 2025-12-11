import React, { useEffect, useState } from 'react';
import { fetchDashboardStats, fetchQuickActions, fetchEconomyStats, fetchAdminCategories } from '../api/dashboard';
import { DashboardStats, QuickAction, EconomyStats, AdminCategory } from '../types/dashboard';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [quickActions, setQuickActions] = useState<QuickAction[]>([]);
  const [economy, setEconomy] = useState<EconomyStats | null>(null);
  const [adminCategories, setAdminCategories] = useState<AdminCategory[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDashboardStats()
      .then(setStats)
      .catch(() => setError('Failed to load dashboard stats'));
    fetchQuickActions()
      .then(setQuickActions)
      .catch(() => setError('Failed to load quick actions'));
    fetchEconomyStats()
      .then(setEconomy)
      .catch(() => setError('Failed to load economy stats'));
    fetchAdminCategories()
      .then(setAdminCategories)
      .catch(() => setError('Failed to load admin categories'));
  }, []);

  return (
    <div className="dashboard">
      {error && <div className="error">{error}</div>}
      {/* Render stats, quickActions, economy, adminCategories */}
    </div>
  );
};

export default Dashboard;