// ============================================================================
// EC ADMIN ULTIMATE - UI LOGGER UTILITY
// ============================================================================
// Call these functions from React components to log ALL interactions
// Automatically sends to backend via fetchNui or TriggerServerEvent
// ============================================================================

/**
 * Log any button click in the UI
 * @param {string} button - Button name/ID
 * @param {string} component - Component name (optional)
 */
export function logClick(button, component = null) {
    try {
        // Send to client-side Lua
        if (window.nuiHandoff) {
            window.nuiHandoff.send('logClick', {
                button: button,
                component: component || 'unknown'
            });
        }
    } catch (error) {
        console.warn('Failed to log click:', error);
    }
}

/**
 * Log page navigation
 * @param {string} page - New page name
 */
export function logPageChange(page) {
    try {
        if (window.nuiHandoff) {
            window.nuiHandoff.send('pageChange', {
                page: page
            });
        }
    } catch (error) {
        console.warn('Failed to log page change:', error);
    }
}

/**
 * Log menu open event
 */
export function logMenuOpen() {
    try {
        if (window.nuiHandoff) {
            window.nuiHandoff.send('menuOpen', {});
        }
    } catch (error) {
        console.warn('Failed to log menu open:', error);
    }
}

/**
 * Log menu close event
 */
export function logMenuClose() {
    try {
        if (window.nuiHandoff) {
            window.nuiHandoff.send('menuClose', {});
        }
    } catch (error) {
        console.warn('Failed to log menu close:', error);
    }
}

/**
 * Log player selection
 * @param {number} playerId - Server ID
 * @param {string} playerName - Player name
 */
export function logPlayerSelect(playerId, playerName) {
    try {
        if (window.nuiHandoff) {
            window.nuiHandoff.send('playerSelect', {
                playerId: playerId,
                playerName: playerName
            });
        }
    } catch (error) {
        console.warn('Failed to log player select:', error);
    }
}

/**
 * React Hook: Automatically log button clicks
 * Usage: const handleClick = useLoggedClick('ButtonName', () => { your code });
 */
export function useLoggedClick(buttonName, callback, component = null) {
    return (...args) => {
        logClick(buttonName, component);
        if (callback) {
            return callback(...args);
        }
    };
}

/**
 * React Hook: Automatically log page changes
 * Usage: useEffect(() => { logPageChange('dashboard'); }, []);
 */
export { logPageChange as usePageChange };

// ============================================================================
// EXAMPLE USAGE IN REACT COMPONENTS
// ============================================================================

/*

import { logClick, logPageChange, logPlayerSelect, useLoggedClick } from './utils/logger';

// Example 1: Manual click logging
function MyButton() {
    const handleClick = () => {
        logClick('TeleportButton', 'PlayerActions');
        // ... your teleport logic
    };
    
    return <button onClick={handleClick}>Teleport</button>;
}

// Example 2: Using useLoggedClick hook (auto-logs)
function MyButton() {
    const handleClick = useLoggedClick('TeleportButton', () => {
        // ... your teleport logic
    }, 'PlayerActions');
    
    return <button onClick={handleClick}>Teleport</button>;
}

// Example 3: Log page changes
function Dashboard() {
    useEffect(() => {
        logPageChange('dashboard');
    }, []);
    
    return <div>Dashboard Content</div>;
}

// Example 4: Log player selection
function PlayerList({ players }) {
    const handlePlayerClick = (player) => {
        logPlayerSelect(player.id, player.name);
        // ... your player selection logic
    };
    
    return (
        <div>
            {players.map(player => (
                <div key={player.id} onClick={() => handlePlayerClick(player)}>
                    {player.name}
                </div>
            ))}
        </div>
    );
}

*/
