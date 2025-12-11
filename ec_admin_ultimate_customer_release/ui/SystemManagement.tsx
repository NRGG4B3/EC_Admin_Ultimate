import React, { useEffect, useState } from 'react';
import { fetchResources, manageResource } from '../api/system';
import { Resource } from '../types/system';

const SystemManagement: React.FC = () => {
  const [resources, setResources] = useState<Resource[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchResources().then(setResources).catch(() => setError('Failed to load resources'));
  }, []);

  const handleAction = (resource: string, action: 'start' | 'stop' | 'restart') => {
    manageResource(resource, action)
      .catch(() => setError(`Failed to ${action} resource`));
  };

  return (
    <div>
      <h1>System Management</h1>
      {error && <div className="error">{error}</div>}
      <div className="resources">
        {resources.map(resource => (
          <div key={resource.name} className="resource">
            <span className="resource-name">{resource.name}</span>
            <span className="resource-status">{resource.status}</span>
            <button onClick={() => handleAction(resource.name, 'start')}>Start</button>
            <button onClick={() => handleAction(resource.name, 'stop')}>Stop</button>
            <button onClick={() => handleAction(resource.name, 'restart')}>Restart</button>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SystemManagement;