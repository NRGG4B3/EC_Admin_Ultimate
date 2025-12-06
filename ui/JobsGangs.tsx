import React, { useEffect, useState } from 'react';
import { fetchJobs, fetchGangs } from '../api/jobsGangs';
import { Job, Gang } from '../types/jobsGangs';

const JobsGangs: React.FC = () => {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [gangs, setGangs] = useState<Gang[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchJobs().then(setJobs).catch(() => setError('Failed to load jobs'));
    fetchGangs().then(setGangs).catch(() => setError('Failed to load gangs'));
  }, []);

  return (
    <div>
      <h1>Jobs and Gangs</h1>
      {error && <div className="error">{error}</div>}
      <div>
        <h2>Jobs</h2>
        <ul>
          {jobs.map((job) => (
            <li key={job.id}>{job.name}</li>
          ))}
        </ul>
      </div>
      <div>
        <h2>Gangs</h2>
        <ul>
          {gangs.map((gang) => (
            <li key={gang.id}>{gang.name}</li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default JobsGangs;