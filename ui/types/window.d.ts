// Global window extensions for FiveM NUI
declare global {
  interface Window {
    invokeNative?: (...args: any[]) => any;
    GetParentResourceName?: () => string;
    nuiHandoverData?: any;
  }
}

export {};