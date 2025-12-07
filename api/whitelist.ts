import { WhitelistForm } from '../types/whitelist';

export async function fetchWhitelistForms(): Promise<WhitelistForm[]> {
  const res = await fetch('/api/whitelist/forms');
  return res.json();
}

export async function updateWhitelistForm(formId: string, data: Partial<WhitelistForm>): Promise<WhitelistForm> {
  const res = await fetch(`/api/whitelist/forms/${formId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}
