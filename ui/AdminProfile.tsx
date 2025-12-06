import React, { useEffect, useState } from 'react';
import { fetchServerInfo } from '../api/server';
import { ServerInfo } from '../types/server';

const AdminProfile: React.FC = () => {
  const [serverInfo, setServerInfo] = useState<ServerInfo | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchServerInfo()
      .then(setServerInfo)
      .catch(() => setError('Failed to load server info'));
  }, []);

  return (
    <div>
      <h1>Admin Profile</h1>
      {error && <div className="error">{error}</div>}
      {serverInfo ? (
        <div>
          <h2>Server Information</h2>
          <p>Server Name: {serverInfo.name}</p>
          <p>Player Count: {serverInfo.playerCount}</p>
          <p>Max Players: {serverInfo.maxPlayers}</p>
          {/* Render other serverInfo fields as needed */}
        </div>
      ) : (
        <p>Loading server info...</p>
      )}
    </div>
  );
};

export default AdminProfile;