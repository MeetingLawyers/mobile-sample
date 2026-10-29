// Demo credentials come from the repo-root .env (git-ignored), see ../.env.example.
// Ask for credentials at support@meetinglawyers.com
export const ML_API_KEY: string = import.meta.env.ML_API_KEY ?? '';
export const ML_USER_ID: string = import.meta.env.ML_USER_ID ?? '';

// 'PROD' points to production; anything else to the MeetingLawyers demo environment.
export const ML_ENVIRONMENT: 'DEV' | 'PROD' = import.meta.env.ML_ENVIRONMENT === 'PROD' ? 'PROD' : 'DEV';

// Brand color applied to the SDK screens.
export const BRAND_COLOR = '#2E7D6B';
