import React, { useEffect, useState } from 'react';
import { fetchLogs } from '../api/logs';
import { LogEntry } from '../types/logs';

const LogsRecentActions: React.FC = () => {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [page, setPage] = useState<number>(1);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchLogs(page).then(setLogs).catch(() => setError('Failed to load logs'));
  }, [page]);

  const handleNextPage = () => {
    setPage((prev) => prev + 1);
  };

  const handlePrevPage = () => {
    setPage((prev) => Math.max(prev - 1, 1));
  };

  return (
    <div>
      <h1>Recent Actions Logs</h1>
      {error && <div className="error">{error}</div>}
      <ul>
        {logs.map((log) => (
          <li key={log.id}>{log.message}</li>
        ))}
      </ul>
      <div className="pagination">
        <button onClick={handlePrevPage} disabled={page === 1}>
          Previous
        </button>
        <span>Page {page}</span>
        <button onClick={handleNextPage}>
          Next
        </button>
      </div>
    </div>
  );
};

export default LogsRecentActions;