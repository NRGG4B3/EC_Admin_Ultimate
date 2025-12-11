import React, { useEffect, useState } from 'react';
import { fetchModerationTickets, fetchUserRole } from '../api/moderation';
import { ModerationTicket, UserRole } from '../types/moderation';

const Moderation: React.FC = () => {
  const [role, setRole] = useState<UserRole>('player');
  const [tickets, setTickets] = useState<ModerationTicket[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchUserRole().then(setRole).catch(() => setError('Failed to load user role'));
    if (role === 'admin') {
      fetchModerationTickets().then(setTickets).catch(() => setError('Failed to load tickets'));
    }
  }, [role]);

  return (
    <div>
      {role === 'admin' ? (
        <div>
          <h2>Moderation Tickets</h2>
          {tickets.length === 0 ? (
            <p>No tickets found.</p>
          ) : (
            <ul>
              {tickets.map((ticket) => (
                <li key={ticket.id}>{ticket.subject}</li>
              ))}
            </ul>
          )}
        </div>
      ) : (
        <div>
          <h2>Create Report</h2>
          {/* Report creation form goes here */}
        </div>
      )}
      {error && <div className="error">{error}</div>}
    </div>
  );
};

export default Moderation;