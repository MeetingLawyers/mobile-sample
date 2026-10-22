import 'package:flutter/services.dart';

/// Which professional list to open.
enum ProfessionalType { lawyers, doctors, vets }

/// MeetingDoctors features a company may have.
enum DoctorsFeature { videoCall, medicalHistory, myHealth, booking, appointments }

/// Bridge to MeetingLawyers (lawyers) and MeetingDoctors (doctors and vets).
///
/// Copy this file plus the native `MeetingProsChannel` and `MeetingProsIntegration` files of each
/// platform: they are the only code that imports the SDKs.
class MeetingPros {
  static const _channel = MethodChannel('meeting_pros');

  /// Configures both SDKs. `isProduction: false` = lawyers demo + doctors staging.
  static Future<void> configure({
    required String lawyersApiKey,
    required String doctorsApiKey,
    required bool isProduction,
  }) =>
      _channel.invokeMethod('configure', {
        'lawyersApiKey': lawyersApiKey,
        'doctorsApiKey': doctorsApiKey,
        'isProduction': isProduction,
      });

  /// Applies the brand color (0xAARRGGBB) to both SDKs.
  static Future<void> configureTheme(int color) => _channel.invokeMethod('configureTheme', {'color': color});

  /// Signs the user into both SDKs, asks for push permission and registers the push token.
  static Future<void> authenticate(String userId) => _channel.invokeMethod('authenticate', {'userId': userId});

  /// Opens the lawyers, doctors or vets list. Tapping a professional opens its chat.
  static Future<void> openProfessionalList(ProfessionalType type) =>
      _channel.invokeMethod('openProfessionalList', {'type': type.name});

  /// Opens the chat with a lawyer.
  static Future<void> openLawyerChat(String professionalHash) =>
      _channel.invokeMethod('openLawyerChat', {'professionalHash': professionalHash});

  /// The MeetingDoctors features the company has. Call it after [authenticate].
  static Future<Set<DoctorsFeature>> availableFeatures() async {
    final names = await _channel.invokeListMethod<String>('availableFeatures') ?? [];
    return DoctorsFeature.values.where((feature) => names.contains(feature.name)).toSet();
  }

  /// Opens a MeetingDoctors feature; fails when the company does not have it.
  static Future<void> openFeature(DoctorsFeature feature) =>
      _channel.invokeMethod('openFeature', {'feature': feature.name});

  /// True only while the user is signed into both SDKs.
  static Future<bool> isAuthenticated() async => await _channel.invokeMethod<bool>('isAuthenticated') ?? false;

  /// Signs the user out of both SDKs.
  static Future<void> logout() => _channel.invokeMethod('logout');
}
