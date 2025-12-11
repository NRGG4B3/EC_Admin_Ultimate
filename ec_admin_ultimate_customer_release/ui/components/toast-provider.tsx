import React, { useState, useEffect, useCallback, createContext, useContext } from 'react';
import { CheckCircle, XCircle, Info, AlertTriangle, X } from 'lucide-react';

interface Toast {
  id: string;
  message: string;
  title?: string;
  description?: string;
  type: 'success' | 'error' | 'info' | 'warning';
  duration?: number;
}

interface ToastProviderProps {
  children: React.ReactNode;
}

interface ToastOptions {
  title?: string;
  description?: string;
  type?: Toast['type'];
  duration?: number;
}

interface ToastContextType {
  addToast: (toast: Omit<Toast, 'id'>) => void;
  removeToast: (id: string) => void;
  toast: (messageOrOptions: string | ToastOptions, type?: Toast['type']) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export function ToastProvider({ children }: ToastProviderProps) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = useCallback((toast: Omit<Toast, 'id'>) => {
    const id = Math.random().toString(36).substring(7);
    const newToast = { ...toast, id };
    
    setToasts(prev => [...prev, newToast]);

    // Auto remove after duration
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, toast.duration || 3000);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  const toast = useCallback((messageOrOptions: string | ToastOptions, type: Toast['type'] = 'info') => {
    if (typeof messageOrOptions === 'string') {
      // Simple string message
      addToast({ message: messageOrOptions, type });
    } else {
      // Object with title/description
      const { title, description, type: optType, duration } = messageOrOptions;
      const message = title && description ? title + ': ' + description : title || description || '';
      addToast({ 
        message, 
        title,
        description,
        type: optType || 'info',
        duration 
      });
    }
  }, [addToast]);

  // Listen for custom toast events
  useEffect(() => {
    const handleToastEvent = (event: CustomEvent) => {
      const { message, type, title, description } = event.detail;
      addToast({ 
        message: message || '',
        title,
        description,
        type: type || 'info', 
        duration: 3000 
      });
    };

    window.addEventListener('show-toast' as any, handleToastEvent);
    window.addEventListener('toast' as any, handleToastEvent);

    return () => {
      window.removeEventListener('show-toast' as any, handleToastEvent);
      window.removeEventListener('toast' as any, handleToastEvent);
    };
  }, [addToast]);

  const getToastIcon = (type: Toast['type']) => {
    switch (type) {
      case 'success':
        return <CheckCircle className="size-5 text-green-400 dark:text-green-500" />;
      case 'error':
        return <XCircle className="size-5 text-red-400 dark:text-red-500" />;
      case 'warning':
        return <AlertTriangle className="size-5 text-orange-400 dark:text-orange-500" />;
      case 'info':
      default:
        return <Info className="size-5 text-blue-400 dark:text-blue-500" />;
    }
  };

  const getToastStyles = (type: Toast['type']) => {
    switch (type) {
      case 'success':
        return 'border-green-500/20 bg-green-500/10 dark:border-green-500/30 dark:bg-green-500/20';
      case 'error':
        return 'border-red-500/20 bg-red-500/10 dark:border-red-500/30 dark:bg-red-500/20';
      case 'warning':
        return 'border-orange-500/20 bg-orange-500/10 dark:border-orange-500/30 dark:bg-orange-500/20';
      case 'info':
      default:
        return 'border-blue-500/20 bg-blue-500/10 dark:border-blue-500/30 dark:bg-blue-500/20';
    }
  };

  return (
    <ToastContext.Provider value={{ addToast, removeToast, toast }}>
      {children}
      
      {/* Toast Container */}
      <div className="fixed top-4 right-4 z-[99999] space-y-2 pointer-events-none">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`pointer-events-auto flex items-start gap-3 px-4 py-3 rounded-lg border backdrop-blur-sm shadow-lg animate-in fade-in-0 slide-in-from-right-full duration-300 ${getToastStyles(toast.type)}`}
            style={{ minWidth: '300px', maxWidth: '400px' }}
          >
            <div className="flex-shrink-0 mt-0.5">
              {getToastIcon(toast.type)}
            </div>
            <div className="flex-1 min-w-0">
              {toast.title && (
                <div className="font-medium text-sm mb-0.5 text-foreground">
                  {toast.title}
                </div>
              )}
              {toast.description && (
                <div className="text-sm text-muted-foreground">
                  {toast.description}
                </div>
              )}
              {!toast.title && !toast.description && toast.message && (
                <div className="text-sm text-foreground">
                  {toast.message}
                </div>
              )}
            </div>
            <button
              onClick={() => removeToast(toast.id)}
              className="flex-shrink-0 p-1 rounded-md hover:bg-white/10 dark:hover:bg-white/5 transition-colors text-foreground"
            >
              <X className="size-4" />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within ToastProvider');
  }
  return context;
}