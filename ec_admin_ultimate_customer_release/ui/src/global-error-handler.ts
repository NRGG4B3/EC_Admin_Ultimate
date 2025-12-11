/**
 * EC Admin Ultimate - Global Error Handler
 * Catches ALL errors (React, fetch, console, etc.) and sends to server logger
 */

// Check if we're in NUI mode
const isNUI = typeof (window as any).GetParentResourceName !== 'undefined';

/**
 * Send error to server logger via NUI callback
 */
function logErrorToServer(
  errorType: string,
  message: string,
  details?: any
): void {
  if (!isNUI) {
    // In browser mode, just log to console
    console.error(`[${errorType}]`, message, details);
    return;
  }

  try {
    const resourceName = (window as any).GetParentResourceName?.();
    if (!resourceName) return;

    // Send error to client-side handler
    fetch(`https://${resourceName}/logError`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        type: errorType,
        message: message,
        details: details || {},
        timestamp: Date.now()
      })
    }).catch(() => {
      // Silently fail if NUI bridge is not available
    });
  } catch (err) {
    // Silently fail
  }
}

/**
 * Wrap fetchNui to catch all errors
 */
export function createErrorHandledFetchNui() {
  const originalFetchNui = (window as any).fetchNui;
  
  if (!originalFetchNui) {
    return originalFetchNui;
  }

  return async function fetchNui<T = any>(
    event: string,
    data?: any,
    mockData?: T
  ): Promise<T> {
    try {
      const result = await originalFetchNui(event, data, mockData);
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logErrorToServer('FETCH_NUI_ERROR', `Failed to call ${event}: ${errorMessage}`, {
        event,
        data,
        error: error instanceof Error ? {
          name: error.name,
          message: error.message,
          stack: error.stack
        } : error
      });
      throw error;
    }
  };
}

/**
 * Setup global error handlers
 */
export function setupGlobalErrorHandlers(): void {
  // 1. React Error Boundary errors (handled in error-boundary.tsx)
  
  // 2. Unhandled Promise Rejections
  window.addEventListener('unhandledrejection', (event) => {
    const error = event.reason;
    const message = error instanceof Error ? error.message : String(error);
    const stack = error instanceof Error ? error.stack : undefined;
    
    logErrorToServer('UNHANDLED_PROMISE_REJECTION', message, {
      reason: error,
      stack: stack
    });
  });

  // 3. Global JavaScript Errors
  window.addEventListener('error', (event) => {
    logErrorToServer('JAVASCRIPT_ERROR', event.message || 'Unknown error', {
      filename: event.filename,
      lineno: event.lineno,
      colno: event.colno,
      error: event.error ? {
        name: event.error.name,
        message: event.error.message,
        stack: event.error.stack
      } : null
    });
  });

  // 4. Console Error Interception
  const originalConsoleError = console.error;
  console.error = (...args: any[]) => {
    originalConsoleError.apply(console, args);
    
    // Extract error message
    const messages = args.map(arg => {
      if (arg instanceof Error) {
        return arg.message;
      }
      return String(arg);
    }).join(' ');
    
    logErrorToServer('CONSOLE_ERROR', messages, {
      args: args.map(arg => {
        if (arg instanceof Error) {
          return {
            name: arg.name,
            message: arg.message,
            stack: arg.stack
          };
        }
        return arg;
      })
    });
  };

  // 5. Console Warn Interception (optional - for warnings)
  const originalConsoleWarn = console.warn;
  console.warn = (...args: any[]) => {
    originalConsoleWarn.apply(console, args);
    
    // Only log warnings if in development or if they're critical
    if (import.meta.env?.DEV) {
      const messages = args.map(arg => String(arg)).join(' ');
      logErrorToServer('CONSOLE_WARN', messages, {
        args: args
      });
    }
  };

  // 6. Fetch Error Interception
  const originalFetch = window.fetch;
  window.fetch = async function(...args: any[]): Promise<Response> {
    try {
      const response = await originalFetch.apply(window, args);
      
      // Log failed requests
      if (!response.ok) {
        const url = typeof args[0] === 'string' ? args[0] : args[0].url;
        logErrorToServer('FETCH_ERROR', `HTTP ${response.status} ${response.statusText}`, {
          url,
          method: args[1]?.method || 'GET',
          status: response.status,
          statusText: response.statusText
        });
      }
      
      return response;
    } catch (error) {
      const url = typeof args[0] === 'string' ? args[0] : args[0]?.url || 'unknown';
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      logErrorToServer('FETCH_ERROR', `Network error: ${errorMessage}`, {
        url,
        method: args[1]?.method || 'GET',
        error: error instanceof Error ? {
          name: error.name,
          message: error.message,
          stack: error.stack
        } : error
      });
      
      throw error;
    }
  };
}

// Auto-setup on import
if (typeof window !== 'undefined') {
  setupGlobalErrorHandlers();
  
  // Wrap fetchNui if it exists
  if ((window as any).fetchNui) {
    (window as any).fetchNui = createErrorHandledFetchNui();
  }
}
