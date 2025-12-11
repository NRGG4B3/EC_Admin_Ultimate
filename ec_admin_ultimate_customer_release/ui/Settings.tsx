import React, { useEffect, useState } from 'react';
import { fetchSettings, updateSetting, syncWebhooks } from '../api/settings';
import { Settings } from '../types/settings';

const SettingsPage: React.FC = () => {
  const [settings, setSettings] = useState<Settings | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchSettings().then(setSettings).catch(() => setError('Failed to load settings'));
  }, []);

  const handleChange = (key: string, value: any) => {
    updateSetting(key, value)
      .then(() => syncWebhooks())
      .catch(() => setError('Failed to update setting'));
  };

  return (
    <div>
      <h1>Settings</h1>
      {settings ? (
        <div>
          {/* Render settings form here, binding changes to handleChange */}
        </div>
      ) : (
        <div>Loading...</div>
      )}
      {error && <div className="error">{error}</div>}
    </div>
  );
};

export default SettingsPage;