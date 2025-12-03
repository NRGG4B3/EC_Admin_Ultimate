type ToastLevel = "success" | "error" | "info" | "warning";

export function notify(
  level: ToastLevel,
  opts: { title: string; description?: string }
) {
  const { title, description } = opts;
  
  // Dispatch custom event with type for dark mode support
  const event = new CustomEvent('toast', { 
    detail: { title, description, type: level } 
  });
  window.dispatchEvent(event);
}

// convenience helpers
export const toastSuccess = (o: { title: string; description?: string }) =>
  notify("success", o);
export const toastError = (o: { title: string; description?: string }) =>
  notify("error", o);
export const toastInfo = (o: { title: string; description?: string }) =>
  notify("info", o);
export const toastWarn = (o: { title: string; description?: string }) =>
  notify("warning", o);

// Re-export toast for direct use
export { toast } from "./use-toast";