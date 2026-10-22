import { registerPlugin } from '@capacitor/core';

import type { MeetingProsPlugin } from './definitions';

export const MeetingPros = registerPlugin<MeetingProsPlugin>('MeetingPros');

export * from './definitions';
