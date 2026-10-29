export type MLEnvironment = 'DEV' | 'PROD';

export interface ConfigureOptions {
  /** Company API key provided by MeetingLawyers. */
  apiKey: string;
  /** 'DEV' = demo environment. Defaults to 'PROD'. */
  environment?: MLEnvironment;
}

/**
 * Colors of the SDK screens shared by iOS and Android, as '#RRGGBB' or '#RRGGBBAA'.
 * Every color is optional; the ones left out keep the SDK default.
 */
export interface ThemeOptions {
  primaryColor?: string;
  secondaryColor?: string;
  navigationBarColor?: string;
  incomingMessageColor?: string;
  outgoingMessageColor?: string;
}

export interface AuthenticateOptions {
  /** User identifier provided by your backend integration. */
  userId: string;
}

export interface OpenChatOptions {
  professionalHash: string;
}

export interface IsAuthenticatedResult {
  authenticated: boolean;
}

/**
 * Bridge to the MeetingLawyers SDK.
 *
 * Native counterparts, the only code that imports the SDK:
 * - iOS:     ios/App/App/MeetingLawyersPlugin.swift + MeetingLawyersIntegration.swift
 * - Android: android/app/src/main/java/.../MeetingLawyersPlugin.kt + MeetingLawyersIntegration.kt
 *            + MeetingLawyersMessagingService.kt
 */
export interface MeetingLawyersPlugin {
  /** Configures the SDK. Call it once at app startup, before any other method. */
  configure(options: ConfigureOptions): Promise<void>;
  /** Applies the theme colors. */
  configureTheme(options: ThemeOptions): Promise<void>;
  /** Signs the user in, asks for push permission and registers the push token. */
  authenticate(options: AuthenticateOptions): Promise<void>;
  /** Opens the professional list. Tapping a professional opens its chat. */
  openProfessionalList(): Promise<void>;
  /** Opens the chat with a professional. */
  openChat(options: OpenChatOptions): Promise<void>;
  /** True while a user is signed in. */
  isAuthenticated(): Promise<IsAuthenticatedResult>;
  /** Signs the user out. */
  logout(): Promise<void>;
}
