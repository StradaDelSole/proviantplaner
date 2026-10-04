import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/config/app_config.dart';

void main() {
  group('S10-T Store-Bereitschaft (ohne Veröffentlichung)', () {
    test('1. App-Name zentral als Konstante definiert und nur an einer Stelle im Dart-Code', () {
      // 1. AppConfig.appName ist 'Provy'
      expect(AppConfig.appName, equals('Provy'));

      // 2. Suche in allen Dart-Dateien unter lib/
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib-Verzeichnis muss existieren');

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final filesWithLiteral = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Suche nach String-Literal 'Provy' oder "Provy"
        if (content.contains("'Provy'") || content.contains('"Provy"')) {
          filesWithLiteral.add(file.path.replaceAll(r'\', '/'));
        }
      }

      // Darf NUR in lib/core/config/app_config.dart vorkommen!
      expect(
        filesWithLiteral,
        equals(['lib/core/config/app_config.dart']),
        reason: 'Der App-Name darf als Literal ausschließlich in app_config.dart definiert sein',
      );

      // 3. Android strings.xml enthält ebenfalls Provy
      final stringsFile = File('android/app/src/main/res/values/strings.xml');
      expect(stringsFile.existsSync(), isTrue);
      expect(stringsFile.readAsStringSync(), contains('<string name="app_name">Provy</string>'));

      // 4. AndroidManifest.xml referenziert @string/app_name
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);
      expect(manifestFile.readAsStringSync(), contains('android:label="@string/app_name"'));
    });

    test('2. Suchtest: Kein Keystore, keine key.properties und keine Passwörter im Repository', () {
      // Prüfe Git-Status bzw. getrackte Dateien
      final gitResult = Process.runSync('git', ['ls-files']);
      expect(gitResult.exitCode, equals(0), reason: 'git ls-files muss erfolgreich sein');

      final trackedFiles = (gitResult.stdout as String)
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList();

      for (final path in trackedFiles) {
        // Kein .jks oder .keystore im Repo
        expect(
          path.endsWith('.jks') || path.endsWith('.keystore'),
          isFalse,
          reason: 'Keystore-Datei darf niemals getrackt werden: $path',
        );

        // Keine key.properties im Repo
        expect(
          path.endsWith('key.properties'),
          isFalse,
          reason: 'key.properties darf niemals getrackt werden: $path',
        );
      }

      // Prüfe .gitignore auf Ausschlussregeln
      final gitignore = File('.gitignore').readAsStringSync();
      expect(gitignore, contains('*.jks'));
      expect(gitignore, contains('*.keystore'));
      expect(gitignore, contains('key.properties'));

      // Prüfe android/app/build.gradle auf Signatur-Konfiguration mit Fallback
      final buildGradle = File('android/app/build.gradle').readAsStringSync();
      expect(buildGradle, contains('rootProject.file(\'key.properties\')'));
      expect(buildGradle, contains('signingConfigs.debug'));
    });

    test('3. Zentrale Links zu Rechtlichem und Kontolöschung als gültige URIs definiert', () {
      final urls = [
        AppConfig.privacyPolicyUrl,
        AppConfig.imprintUrl,
        AppConfig.termsOfServiceUrl,
        AppConfig.deleteAccountUrl,
      ];

      for (final url in urls) {
        expect(url, isNotEmpty);
        final uri = Uri.tryParse(url);
        expect(uri, isNotNull, reason: 'URL muss parsebar sein: $url');
        expect(uri!.scheme, equals('https'), reason: 'URL muss https sein: $url');
        expect(uri.host, equals('planer.hullq.com'), reason: 'Host muss planer.hullq.com sein: $url');
        expect(uri.path, isNotEmpty, reason: 'Pfad darf nicht leer sein: $url');
      }

      expect(AppConfig.privacyPolicyUrl, equals('https://planer.hullq.com/datenschutz'));
      expect(AppConfig.imprintUrl, equals('https://planer.hullq.com/impressum'));
      expect(AppConfig.termsOfServiceUrl, equals('https://planer.hullq.com/nutzungsbedingungen'));
      expect(AppConfig.deleteAccountUrl, equals('https://planer.hullq.com/konto-loeschen'));
    });

    test('4. Version und Build-Nummer gepflegt; keine Crash-Reporting-SDKs in v1', () {
      expect(AppConfig.appVersion, equals('1.0.0'));
      expect(AppConfig.buildNumber, equals(1));

      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('version: 1.0.0+1'));

      // Keine Crash-Reporting-SDKs
      expect(pubspec.contains('firebase_crashlytics'), isFalse);
      expect(pubspec.contains('sentry'), isFalse);
      expect(pubspec.contains('bugsnag'), isFalse);
    });

    test('5. Platzhalter-Icon und Splash nach Design-System (Deep Navy, ohne Anker/Segel)', () {
      // colors.xml mit Deep Navy (#0A2540)
      final colorsFile = File('android/app/src/main/res/values/colors.xml');
      expect(colorsFile.existsSync(), isTrue);
      final colorsContent = colorsFile.readAsStringSync();
      expect(colorsContent, contains('<color name="ic_launcher_background">#0A2540</color>'));
      expect(colorsContent, contains('<color name="splash_background">#0A2540</color>'));

      // Adaptive Icon XML
      final adaptiveIcon = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml');
      expect(adaptiveIcon.existsSync(), isTrue);
      final adaptiveContent = adaptiveIcon.readAsStringSync();
      expect(adaptiveContent, contains('android:drawable="@color/ic_launcher_background"'));
      expect(adaptiveContent, contains('android:drawable="@drawable/ic_launcher_foreground"'));

      // Foreground Vector Drawable
      final foregroundIcon = File('android/app/src/main/res/drawable/ic_launcher_foreground.xml');
      expect(foregroundIcon.existsSync(), isTrue);
      final foregroundContent = foregroundIcon.readAsStringSync();
      expect(foregroundContent, contains('<vector'));

      // Keine maritimen Klischees (kein Anker, kein Segel)
      expect(foregroundContent.toLowerCase().contains('anchor'), isFalse);
      expect(foregroundContent.toLowerCase().contains('sail'), isFalse);

      // Splash Screen Konfiguration
      final splashFile = File('android/app/src/main/res/drawable/launch_background.xml');
      expect(splashFile.existsSync(), isTrue);
      expect(splashFile.readAsStringSync(), contains('@color/splash_background'));

      final splashV21 = File('android/app/src/main/res/drawable-v21/launch_background.xml');
      expect(splashV21.existsSync(), isTrue);
      expect(splashV21.readAsStringSync(), contains('@color/splash_background'));
    });
  });
}
