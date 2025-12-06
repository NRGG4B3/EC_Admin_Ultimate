import React, { useEffect, useState } from 'react';
import { fetchPlayerProfile, performPlayerAction } from '../api/player';
import { PlayerProfile } from '../types/player';

const PlayerProfilePage: React.FC<{ playerId: string }> = ({ playerId }) => {
  const [profile, setProfile] = useState<PlayerProfile | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPlayerProfile(playerId)
      .then(setProfile)
      .catch(() => setError('Failed to load player profile'));
  }, [playerId]);

  const handleAction = (action: string) => {
    performPlayerAction(playerId, action)
      .catch(() => setError('Failed to perform action'));
  };

  if (error) {
    return <div className="error">{error}</div>;
  }

  if (!profile) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <h1>{profile.name}'s Profile</h1>
      <div>
        <strong>ID:</strong> {profile.id}
      </div>
      <div>
        <strong>Actions:</strong>
        {profile.actions.map(action => (
          <button key={action} onClick={() => handleAction(action)}>
            {action}
          </button>
        ))}
      </div>
    </div>
  );
};

export default PlayerProfilePage;