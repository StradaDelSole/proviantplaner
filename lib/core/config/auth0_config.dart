/// Konfiguration für Auth0 Native Authentication (Slice BC-1A).
class Auth0Config {
  const Auth0Config({
    this.domain = const String.fromEnvironment('AUTH0_DOMAIN', defaultValue: 'auth.hullq.com'),
    this.clientId = const String.fromEnvironment('AUTH0_CLIENT_ID', defaultValue: ''),
    this.audience = const String.fromEnvironment('AUTH0_AUDIENCE', defaultValue: 'https://api.planer.hullq.com'),
    this.customScheme = const String.fromEnvironment('AUTH0_CUSTOM_SCHEME', defaultValue: 'provy'),
  });

  /// Auth0 Tenant Domain (Host ohne Protokoll, z.B. auth.hullq.com).
  final String domain;

  /// Public Client ID der Auth0 Native Application.
  final String clientId;

  /// Provy API Audience für Access Tokens.
  final String audience;

  /// Custom Scheme für Android Redirects (z.B. provy).
  final String customScheme;

  /// Standard-Instanz.
  static const Auth0Config standard = Auth0Config();
}
