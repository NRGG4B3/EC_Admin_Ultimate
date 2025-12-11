import { useState } from 'react';
import { Badge } from './ui/badge';
import { MapPin, User, Car, Shield } from 'lucide-react';
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from './ui/tooltip';

interface PlayerMarkerProps {
  player: {
    id: string;
    name: string;
    coords: { x: number; y: number; z: number };
    normalizedX: number;
    normalizedY: number;
    vehicle?: string;
    job?: string;
    heading?: number;
    health?: number;
    armor?: number;
    identifier?: string;
  };
  onClick?: (playerId: string) => void;
}

// Job colors mapping
const jobColors: Record<string, string> = {
  'police': '#3b82f6',      // Blue
  'sheriff': '#1e40af',     // Dark Blue
  'state': '#1e3a8a',       // Navy
  'ems': '#ef4444',         // Red
  'ambulance': '#dc2626',   // Dark Red
  'fire': '#f97316',        // Orange
  'mechanic': '#f59e0b',    // Amber
  'taxi': '#eab308',        // Yellow
  'lawyer': '#8b5cf6',      // Purple
  'judge': '#7c3aed',       // Dark Purple
  'reporter': '#ec4899',    // Pink
  'realestate': '#10b981',  // Green
  'cardealer': '#14b8a6',   // Teal
  'default': '#6b7280'      // Gray
};

export function PlayerMarker({ player, onClick }: PlayerMarkerProps) {
  const [isHovered, setIsHovered] = useState(false);
  
  const jobColor = jobColors[player.job?.toLowerCase() || 'default'] || jobColors.default;
  const isInVehicle = !!player.vehicle;
  
  const handleClick = () => {
    if (onClick) {
      onClick(player.id);
    }
  };

  return (
    <Tooltip>
      <TooltipTrigger asChild>
          <div
            className="absolute cursor-pointer transition-all duration-200 z-10"
            style={{
              left: `${player.normalizedX * 100}%`,
              top: `${player.normalizedY * 100}%`,
              transform: 'translate(-50%, -50%)',
            }}
            onClick={handleClick}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
          >
            {/* Marker pin */}
            <div className="relative">
              <MapPin
                className={`size-6 transition-all duration-200 ${
                  isHovered ? 'scale-125' : 'scale-100'
                }`}
                style={{ color: jobColor }}
                fill={jobColor}
              />
              
              {/* Pulse animation */}
              {isHovered && (
                <div
                  className="absolute inset-0 rounded-full animate-ping opacity-75"
                  style={{ backgroundColor: jobColor }}
                />
              )}
              
              {/* Vehicle indicator */}
              {isInVehicle && (
                <div className="absolute -top-1 -right-1">
                  <div className="size-3 rounded-full bg-orange-500 border-2 border-background" />
                </div>
              )}
            </div>
            
            {/* Player name label (shown on hover) */}
            {isHovered && (
              <div
                className="absolute top-8 left-1/2 transform -translate-x-1/2 whitespace-nowrap bg-card border rounded-lg px-2 py-1 shadow-lg z-20"
                style={{ borderColor: jobColor }}
              >
                <div className="flex items-center gap-1.5">
                  <User className="size-3" />
                  <span className="text-xs font-medium">{player.name}</span>
                </div>
                {player.vehicle && (
                  <div className="flex items-center gap-1 mt-1 text-xs text-muted-foreground">
                    <Car className="size-3" />
                    <span>{player.vehicle}</span>
                  </div>
                )}
                {player.job && (
                  <div className="flex items-center gap-1 mt-1">
                    <Badge
                      variant="outline"
                      className="text-xs"
                      style={{ borderColor: jobColor, color: jobColor }}
                    >
                      {player.job}
                    </Badge>
                  </div>
                )}
              </div>
            )}
          </div>
        </TooltipTrigger>
        <TooltipContent side="top" className="max-w-xs">
          <div className="space-y-1">
            <div className="font-medium">{player.name}</div>
            {player.identifier && (
              <div className="text-xs text-muted-foreground">
                ID: {player.identifier}
              </div>
            )}
            {player.job && (
              <div className="text-xs">
                Job: <span style={{ color: jobColor }}>{player.job}</span>
              </div>
            )}
            {player.vehicle && (
              <div className="text-xs flex items-center gap-1">
                <Car className="size-3" />
                {player.vehicle}
              </div>
            )}
            <div className="text-xs text-muted-foreground">
              Coords: {player.coords.x.toFixed(1)}, {player.coords.y.toFixed(1)}
            </div>
            {player.health !== undefined && (
              <div className="text-xs">
                Health: {player.health}%
                {player.armor !== undefined && player.armor > 0 && (
                  <span className="ml-2">
                    <Shield className="size-3 inline mr-1" />
                    Armor: {player.armor}%
                  </span>
                )}
              </div>
            )}
          </div>
        </TooltipContent>
      </Tooltip>
  );
}

