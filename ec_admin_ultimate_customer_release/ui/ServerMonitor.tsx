import React, { useEffect, useState } from 'react';
import { fetchServerMetrics, fetchMapScreenshot, fetchPlayers, fetchEntities, fetchResources } from '../api/serverMonitor';
import { ServerMetrics, Player, Entity, Resource } from '../types/serverMonitor';

const ServerMonitor: React.FC = () => {
  const [metrics, setMetrics] = useState<ServerMetrics | null>(null);
  const [mapScreenshot, setMapScreenshot] = useState<string | null>(null);
  const [players, setPlayers] = useState<Player[]>([]);
  const [entities, setEntities] = useState<Entity[]>([]);
  const [resources, setResources] = useState<Resource[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchServerMetrics().then(setMetrics).catch(() => setError('Failed to load metrics'));
    fetchMapScreenshot().then(setMapScreenshot).catch(() => setError('Failed to load map screenshot'));
    fetchPlayers().then(setPlayers).catch(() => setError('Failed to load players'));
    fetchEntities().then(setEntities).catch(() => setError('Failed to load entities'));
    fetchResources().then(setResources).catch(() => setError('Failed to load resources'));
  }, []);

  return (
    <div className="server-monitor">
      {error && <div className="error">{error}</div>}
      {metrics && (
        <div className="metrics">
          <h2>Server Metrics</h2>
          <pre>{JSON.stringify(metrics, null, 2)}</pre>
        </div>
      )}
      {mapScreenshot && (
        <div className="map-screenshot">
          <h2>Map Screenshot</h2>
          <img src={mapScreenshot} alt="Map Screenshot" />
        </div>
      )}
      {players.length > 0 && (
        <div className="players">
          <h2>Players</h2>
          <ul>
            {players.map(player => (
              <li key={player.id}>{player.name}</li>
            ))}
          </ul>
        </div>
      )}
      {entities.length > 0 && (
        <div className="entities">
          <h2>Entities</h2>
          <ul>
            {entities.map(entity => (
              <li key={entity.id}>{entity.name}</li>
            ))}
          </ul>
        </div>
      )}
      {resources.length > 0 && (
        <div className="resources">
          <h2>Resources</h2>
          <ul>
            {resources.map(resource => (
              <li key={resource.name}>{resource.name}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default ServerMonitor;