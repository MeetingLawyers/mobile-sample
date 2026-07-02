// Update these constants with your values.
// Ask for credentials at support@meetinglawyers.com
export const ML_API_KEY = '';
export const ML_USER_ID = '';

// 'DEV' points to the MeetingLawyers demo environment, 'PROD' to production.
export const ML_ENVIRONMENT: 'DEV' | 'PROD' = 'DEV';

// Optional theme applied after configure(). Colors are '#RRGGBB' or '#RRGGBBAA'.
// Every field is optional; each platform applies the colors its SDK supports.
import type { ThemeOptions } from '../plugins/meeting-lawyers';

export const ML_THEME: ThemeOptions = {
  primaryColor: '#2E7D6B',
  secondaryColor: '#2E7D6B',
  navigationBarColor: '#2E7D6B',
  outgoingMessageColor: '#2E7D6B',
};
