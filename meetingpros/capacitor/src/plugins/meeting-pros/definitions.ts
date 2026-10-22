export type MPEnvironment = 'DEV' | 'PROD';
export type ProfessionalType = 'lawyers' | 'doctors' | 'vets';
export type DoctorsFeature = 'videoCall' | 'medicalHistory' | 'myHealth' | 'booking' | 'appointments';

export interface ConfigureOptions {
  /** MeetingLawyers API key of your MeetingPros company. */
  lawyersApiKey: string;
  /** MeetingDoctors API key of your MeetingPros company. */
  doctorsApiKey: string;
  /** 'DEV' = lawyers demo + doctors staging. Defaults to 'PROD'. */
  environment?: MPEnvironment;
}

export interface ThemeOptions {
  /** Brand color as '#RRGGBB' or '#RRGGBBAA', applied to both SDKs. */
  primaryColor: string;
}

export interface AuthenticateOptions {
  /** User identifier valid for both companies. */
  userId: string;
}

export interface OpenListOptions {
  type: ProfessionalType;
}

export interface OpenLawyerChatOptions {
  professionalHash: string;
}

export interface FeaturesResult {
  features: DoctorsFeature[];
}

export interface OpenFeatureOptions {
  feature: DoctorsFeature;
}

export interface IsAuthenticatedResult {
  authenticated: boolean;
}

/**
 * Bridge to MeetingLawyers (lawyers) and MeetingDoctors (doctors and vets).
 *
 * Native counterparts, the only code that imports the SDKs:
 * - iOS:     ios/App/App/MeetingProsPlugin.swift + MeetingProsIntegration.swift
 * - Android: android/app/src/main/java/.../MeetingProsPlugin.kt + MeetingProsIntegration.kt
 */
export interface MeetingProsPlugin {
  /** Configures both SDKs. Call once at app startup, before any other method. */
  configure(options: ConfigureOptions): Promise<void>;
  /** Applies the brand color to both SDKs. */
  configureTheme(options: ThemeOptions): Promise<void>;
  /** Signs the user into both SDKs, asks for push permission and registers the push token. */
  authenticate(options: AuthenticateOptions): Promise<void>;
  /** Opens the lawyers, doctors or vets list. Tapping a professional opens its chat. */
  openProfessionalList(options: OpenListOptions): Promise<void>;
  /** Opens the chat with a lawyer. */
  openLawyerChat(options: OpenLawyerChatOptions): Promise<void>;
  /** The MeetingDoctors features the company has. Call it after authenticate(). */
  availableFeatures(): Promise<FeaturesResult>;
  /** Opens a MeetingDoctors feature; fails when the company does not have it. */
  openFeature(options: OpenFeatureOptions): Promise<void>;
  /** True only while the user is signed into both SDKs. */
  isAuthenticated(): Promise<IsAuthenticatedResult>;
  /** Signs the user out of both SDKs. */
  logout(): Promise<void>;
}
