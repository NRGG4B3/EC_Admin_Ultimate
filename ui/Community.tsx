import React, { useEffect, useState } from 'react';
import { fetchCommunityData } from '../api/community';
import { CommunityData } from '../types/community';

const Community: React.FC = () => {
  const [data, setData] = useState<CommunityData | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchCommunityData().then(setData).catch(() => setError('Failed to load community data'));
  }, []);

  return (
    <div>
      {error && <div className="error">{error}</div>}
      {data && (
        <div>
          {/* Render bans, warns, playtime, whitelist from state */}
        </div>
      )}
    </div>
  );
};

export default Community;