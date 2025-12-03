import { useState } from 'react';
// Completely removed motion imports to fix framer-motion conflicts
// import { motion, AnimatePresence } from 'motion/react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { ScrollArea } from './ui/scroll-area';
import { Separator } from './ui/separator';
import { 
  X, 
  Bell, 
  Check, 
  Trash2, 
  Filter,
  Users,
  Car,
  Shield,
  AlertTriangle,
  Info,
  CheckCircle
} from 'lucide-react';

interface NotificationCenterProps {
  isOpen: boolean;
  onClose: () => void;
}

interface Notification {
  id: string;
  type: 'info' | 'warning' | 'error' | 'success' | 'player' | 'vehicle' | 'system';
  title: string;
  message: string;
  timestamp: number;
  severity: 'low' | 'medium' | 'high' | 'critical';
  read: boolean;
  source?: string;
  actions?: Array<{
    label: string;
    action: string;
  }>;
}

// Mock notifications
const mockNotifications: Notification[] = [
  {
    id: '1',
    type: 'player',
    title: 'Player Joined',
    message: 'John_Doe (ID: 1) has joined the server',
    timestamp: Date.now() - 2 * 60 * 1000,
    severity: 'low',
    read: false,
    source: 'Player Management'
  },
  {
    id: '2',
    type: 'warning',
    title: 'High CPU Usage',
    message: 'Server CPU usage has exceeded 80% for the past 5 minutes',
    timestamp: Date.now() - 5 * 60 * 1000,
    severity: 'medium',
    read: false,
    source: 'System Monitor'
  },
  {
    id: '3',
    type: 'error',
    title: 'Anticheat Detection',
    message: 'Suspicious activity detected from player Jane_Smith (ID: 2)',
    timestamp: Date.now() - 10 * 60 * 1000,
    severity: 'high',
    read: true,
    source: 'Anticheat System',
    actions: [
      { label: 'Ban Player', action: 'ban' },
      { label: 'Spectate', action: 'spectate' }
    ]
  },
  {
    id: '4',
    type: 'success',
    title: 'Backup Completed',
    message: 'Daily database backup completed successfully',
    timestamp: Date.now() - 30 * 60 * 1000,
    severity: 'low',
    read: true,
    source: 'Backup System'
  },
  {
    id: '5',
    type: 'vehicle',
    title: 'Vehicle Spawned',
    message: 'Admin spawned Adder (Plate: ADMIN01) at Legion Square',
    timestamp: Date.now() - 60 * 60 * 1000,
    severity: 'low',
    read: true,
    source: 'Vehicle Management'
  }
];

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
  info: 'text-blue-400 bg-blue-500/10',
  warning: 'text-yellow-400 bg-yellow-500/10',
  error: 'text-red-400 bg-red-500/10',
  success: 'text-green-400 bg-green-500/10',
  player: 'text-cyan-400 bg-cyan-500/10',
  vehicle: 'text-orange-400 bg-orange-500/10',
  system: 'text-purple-400 bg-purple-500/10'
};

const severityColors = {
  low: 'border-gray-500/20',
  medium: 'border-yellow-500/20',
  high: 'border-orange-500/20',
  critical: 'border-red-500/20'
};

export function NotificationCenter({ isOpen, onClose }: NotificationCenterProps) {
  const [notifications, setNotifications] = useState<Notification[]>(mockNotifications);
  const [filter, setFilter] = useState<'all' | 'unread' | 'high'>('all');

  const filteredNotifications = notifications.filter(notification => {
    if (filter === 'unread') return !notification.read;
    if (filter === 'high') return notification.severity === 'high' || notification.severity === 'critical';
    return true;
  });

  const unreadCount = notifications.filter(n => !n.read).length;

  const markAsRead = (id: string) => {
    setNotifications(prev => 
      prev.map(notification => 
        notification.id === id 
          ? { ...notification, read: true }
          : notification
      )
    );
  };

  const markAllAsRead = () => {
    setNotifications(prev => 
      prev.map(notification => ({ ...notification, read: true }))
    );
  };

  const deleteNotification = (id: string) => {
    setNotifications(prev => prev.filter(n => n.id !== id));
  };

  const clearAll = () => {
    setNotifications([]);
  };

  const formatTimeAgo = (timestamp: number) => {
    const diff = Date.now() - timestamp;
    if (diff < 60 * 1000) return 'Just now';
    if (diff < 60 * 60 * 1000) return Math.floor(diff / (60 * 1000)) + 'm ago';
    if (diff < 24 * 60 * 60 * 1000) return Math.floor(diff / (60 * 60 * 1000)) + 'h ago';
    return new Date(timestamp).toLocaleDateString();
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 bg-black/50 dark:bg-black/70 backdrop-blur-sm flex items-center justify-end pr-4 z-[9999] pointer-events-auto animate-in fade-in-0 duration-200"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="w-full max-w-md h-[80vh] backdrop-blur-xl border border-border dark:border-border rounded-xl shadow-2xl overflow-hidden flex flex-col animate-in slide-in-from-right-full duration-300 ec-gradient-bg"
      >
        {/* Header */}
        <div className="p-4 border-b border-border/20 dark:border-border/10">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="size-8 rounded-lg bg-blue-500/20 flex items-center justify-center">
                <Bell className="size-4 text-blue-400" />
              </div>
              <div>
                <h2 className="font-semibold">Notifications</h2>
                {unreadCount > 0 && (
                  <p className="text-sm text-muted-foreground">
                    {unreadCount} unread
                  </p>
                )}
              </div>
            </div>
            
            <Button
              size="sm"
              variant="ghost"
              onClick={onClose}
              className="text-muted-foreground hover:text-foreground"
            >
              <X className="size-4" />
            </Button>
          </div>

          {/* Filters */}
          <div className="flex items-center gap-2">
            <Button
              size="sm"
              variant={filter === 'all' ? 'secondary' : 'ghost'}
              onClick={() => setFilter('all')}
              className="text-xs"
            >
              All
            </Button>
            <Button
              size="sm"
              variant={filter === 'unread' ? 'secondary' : 'ghost'}
              onClick={() => setFilter('unread')}
              className="text-xs"
            >
              Unread
              {unreadCount > 0 && (
                <Badge variant="outline" className="ml-1 text-xs">
                  {unreadCount}
                </Badge>
              )}
            </Button>
            <Button
              size="sm"
              variant={filter === 'high' ? 'secondary' : 'ghost'}
              onClick={() => setFilter('high')}
              className="text-xs"
            >
              Priority
            </Button>
          </div>
        </div>

        {/* Actions */}
        {notifications.length > 0 && (
          <div className="px-4 py-2 border-b border-border/20">
            <div className="flex items-center gap-2">
              <Button
                size="sm"
                variant="ghost"
                onClick={markAllAsRead}
                className="text-xs gap-1"
                disabled={unreadCount === 0}
              >
                <Check className="size-3" />
                Mark all read
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={clearAll}
                className="text-xs gap-1 text-red-400 hover:text-red-300"
              >
                <Trash2 className="size-3" />
                Clear all
              </Button>
            </div>
          </div>
        )}

        {/* Notifications List */}
        <ScrollArea className="flex-1">
          {filteredNotifications.length === 0 ? (
            <div className="text-center py-12 px-4">
              <Bell className="size-12 mx-auto mb-4 text-muted-foreground/50" />
              <p className="text-muted-foreground mb-2">No notifications</p>
              <p className="text-sm text-muted-foreground">
                {filter === 'unread' 
                  ? "You're all caught up!" 
                  : "We'll notify you when something happens"
                }
              </p>
            </div>
          ) : (
            <div className="p-2 space-y-2">
              {filteredNotifications.map((notification) => {
                  const Icon = typeIcons[notification.type];
                  
                  return (
                    <div
                      key={notification.id}
                      className={`animate-in fade-in-0 duration-300 
                        p-3 rounded-lg border-l-2 border
                        ${severityColors[notification.severity]}
                        ${notification.read 
                          ? 'opacity-75 bg-white/5 dark:bg-black/20' 
                          : 'bg-white/10 dark:bg-black/30 border-border/20'
                        }
                        hover:bg-white/15 dark:hover:bg-black/40 transition-all duration-200
                        group
                      `}
                    >
                      <div className="flex items-start gap-3">
                        <div className={`
                          size-8 rounded-lg flex items-center justify-center
                          ${typeColors[notification.type]}
                        `}>
                          <Icon className="size-4" />
                        </div>
                        
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <div className="flex-1">
                              <div className="flex items-center gap-2 mb-1">
                                <h4 className={`font-medium text-sm ${
                                  notification.read ? 'text-muted-foreground' : ''
                                }`}>
                                  {notification.title}
                                </h4>
                                {!notification.read && (
                                  <div className="size-2 bg-blue-500 rounded-full" />
                                )}
                              </div>
                              
                              <p className="text-sm text-muted-foreground mb-1">
                                {notification.message}
                              </p>
                              
                              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                <span>{formatTimeAgo(notification.timestamp)}</span>
                                {notification.source && (
                                  <>
                                    <span>•</span>
                                    <span>{notification.source}</span>
                                  </>
                                )}
                              </div>
                            </div>
                            
                            <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                              {!notification.read && (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  onClick={() => markAsRead(notification.id)}
                                  className="h-6 w-6 p-0"
                                >
                                  <Check className="size-3" />
                                </Button>
                              )}
                              <Button
                                size="sm"
                                variant="ghost"
                                onClick={() => deleteNotification(notification.id)}
                                className="h-6 w-6 p-0 text-red-400 hover:text-red-300"
                              >
                                <X className="size-3" />
                              </Button>
                            </div>
                          </div>
                          
                          {/* Actions */}
                          {notification.actions && notification.actions.length > 0 && (
                            <div className="flex items-center gap-2 mt-2">
                              {notification.actions.map((action, index) => (
                                <Button
                                  key={index}
                                  size="sm"
                                  variant="outline"
                                  className="h-6 text-xs px-2"
                                  onClick={() => console.log(`Action: ${action.action}`)}
                                >
                                  {action.label}
                                </Button>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
            </div>
          )}
        </ScrollArea>
      </div>
    </div>
  );
}