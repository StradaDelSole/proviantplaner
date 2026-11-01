import 'package:flutter/foundation.dart';

/// Konfiguration für Auth0 Native Authentication (Slice BC-1A).
class Auth0Config {
  /// Erwartete native Werte gemäß AndroidManifest.xml / iOS Info.plist und Auth0 Runbook.
  static const String expectedNativeDomain = 'auth.hullq.com';
  static const String expectedNativeScheme = 'provy';
  static const String expectedNativeAudience = 'https://api.planer.hullq.com';
  static const String nativeApplicationId = 'com.hullq.proviantplaner';

  const Auth0Config({
    this.domain = const String.fromEnvironment('AUTH0_DOMAIN', defaultValue: expectedNativeDomain),
    this.clientId = const String.fromEnvironment('AUTH0_CLIENT_ID', defaultValue: ''),
    this.audience = const String.fromEnvironment('AUTH0_AUDIENCE', defaultValue: expectedNativeAudience),
    this.customScheme = const String.fromEnvironment('AUTH0_CUSTOM_SCHEME', defaultValue: expectedNativeScheme),
  });

  /// Auth0 Tenant Domain (Host ohne Protokoll, z.B. auth.hullq.com).
  final String domain;

  /// Public Client ID der Auth0 Native Application.
  final String clientId;

  /// Provy API Audience für Access Tokens.
  final String audience;

  /// Custom Scheme für Android Redirects (z.B. provy).
  final String customScheme;

  static const Set<String> _knownPlaceholders = {
    'provy-app-client',
    'placeholder',
    'todo',
    'client_id',
    'your_client_id',
    'insert_client_id_here',
  };

  /// Prüft, ob die Konfiguration konsistent mit den nativen Manifest-/URL-Scheme-Registrierungen ist.
  bool get isValid {
    final cleanClientId = clientId.trim();
    if (cleanClientId.isEmpty) return false;
    if (_knownPlaceholders.contains(cleanClientId.toLowerCase())) return false;
    if (domain != expectedNativeDomain) return false;
    if (customScheme != expectedNativeScheme) return false;
    if (audience != expectedNativeAudience) return false;
    return true;
  }

  /// Erwartete Redirect-Callback-URL für die jeweilige Plattform.
  String callbackUrlFor(TargetPlatform platform) {
    if (platform == TargetPlatform.android) {
      return '$customScheme://$domain/android/$nativeApplicationId/callback';
    } else {
      return '$nativeApplicationId://$domain/ios/$nativeApplicationId/callback';
    }
  }

  /// Standard-Instanz.
  static const Auth0Config standard = Auth0Config();
}
