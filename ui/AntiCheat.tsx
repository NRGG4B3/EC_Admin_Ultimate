import React, { useEffect, useState } from 'react';
import { fetchAntiCheatLogs, toggleAntiCheatAction } from '../api/antiCheat';
import { AntiCheatLog } from '../types/antiCheat';

const AntiCheat: React.FC = () => {
  const [logs, setLogs] = useState<AntiCheatLog[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchAntiCheatLogs().then(setLogs).catch(() => setError('Failed to load anti-cheat logs'));
  }, []);

  const handleToggle = (action: string) => {
    toggleAntiCheatAction(action)
      .catch(() => setError('Failed to toggle anti-cheat action'));
  };

  return (
    <div>
      <h1>Anti-Cheat Logs</h1>
      {error && <div className="error">{error}</div>}
      <ul>
        {logs.map(log => (
          <li key={log.id}>
            {log.message}
            <button onClick={() => handleToggle(log.action)}>
              {log.toggled ? 'Disable' : 'Enable'}
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default AntiCheat;