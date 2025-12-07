export interface WhitelistForm {
  id: string;
  name: string;
  fields: Array<{ label: string; type: string; value?: any }>;
  // Add more fields as needed from your API schema
}
