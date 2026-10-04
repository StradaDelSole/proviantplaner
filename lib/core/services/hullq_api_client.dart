import 'dart:convert';
import 'dart:io';

/// Fehlerklasse für Backend-API-Fehler.
class HullqApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const HullqApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'HullqApiException($statusCode, $code): $message';
}

/// Schnittstelle für den Zugriff auf die Planer-Backend-API (Cloudflare Worker).
abstract class HullqApiClient {
  /// Ruft Kontoinformationen und Status über GET /v1/me ab.
  Future<Map<String, dynamic>> getMe(String token);

  /// Speichert oder widerruft eine Einwilligung über PUT /v1/consents/boat-market-news.
  Future<Map<String, dynamic>> updateConsent(
    String token, {
    required bool granted,
    required String textVersion,
  });

  /// Löscht das Konto und alle Daten über DELETE /v1/me.
  Future<void> deleteMe(String token);

  /// Lädt eine Sicherung über POST /v1/backups hoch.
  Future<Map<String, dynamic>> uploadBackup(
    String token, {
    required String deviceId,
    required String content,
  });

  /// Ruft die Liste der Sicherungen über GET /v1/backups ab.
  Future<List<Map<String, dynamic>>> getBackups(String token);

  /// Lädt den Inhalt einer Sicherung über GET /v1/backups/{id} herunter.
  Future<String> downloadBackup(String token, String backupId);
}

/// Standard-Implementierung von [HullqApiClient] mit [HttpClient] (ohne Zusatzpakete).
class HttpHullqApiClient implements HullqApiClient {
  final String baseUrl;
  final HttpClient _httpClient;

  HttpHullqApiClient({
    this.baseUrl = 'https://api.planer.hullq.com',
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  @override
  Future<Map<String, dynamic>> getMe(String token) async {
    final uri = Uri.parse('$baseUrl/v1/me');
    final request = await _httpClient.getUrl(uri);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Accept', 'application/json');

    final response = await request.close();
    final bodyString = await response.transform(utf8.decoder).join();
    final dynamic json = jsonDecode(bodyString);

    if (response.statusCode >= 400) {
      final error = json is Map<String, dynamic> ? json['error'] as Map<String, dynamic>? : null;
      throw HullqApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? 'Fehler beim Abruf des Profils',
      );
    }

    return json as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateConsent(
    String token, {
    required bool granted,
    required String textVersion,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/consents/boat-market-news');
    final request = await _httpClient.putUrl(uri);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');

    final payload = jsonEncode({
      'granted': granted,
      'text_version': textVersion,
    });
    request.write(payload);

    final response = await request.close();
    final bodyString = await response.transform(utf8.decoder).join();
    final dynamic json = jsonDecode(bodyString);

    if (response.statusCode >= 400) {
      final error = json is Map<String, dynamic> ? json['error'] as Map<String, dynamic>? : null;
      throw HullqApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? 'Fehler beim Setzen der Einwilligung',
      );
    }

    return json as Map<String, dynamic>;
  }

  @override
  Future<void> deleteMe(String token) async {
    final uri = Uri.parse('$baseUrl/v1/me');
    final request = await _httpClient.deleteUrl(uri);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Accept', 'application/json');

    final response = await request.close();
    final bodyString = await response.transform(utf8.decoder).join();
    final dynamic json = jsonDecode(bodyString);

    if (response.statusCode >= 400) {
      final error = json is Map<String, dynamic> ? json['error'] as Map<String, dynamic>? : null;
      throw HullqApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? 'Fehler beim Löschen des Kontos',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> uploadBackup(
    String token, {
    required String deviceId,
    required String content,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/backups');
    final request = await _httpClient.postUrl(uri);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');

    final payload = jsonEncode({
      'device_id': deviceId,
      'content': content,
    });
    request.write(payload);

    final response = await request.close();
    final bodyString = await response.transform(utf8.decoder).join();
    final dynamic json = jsonDecode(bodyString);

    if (response.statusCode >= 400) {
      final error = json is Map<String, dynamic> ? json['error'] as Map<String, dynamic>? : null;
      throw HullqApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? 'Fehler beim Hochladen der Sicherung',
      );
    }

    return json as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getBackups(String token) async {
    final uri = Uri.parse('$baseUrl/v1/backups');
    final request = await _httpClient.getUrl(uri);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Accept', 'application/json');

    final response = await request.close();
    final bodyString = await response.transform(utf8.decoder).join();
    final dynamic json = jsonDecode(bodyString);

    if (response.statusCode >= 400) {
      final error = json is Map<String, dynamic> ? json['error'] as Map<String, dynamic>? : null;
      throw HullqApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? 'Fehler beim Abrufen der Sicherungen',
      );
    }

    final rawList = (json as Map<String, dynamic>)['backups'] as List<dynamic>? ?? [];
    return rawList.map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<String> downloadBackup(String token, String backupId) async {
    final uri = Uri.parse('$baseUrl/v1/backups/$backupId');
    final request = await _httpClient.getUrl(uri);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Accept', 'application/json');

    final response = await request.close();
    final bodyString = await response.transform(utf8.decoder).join();
    final dynamic json = jsonDecode(bodyString);

    if (response.statusCode >= 400) {
      final error = json is Map<String, dynamic> ? json['error'] as Map<String, dynamic>? : null;
      throw HullqApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? 'Fehler beim Herunterladen der Sicherung',
      );
    }

    return (json as Map<String, dynamic>)['content'] as String;
  }
}
