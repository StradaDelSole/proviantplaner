import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    test('lightTheme has correct brightness and primary color', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppTheme.primaryNavy);
      expect(theme.useMaterial3, true);
    });

    test('darkTheme has correct brightness and Material 3', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, true);
    });
  });

  group('MockHullqAuthService Tests', () {
    test('initial status is trial and token is null', () async {
      final auth = MockHullqAuthService();
      expect(await auth.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await auth.getAuthToken(), isNull);
    });

    test('loginWithEmail sets member status and token', () async {
      final auth = MockHullqAuthService();
      final success = await auth.loginWithEmail('test@hullq.com', newsletterOptIn: false);
      expect(success, isTrue);
      expect(await auth.getMembershipStatus(), HullqMembershipStatus.member);
      expect(await auth.getAuthToken(), 'mock_token_test@hullq.com');
    });

    test('logout resets status and token', () async {
      final auth = MockHullqAuthService();
      await auth.loginWithApple(newsletterOptIn: false);
      expect(await auth.getMembershipStatus(), HullqMembershipStatus.member);
      await auth.logout();
      expect(await auth.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await auth.getAuthToken(), isNull);
    });
  });

  group('MockHullqBackupService Tests', () {
    test('backup and restore work as expected', () async {
      final backup = MockHullqBackupService();
      expect(await backup.restoreData(), isNull);
      expect(await backup.getLastBackupTimestamp(), isNull);

      final success = await backup.backupData('{"trips": []}');
      expect(success, isTrue);
      expect(await backup.restoreData(), '{"trips": []}');
      expect(await backup.getLastBackupTimestamp(), isNotNull);
    });
  });
}