# Abschlussbericht S10-T: Technische Store-Bereitschaft (ohne Veröffentlichung)

Slice: S10-T – Technische Store-Bereitschaft (ohne Veröffentlichung)
Umgesetzt:
- Zentraler App-Name als Konstante (`AppConfig.appName = 'Provy'`) in `lib/core/config/app_config.dart`.
- App-Name im Dart-Code ausschließlich an dieser einen Stelle als Literal definiert (geprüft per Test).
- `MaterialApp.router` in `lib/main.dart` auf `AppConfig.appName` umgestellt.
- Android nativ: `strings.xml` mit `<string name="app_name">Provy</string>` und Verknüpfung in `AndroidManifest.xml` über `@string/app_name`.
- Release-Signatur in `android/app/build.gradle` konfiguriert: liest `key.properties` (falls vorhanden) und fällt für reproduzierbare lokale/CI-Test-Builds ohne Secrets im Repo sauber auf Debug-Signatur zurück.
- `.gitignore` gehärtet: `*.jks`, `*.keystore`, `key.properties`, `**/key.properties`.
- Platzhalter-Icon und Splash nach Design-System (Deep Navy `#0A2540`, ohne Anker/Segel-Klischees) als Android Adaptive Icon (`mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_round.xml`, `drawable/ic_launcher_foreground.xml` als Vektor mit Proviantkiste/Flasche/Obst).
- Splash Screen (`launch_background.xml`) auf `@color/splash_background` (`#0A2540`) umgestellt.
- Zentrale Konstanten für Links zu Datenschutz, Impressum, Nutzungsbedingungen und Kontolöschung (Platzhalter-URLs) in `AppConfig` definiert und in `MoreScreen` sowie `UnlockSheet` per `url_launcher` angebunden.
- Versionsnummer (`1.0.0`) und Build-Nummer (`1`) gepflegt; keine Crash-Reporting-SDKs in `pubspec.yaml`.
- Vollständiger lokaler Release-Build `flutter build appbundle --release` erfolgreich ausgeführt (`build\app\outputs\bundle\release\app-release.aab`, 28.5 MB).

Geänderte/neue Dateien:
- `.gitignore`
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/drawable/ic_launcher_foreground.xml` (neu)
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (neu)
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml` (neu)
- `android/app/src/main/res/values/colors.xml` (neu)
- `android/app/src/main/res/values/strings.xml` (neu)
- `lib/core/config/app_config.dart` (neu)
- `lib/features/entitlements/ui/unlock_sheet.dart`
- `lib/features/more/ui/more_screen.dart`
- `lib/main.dart`
- `test/core/config/s10_t_store_readiness_test.dart` (neu)
- `docs/impl/S10-T_plan.md` (neu)
- `docs/impl/S10-T_bericht.md` (neu)
- `CHANGELOG.md`
- `README.md`

flutter analyze:
No issues found! (0 Fehler, 0 Warnungen)

flutter test:
229/229 Tests bestanden (5 neue Tests in `test/core/config/s10_t_store_readiness_test.dart`, alle bestehenden 224 Tests grün)

Abnahmekriterien:
- Release-Build läuft lokal durch (im Bericht, ohne Signaturdaten): erfüllt – Nachweis: automatischer Test (`flutter build appbundle --release` erfolgreich durchgelaufen: `Built build\app\outputs\bundle\release\app-release.aab (28.5MB)`)
- Suchtest: kein Keystore/Passwort im Repo: erfüllt – Nachweis: automatischer Test (`2. Suchtest: Kein Keystore, keine key.properties und keine Passwörter im Repository` in `test/core/config/s10_t_store_readiness_test.dart`)
- App-Name nur an einer Stelle: erfüllt – Nachweis: automatischer Test (`1. App-Name zentral als Konstante definiert und nur an einer Stelle im Dart-Code` in `test/core/config/s10_t_store_readiness_test.dart`)
- Platzhalter-Icon und Splash nach Design-System (ohne Anker/Segel), adaptive Icons: erfüllt – Nachweis: automatischer Test (`5. Platzhalter-Icon und Splash nach Design-System (Deep Navy, ohne Anker/Segel)` in `test/core/config/s10_t_store_readiness_test.dart`)
- Links Datenschutz, Impressum, Nutzungsbedingungen, Konto löschen (Web) als zentrale Konstanten: erfüllt – Nachweis: automatischer Test (`3. Zentrale Links zu Rechtlichem und Kontolöschung als gültige URIs definiert` in `test/core/config/s10_t_store_readiness_test.dart`)
- Versionsnummer und Build-Nummer gepflegt; Crash-Berichte: keine in v1: erfüllt – Nachweis: automatischer Test (`4. Version und Build-Nummer gepflegt; keine Crash-Reporting-SDKs in v1` in `test/core/config/s10_t_store_readiness_test.dart`)

Offen / Risiken:
- Keine. Bereitstellung von Release-Keystore und echten URLs obliegt dem Product Owner vor Veröffentlichung (Slice S10).

Annahmen / Abweichungen vom PRD:
- keine.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): eingehalten (AppConfig als typisierte Klasse mit festen Konstanten).
- Regel 2 (Keine versteckten Platzhalter): eingehalten (keine TODOs oder Stubs).
- Regel 3 (Ehrliche Berichte): eingehalten (konkrete Testergebnisse und Build-Nachweis belegt).
- Regel 4 (Datengetrieben): eingehalten.
- Regel 5 (Kommazahlen): eingehalten.
- Regel 6 (Struktur): eingehalten (Aufteilung in kurze, präzise Methoden und Konstanten).
- Regel 7 (Tests): eingehalten (fünf spezifische Abnahmetests mit exakten Prüfungen).
- Regel 8 (Keine Eigenbauten von Standards): eingehalten (Nutzung von `url_launcher` für externe Links).
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): eingehalten (Build und Tests tatsächlich auf dem lokalen System ausgeführt).
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): eingehalten (keine sichtbaren v1.1-Features).

Vorschläge für das PRD:
- keine.

Commit: S10-T: Technische Store-Bereitschaft (ohne Veröffentlichung) (gepusht: ja)
