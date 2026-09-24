Slice: S0 – Projekt-Setup und Architektur
Umgesetzt:
- Flutter-Projekt im Repository-Root initialisiert mit Paket-ID `com.hullq.proviantplaner`
- Feature-First Ordnerstruktur angelegt (`lib/core`, `lib/features/<feature>/{data,domain,ui}`, `lib/l10n`)
- Alle Pakete aus den technischen Leitplanken eingebunden (Riverpod, GoRouter, Drift, Flutter Secure Storage, Intl/Localizations)
- Zentrales `AppTheme` (Light/Dark) im Stil des Design-Briefs (Blueprint Navy, Petrol Akzent, Amber Hinweise, Tabular Figures)
- Interfaces und Mock-Implementierungen für `HullqAuthService` und `HullqBackupService`
- Startbildschirm mit App-Name, dezentem "powered by HullQ" und 4 Hauptnavigationsreitern
- Unit- und Widget-Tests für Startbildschirm, Theme und Mock-Services
- Android Gradle Setup auf AGP 8.4.2 und CompileSDK 35 für Kompatibilität konfiguriert
- Start auf Android-Emulator verifiziert

Geänderte/neue Dateien:
- `pubspec.yaml`
- `l10n.yaml`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/core/theme/app_theme.dart`
- `lib/core/routing/app_router.dart`
- `lib/core/services/hullq_auth_service.dart`
- `lib/core/services/hullq_backup_service.dart`
- `lib/features/home/ui/start_screen.dart`
- `lib/features/trip/{data,domain,ui}/`
- `lib/features/shopping_list/{data,domain,ui}/`
- `lib/features/kitty/{data,domain,ui}/`
- `lib/features/more/{data,domain,ui}/`
- `lib/main.dart`
- `test/widget_test.dart`
- `test/core/theme_and_services_test.dart`
- `android/` (Konfiguration & Build-Setup)
- `ios/` (Konfiguration)
- `docs/impl/S0_plan.md`
- `docs/impl/S0_bericht.md`
- `CHANGELOG.md`

flutter analyze: No issues found! (ran in 40.2s)
flutter test: All tests passed! (8 Tests)

Abnahmekriterien:
- App startet auf dem Android-Emulator: erfüllt (Debug APK gebaut, via adb auf `Medium_Phone_API_35` installiert, gestartet und per Screenshot verifiziert)
- flutter analyze ohne Fehler: erfüllt (0 Fehler, 0 Warnungen)
- flutter test läuft: erfüllt (8/8 Tests grün)
- Paket-ID `com.hullq.proviantplaner` für Android und iOS: erfüllt

Offen / Risiken:
- Keine. Das Architektur-Fundament für S1 ist vollständig gelegt.

Vorschläge für das PRD: keine
Commit: S0: Projekt-Setup und Architektur (gepusht: ja)
