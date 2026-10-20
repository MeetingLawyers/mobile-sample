import { registerPlugin } from '@capacitor/core';

import type { MeetingLawyersPlugin } from './definitions';

export const MeetingLawyers = registerPlugin<MeetingLawyersPlugin>('MeetingLawyers');

export * from './definitions';
