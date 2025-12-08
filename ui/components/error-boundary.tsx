import React from 'react';

interface Props {
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('EC Admin Ultimate Error:', error, errorInfo);
    
    // Send error to server logger
    this.logReactError(error, errorInfo);
  }

  private logReactError(error: Error, errorInfo: React.ErrorInfo) {
    const isNUI = typeof (window as any).GetParentResourceName !== 'undefined';
    
    if (!isNUI) {
      return; // Only log in NUI mode
    }

    try {
      const resourceName = (window as any).GetParentResourceName?.();
      if (!resourceName) return;

      fetch(`https://${resourceName}/logReactError`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          error: {
            name: error.name,
            message: error.message,
            stack: error.stack
          },
          errorInfo: {
            componentStack: errorInfo.componentStack
          },
          timestamp: Date.now()
        })
      }).catch(() => {
        // Silently fail if NUI bridge is not available
      });
    } catch (err) {
      // Silently fail
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="flex items-center justify-center min-h-screen bg-background">
          <div className="text-center p-8 max-w-md">
            <h2 className="text-2xl font-bold text-red-500 mb-4">
              Something went wrong
            </h2>
            <p className="text-muted-foreground mb-4">
              EC Admin Ultimate encountered an unexpected error.
            </p>
            <button
              onClick={() => this.setState({ hasError: false })}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
            >
              Try again
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}