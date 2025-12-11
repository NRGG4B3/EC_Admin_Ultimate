import { useEffect } from 'react';

/**
 * Custom hook to listen for NUI messages from the game
 * @param action - The action name to listen for
 * @param handler - The callback function to handle the message
 */
export const useNuiEvent = <T = unknown>(
  action: string,
  handler: (data: T) => void
) => {
  useEffect(() => {
    const eventListener = (event: MessageEvent) => {
      const { type, data } = event.data;

      if (type === action) {
        handler(data);
      }
    };

    window.addEventListener('message', eventListener);

    return () => {
      window.removeEventListener('message', eventListener);
    };
  }, [action, handler]);
};
