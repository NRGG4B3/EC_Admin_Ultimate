// Re-export the useToast hook from toast-provider for convenience
export { useToast } from './toast-provider';

// Export toast function
export function toast(options: { title: string; description?: string; className?: string }) {
  const event = new CustomEvent('toast', { detail: options });
  window.dispatchEvent(event);
}