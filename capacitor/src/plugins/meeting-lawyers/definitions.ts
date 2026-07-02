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
 * Bridge to the native MeetingLawyers SDKs (iOS and Android).
 *
 * Native counterparts:
 * - iOS:     ios/App/App/MeetingLawyersPlugin.swift
 * - Android: android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersPlugin.java
 *
 * The three files (plus this folder) are self-contained: copy them into your
 * own Capacitor project to integrate the SDK without spreading native imports.
 */
export interface MeetingLawyersPlugin {
  /** Initializes the SDK. Call once at app startup, before any other method. */
  configure(options: ConfigureOptions): Promise<void>;
  /** Authenticates the user in the SDK. Requires configure() first. */
  authenticate(options: AuthenticateOptions): Promise<void>;
  /** Opens the native professional list. Tapping a professional opens its chat. */
  openProfessionalList(): Promise<void>;
  /** Opens the chat with a specific professional. */
  openChatWithProfessional(options: OpenChatOptions): Promise<void>;
  /** Whether a user is currently authenticated in the SDK. */
  isAuthenticated(): Promise<IsAuthenticatedResult>;
  /** Logs the user out of the SDK. */
  logout(): Promise<void>;
}
