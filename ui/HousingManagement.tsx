import React, { useEffect, useState } from 'react';
import { fetchProperties, fetchOwnedProperties } from '../api/housing';
import { Property, OwnedProperty } from '../types/housing';

const HousingManagement: React.FC = () => {
  const [properties, setProperties] = useState<Property[]>([]);
  const [owned, setOwned] = useState<OwnedProperty[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchProperties().then(setProperties).catch(() => setError('Failed to load properties'));
    fetchOwnedProperties().then(setOwned).catch(() => setError('Failed to load owned properties'));
  }, []);

  return (
    <div>
      <h1>Housing Management</h1>
      {error && <div className="error">{error}</div>}
      <h2>All Properties</h2>
      <ul>
        {properties.map(property => (
          <li key={property.id}>{property.name}</li>
        ))}
      </ul>
      <h2>Owned Properties</h2>
      <ul>
        {owned.map(property => (
          <li key={property.id}>{property.name} - {property.status}</li>
        ))}
      </ul>
    </div>
  );
};

export default HousingManagement;