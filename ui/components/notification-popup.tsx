import { useState, useEffect } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { 
  X, 
  Bell, 
  AlertTriangle,
  Info,
  CheckCircle,
  Users,
  Car,
  Shield
} from 'lucide-react';

interface NotificationPopupProps {
  isVisible: boolean;
  onDismiss: () => void;
  alerts: Array<{
    id: string;
    type: string;
    message: string;
    time: number;
    severity?: string;
  }>;
}

const typeIcons = {
  info: Info,
  warning: AlertTriangle,
  error: AlertTriangle,
  success: CheckCircle,
  player: Users,
  vehicle: Car,
  system: Shield
};

const typeColors = {
  info: 'from-blue-500/20 to-blue-600/20 border-blue-500/30',
  warning: 'from-yellow-500/20 to-yellow-600/20 border-yellow-500/30',
  error: 'from-red-500/20 to-red-600/20 border-red-500/30',
  success: 'from-green-500/20 to-green-600/20 border-green-500/30',
  player: 'from-cyan-500/20 to-cyan-600/20 border-cyan-500/30',
  vehicle: 'from-orange-500/20 to-orange-600/20 border-orange-500/30',
  system: 'from-purple-500/20 to-purple-600/20 border-purple-500/30'
};

export function NotificationPopup({ isVisible, onDismiss, alerts }: NotificationPopupProps) {
  const [currentAlert, setCurrentAlert] = useState(0);
  const [autoProgress, setAutoProgress] = useState(true);
  const [displayedAlerts, setDisplayedAlerts] = useState<Array<any>>([]);

  // Track which alerts have been shown
  useEffect(() => {
    if (alerts && alerts.length > 0) {
      const newAlerts = alerts.filter(alert => 
        !displayedAlerts.some(displayed => displayed.id === alert.id)
      );
      if (newAlerts.length > 0) {
        setDisplayedAlerts([...displayedAlerts, ...newAlerts]);
      }
    }
  }, [alerts, displayedAlerts]);

  const latestAlerts = alerts.slice(0, 3);

  useEffect(() => {
    if (!isVisible || !autoProgress || latestAlerts.length === 0) return;

    const timer = setTimeout(() => {
      if (currentAlert < latestAlerts.length - 1) {
        setCurrentAlert(prev => prev + 1);
      } else {
        onDismiss();
        setCurrentAlert(0);
      }
    }, 5000);

    return () => clearTimeout(timer);
  }, [isVisible, currentAlert, latestAlerts.length, autoProgress, onDismiss]);

  useEffect(() => {
    if (isVisible) {
      setCurrentAlert(0);
      setAutoProgress(true);
    }
  }, [isVisible]);

  if (!isVisible || latestAlerts.length === 0) return null;

  const alert = latestAlerts[currentAlert];
  const Icon = typeIcons[alert.type as keyof typeof typeIcons] || Bell;
  const colorClass = typeColors[alert.type as keyof typeof typeColors] || typeColors.info;

  const formatTimeAgo = (timestamp: number) => {
    const diff = Date.now() - timestamp;
    if (diff < 60 * 1000) return 'Just now';
    if (diff < 60 * 60 * 1000) return Math.floor(diff / (60 * 1000)) + 'm ago';
    return new Date(timestamp).toLocaleTimeString();
  };

  return (
    <div className="fixed top-4 right-4 z-[9999] w-96 pointer-events-auto">
      <div 
        className={`relative overflow-hidden rounded-xl border backdrop-blur-xl bg-gradient-to-br ${colorClass} shadow-2xl animate-in slide-in-from-right-full duration-300`}
        onMouseEnter={() => setAutoProgress(false)}
        onMouseLeave={() => setAutoProgress(true)}
      >
        {autoProgress && (
          <div
            className="absolute top-0 left-0 h-1 bg-primary/50 dark:bg-primary/70"
            style={{
              width: '100%',
              animation: 'progressBar 5s linear forwards'
            }}
          />
        )}

        <div className="p-4 bg-white/95 dark:bg-black/90">
          <div className="flex items-start gap-3">
            <div className="size-10 rounded-lg bg-primary/10 dark:bg-primary/20 flex items-center justify-center backdrop-blur-sm">
              <Icon className="size-5 text-primary dark:text-primary" />
            </div>
            
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between gap-2 mb-1">
                <h4 className="font-semibold text-card-foreground capitalize">
                  {alert.type} Alert
                </h4>
                <div className="flex items-center gap-2">
                  {latestAlerts.length > 1 && (
                    <Badge variant="secondary" className="bg-muted text-muted-foreground text-xs">
                      {currentAlert + 1} of {latestAlerts.length}
                    </Badge>
                  )}
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={onDismiss}
                    className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground hover:bg-accent"
                  >
                    <X className="size-4" />
                  </Button>
                </div>
              </div>
              
              <p className="text-card-foreground/90 dark:text-card-foreground/80 text-sm mb-2">
                {alert.message}
              </p>
              
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground text-xs">
                  {formatTimeAgo(alert.time)}
                </span>
                
                {latestAlerts.length > 1 && (
                  <div className="flex items-center gap-1">
                    {latestAlerts.map((_, index) => (
                      <button
                        key={index}
                        onClick={() => setCurrentAlert(index)}
                        className={`size-2 rounded-full transition-all duration-200 ${ 
                          index === currentAlert 
                            ? 'bg-primary scale-110' 
                            : 'bg-muted-foreground/40 hover:bg-muted-foreground/60'
                        }`}
                      />
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>

          {alert.severity === 'critical' && (
            <div className="flex items-center gap-2 mt-3 pt-3 border-t border-border">
              <Button
                size="sm"
                variant="secondary"
                className="text-xs"
                onClick={() => console.log('View details')}
              >
                View Details
              </Button>
              <Button
                size="sm"
                variant="secondary"
                className="text-xs"
                onClick={() => console.log('Take action')}
              >
                Take Action
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}