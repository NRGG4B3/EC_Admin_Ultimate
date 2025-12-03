// Shared time formatting utilities
// Provides consistent display across Admin Profile and Player Profile

export function formatRelativeTime(input: number | string | Date): string {
  const date = typeof input === 'number'
    ? // seconds vs ms detection: if it's in seconds (10 digits), multiply to ms
      (input < 2_000_000_000 ? new Date(input * 1000) : new Date(input))
    : typeof input === 'string'
    ? new Date(input)
    : input;

  const diffMs = Date.now() - date.getTime();
  const minutes = Math.floor(diffMs / 60000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString();
}

export function formatDateTime(input: number | string | Date): string {
  const date = typeof input === 'number'
    ? (input < 2_000_000_000 ? new Date(input * 1000) : new Date(input))
    : typeof input === 'string'
    ? new Date(input)
    : input;
  return date.toLocaleString();
}
