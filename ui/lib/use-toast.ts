// Re-export the useToast hook from toast-provider for convenience
export { useToast } from '../components/toast-provider';

// Export toast function with correct signature
export interface ToastOptions {
  title: string;
  description?: string;
  className?: string;
  variant?: 'default' | 'destructive';
}

export function toast(options: ToastOptions) {
  const { title, description, variant } = options;
  
  // Map variant to toast type
  let type: 'success' | 'error' | 'info' | 'warning' = 'info';
  if (variant === 'destructive') {
    type = 'error';
  }
  
  const event = new CustomEvent('toast', { 
    detail: { title, description, type } 
  });
  window.dispatchEvent(event);
}