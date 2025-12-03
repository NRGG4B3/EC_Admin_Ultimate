/**
 * TypeScript definitions for custom modules and fixes
 */

// Toast types
declare module './lib/use-toast' {
  export interface ToastOptions {
    title: string;
    description?: string;
    className?: string;
    variant?: 'default' | 'destructive';
  }

  export function toast(options: ToastOptions): void;
  export function useToast(): any;
}

declare module './lib/toast' {
  export function toastSuccess(options: { title: string; description?: string }): void;
  export function toastError(options: { title: string; description?: string }): void;
  export function toastInfo(options: { title: string; description?: string }): void;
  export function toastWarn(options: { title: string; description?: string }): void;
  export function toast(options: import('./lib/use-toast').ToastOptions): void;
}

// Sonner toast
declare module 'sonner@2.0.3' {
  export function toast(message: string, options?: any): void;
  export const toast: {
    (message: string, options?: any): void;
    success: (message: string, options?: any) => void;
    error: (message: string, options?: any) => void;
    warning: (message: string, options?: any) => void;
    info: (message: string, options?: any) => void;
  };
}
