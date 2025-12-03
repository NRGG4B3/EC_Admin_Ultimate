/**
 * EC Admin Ultimate - Loading State Components
 * Used when awaiting live data (NO MOCK DATA)
 */

import { Loader2, Database, Wifi, AlertCircle } from 'lucide-react';
import { motion } from 'framer-motion';
import { Card } from './ui/card';
import { Alert, AlertDescription } from './ui/alert';

interface LoadingStateProps {
  message?: string;
  type?: 'spinner' | 'shimmer' | 'pulse';
  size?: 'sm' | 'md' | 'lg';
  fullScreen?: boolean;
}

export function LoadingState({ 
  message = 'Awaiting live data...', 
  type = 'spinner',
  size = 'md',
  fullScreen = false
}: LoadingStateProps) {
  const sizeClasses = {
    sm: 'size-4',
    md: 'size-8',
    lg: 'size-12'
  };

  if (type === 'shimmer') {
    return (
      <div className="space-y-3">
        <div className="h-8 bg-gradient-to-r from-card via-card/50 to-card rounded animate-pulse" />
        <div className="h-8 bg-gradient-to-r from-card via-card/50 to-card rounded animate-pulse" />
        <div className="h-8 bg-gradient-to-r from-card via-card/50 to-card rounded animate-pulse" />
      </div>
    );
  }

  if (type === 'pulse') {
    return (
      <motion.div
        animate={{ opacity: [0.5, 1, 0.5] }}
        transition={{ duration: 2, repeat: Infinity }}
        className="text-center py-8"
      >
        <Database className={sizeClasses[size] + ' mx-auto mb-2 text-primary'} />
        <p className="text-sm text-muted-foreground">{message}</p>
      </motion.div>
    );
  }

  return (
    <div className={'flex flex-col items-center justify-center ' + (fullScreen ? 'h-screen' : 'py-12') + ' space-y-4'}>
      {type === 'database' ? (
        <Database className={sizeClasses[size] + ' mx-auto mb-2 text-primary'} />
      ) : (
        <Loader2 className={sizeClasses[size] + ' animate-spin text-primary'} />
      )}
      <p className="text-sm text-muted-foreground">{message}</p>
    </div>
  );
}

export function EmptyState({ 
  icon: Icon = Database,
  title = 'No Data Available',
  description = 'Awaiting live data...',
  action
}: {
  icon?: React.ComponentType<{ className?: string }>;
  title?: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <Card className="p-8 text-center">
      <Icon className="size-12 mx-auto mb-4 text-muted-foreground" />
      <h3 className="mb-2">{title}</h3>
      <p className="text-sm text-muted-foreground mb-4">{description}</p>
      {action}
    </Card>
  );
}

export function ConnectionStatus({ 
  connected,
  message 
}: { 
  connected: boolean;
  message?: string;
}) {
  return (
    <div className="flex items-center gap-2 text-sm">
      <div className={'size-2 rounded-full ' + (connected ? 'bg-green-500' : 'bg-red-500')} />
      <Wifi className={'size-4 ' + (connected ? 'text-green-400' : 'text-red-400')} />
      <span className="text-muted-foreground">
        {message || (connected ? 'Connected to live API' : 'Disconnected')}
      </span>
    </div>
  );
}

export function DataLoadError({ 
  error,
  onRetry 
}: {
  error: string;
  onRetry?: () => void;
}) {
  return (
    <Alert variant="destructive">
      <AlertCircle className="size-4" />
      <AlertDescription className="flex items-center justify-between">
        <span>{error}</span>
        {onRetry && (
          <button
            onClick={onRetry}
            className="text-xs underline hover:no-underline"
          >
            Retry
          </button>
        )}
      </AlertDescription>
    </Alert>
  );
}

export function SkeletonTable({ rows = 5, columns = 4 }: { rows?: number; columns?: number }) {
  return (
    <div className="space-y-2">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex gap-4">
          {Array.from({ length: columns }).map((_, j) => (
            <div 
              key={j}
              className="h-8 flex-1 bg-gradient-to-r from-card via-card/50 to-card rounded animate-pulse"
            />
          ))}
        </div>
      ))}
    </div>
  );
}

export function SkeletonCard() {
  return (
    <Card className="p-4 space-y-3">
      <div className="h-6 bg-gradient-to-r from-card via-card/50 to-card rounded animate-pulse" />
      <div className="h-4 bg-gradient-to-r from-card via-card/50 to-card rounded animate-pulse w-3/4" />
      <div className="h-4 bg-gradient-to-r from-card via-card/50 to-card rounded animate-pulse w-1/2" />
    </Card>
  );
}