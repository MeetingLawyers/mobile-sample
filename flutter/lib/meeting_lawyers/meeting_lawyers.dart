import 'package:flutter/services.dart';

/// Bridge to the MeetingLawyers SDK.
///
/// Copy this file plus the native `MeetingLawyersChannel` and `MeetingLawyersIntegration` files of each
/// platform: they are the only code that imports the SDK.
class MeetingLawyers {
  static const _channel = MethodChannel('meeting_lawyers');

  /// Configures the SDK. `isProduction: false` = demo environment.
  static Future<void> configure({required String apiKey, required bool isProduction}) =>
      _channel.invokeMethod('configure', {'apiKey': apiKey, 'isProduction': isProduction});

  /// Applies the theme colors (0xAARRGGBB). Every color is optional; the ones left out keep the SDK default.
  static Future<void> configureTheme({
    int? primaryColor,
    int? secondaryColor,
    int? navigationBarColor,
    int? incomingMessageColor,
    int? outgoingMessageColor,
  }) =>
      _channel.invokeMethod('configureTheme', {
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'navigationBarColor': navigationBarColor,
        'incomingMessageColor': incomingMessageColor,
        'outgoingMessageColor': outgoingMessageColor,
      });

  /// Signs the user in, asks for push permission and registers the push token.
  static Future<void> authenticate(String userId) => _channel.invokeMethod('authenticate', {'userId': userId});

  /// Opens the professional list. Tapping a professional opens its chat.
  static Future<void> openProfessionalList() => _channel.invokeMethod('openProfessionalList');

  /// Opens the chat with a professional.
  static Future<void> openChat(String professionalHash) =>
      _channel.invokeMethod('openChat', {'professionalHash': professionalHash});

  /// True while a user is signed in.
  static Future<bool> isAuthenticated() async => await _channel.invokeMethod<bool>('isAuthenticated') ?? false;

  /// Signs the user out.
  static Future<void> logout() => _channel.invokeMethod('logout');
}
