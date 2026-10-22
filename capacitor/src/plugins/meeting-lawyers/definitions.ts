export type MLEnvironment = 'DEV' | 'PROD';

export interface ConfigureOptions {
  /** Company API key provided by MeetingLawyers. */
  apiKey: string;
  /** Target backend. Defaults to 'PROD'. */
  environment?: MLEnvironment;
}

export interface AuthenticateOptions {
  /** User identifier provided by your backend integration. */
  userId: string;
}

export interface OpenChatOptions {
  /** Professional hash, e.g. captured from a professional list selection. */
  professionalHash: string;
}

export interface IsAuthenticatedResult {
  authenticated: boolean;
}

/**
 * Theme colors as hex strings (`#RRGGBB` or `#RRGGBBAA`).
 * Every field is optional; each platform applies the colors its SDK supports
 * and ignores the rest, so you can set the full palette from one place.
 */
export interface ThemeOptions {
  /** Primary tint. iOS + Android. */
  primaryColor?: string;
  /** Secondary tint (e.g. list badge). iOS + Android. */
  secondaryColor?: string;
  /** Navigation bar color. iOS + Android. */
  navigationBarColor?: string;
  /** Incoming chat bubble color. iOS + Android. */
  incomingMessageColor?: string;
  /** Outgoing chat bubble color. iOS + Android. */
  outgoingMessageColor?: string;
  /** Divider background. iOS only. */
  dividerColor?: string;
}

/**
 * Bridge to the native MeetingLawyers SDKs (iOS and Android).
 *
 * Native counterparts:
 * - iOS:     ios/App/App/MeetingLawyersPlugin.swift
 * - Android: android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersPlugin.java
 *            and MeetingLawyersFirebaseService.java (push)
 *
 * Copy those three native files plus this folder into your own Capacitor project
 * to integrate the SDK without spreading native imports.
 */
export interface MeetingLawyersPlugin {
  /** Initializes the SDK. Call once at app startup, before any other method. */
  configure(options: ConfigureOptions): Promise<void>;
  /** Applies the theme colors. Requires configure() first. */
  configureTheme(options: ThemeOptions): Promise<void>;
  /** Authenticates the user in the SDK. Requires configure() first. */
  authenticate(options: AuthenticateOptions): Promise<void>;
  /** Opens the native professional list. Tapping a professional opens its chat. */
  openProfessionalList(): Promise<void>;
  /** Opens the chat with a specific professional. */
  openChatWithProfessional(options: OpenChatOptions): Promise<void>;
  /**
   * Asks for notification permission and registers the device FCM token with
   * the SDK. Call it right after authenticate() so the token is linked to the user.
   */
  registerForPushNotifications(): Promise<void>;
  /** Whether a user is currently authenticated in the SDK. */
  isAuthenticated(): Promise<IsAuthenticatedResult>;
  /** Logs the user out of the SDK. */
  logout(): Promise<void>;
}
