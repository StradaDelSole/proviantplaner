# Proviantplaner – Umsetzungsplan in Slices v0.1

Stand: 23.09.2026 · Grundlage: `docs/PRD_v0.7.md`

Jeder Slice ist eine abgeschlossene Arbeitseinheit für eine Gemini-Sitzung: klein genug für eine Standzeit, mit klaren Abnahmekriterien. Ein Slice gilt erst als fertig, wenn alle Kriterien erfüllt sind und die Tests grün laufen.

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 11 Slices für v1 auf Basis PRD v0.7 |

## Technische Leitplanken (für alle Slices)

- Flutter stable, Dart mit null safety, nur iOS und Android
- State-Management: Riverpod
- Lokale Datenbank: drift (SQLite)
- Navigation: go_router
- Übersetzung: flutter_localizations + intl mit ARB-Dateien
- Sichere Token-Ablage: flutter_secure_storage
- Offline zuerst: Keine Funktion außer Login, Sicherung und Konto löschen darf Netz voraussetzen
- HullQ-Anbindung nur über ein Interface (`HullqAuthService`, `HullqBackupService`) mit Mock-Implementierung, bis die echte API steht
- Keine Bootsinhalte, keine Push-Nachrichten, keine Werbung in der App
- Rechenlogik (Mengen, Bordkasse, Freischaltung) als reines Dart ohne Flutter-Abhängigkeit, mit Unit-Tests

## Slices

| Nr | Slice | Tag laut PRD |
| --- | --- | --- |
| S0 | Projekt-Setup und Architektur | 1 |
| S1 | Datenmodell und lokale Datenbank | 1 |
| S2 | Mengen-Engine | 1 |
| S3 | Törn anlegen | 1 |
| S4 | Menüplan und Einkaufsliste | 2 |
| S5 | Bordkasse | 2 |
| S6 | Freischaltungslogik Probetörn, Mitglied, Pro | 3 |
| S7 | HullQ-Login, Einwilligung, Konto löschen (Mock) | 3 |
| S8 | Sicherung, Wiederherstellung, Export | 3 |
| S9 | Sechs Sprachen und Formate | 4 |
| S10 | Store-Bereitschaft | 5 |

### S0 – Projekt-Setup und Architektur

- Flutter-Projekt `proviantplaner` im Repo-Root anlegen, Ordnerstruktur feature-first: `lib/core`, `lib/features/<feature>/{data,domain,ui}`, `lib/l10n`
- Pakete aus den Leitplanken einbinden, Linting mit `flutter_lints`
- Startbildschirm mit App-Name (Platzhalter) und dezentem "powered by HullQ"

**Abnahme:** App startet auf iOS-Simulator und Android-Emulator; `flutter analyze` ohne Fehler; `flutter test` läuft.

### S1 – Datenmodell und lokale Datenbank

Entitäten: `Trip` (Name, Start, Tage, Revier, Kühlkapazität, Bootstyp Mono/Kat, Abende an Bord, Appetit-Faktor), `CrewMember` (Name, Essgewohnheiten), `ShoppingItem` (Artikel, Menge, Einheit, Abteilung, erledigt), `Expense` (Betrag, Währung, bezahlt von, aufgeteilt auf), `Recipe` (optional, eigene Mengen).

**Abnahme:** CRUD für alle Entitäten mit drift; Migrationstest; Daten überleben App-Neustart.

### S2 – Mengen-Engine

- Liest `data/quantities_v0.1.json` als Asset
- Berechnet aus Trip und Crew: Trinkwasser gesamt, Frühstück und Grundvorrat, Hauptmahlzeiten für die Abende an Bord, angewendet Appetit-Faktor und Urlaubszuschlag
- Warnung, wenn frische Mengen der ersten 3 Tage die Kühlkapazität grob übersteigen

**Abnahme:** Unit-Tests mit festen Beispielen, z. B. 6 Personen, 7 Tage, Mittelmeer, 5 Abende an Bord, Faktor 1,0 ergeben nachvollziehbare Summen; Ränder (1 Person, 14 Tage, Faktor 0,8 und 1,25) getestet.

### S3 – Törn anlegen

Formular in wenigen Schritten: Name und Datum, Crew mit Essgewohnheiten, Revier, Boot und Kühlkapazität, Abende an Bord, Appetit.

**Abnahme:** Ein Törn lässt sich in unter 2 Minuten anlegen und bearbeiten; Validierung verständlich.

### S4 – Menüplan und Einkaufsliste

- Menüplan pro Tag aus der Mengen-Engine, Essgewohnheiten berücksichtigt (z. B. vegetarische Personen ohne Fleischanteil)
- Einkaufsliste gruppiert nach Supermarkt-Abteilung, abhakbar, manuell ergänzbar
- Hinweis "frisch nachkaufen" ab Tag 4

**Abnahme:** Liste funktioniert komplett offline; Abhaken bleibt nach Neustart erhalten.

### S5 – Bordkasse

- Ausgaben erfassen: Betrag, Währung, wer hat bezahlt, für wen
- Ausgleich "wer schuldet wem" mit möglichst wenigen Überweisungen
- Mehrere Währungen nur im Probetörn und in Pro (siehe S6)

**Abnahme:** Unit-Tests für den Ausgleich, inklusive ungleicher Aufteilung und Rundung auf Cent; Summe aller Salden ist immer 0.

### S6 – Freischaltungslogik

Reine Dart-Logik `Entitlements`: Probetörn (erster Törn, alles frei), Mitglied (HullQ-Login, unbegrenzte Törns, Funktionen laut PRD-Tabelle), Pro (Abo, Mock bis v1.1).

**Abnahme:** Unit-Tests decken jede Zeile der Funktionstabelle im PRD ab; der zweite Törn zeigt den Freischalten-Dialog.

### S7 – HullQ-Login, Einwilligung, Konto löschen

- Login-Bildschirm: E-Mail, Sign in with Apple, Google
- Checkbox "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden", nicht vorausgewählt; Wert wird an `HullqAuthService` übergeben
- Token in `flutter_secure_storage`; Status offline tolerant
- Menüpunkt "Konto löschen" mit Bestätigung
- Implementierung gegen `MockHullqAuthService`

**Abnahme:** Freischaltung funktioniert mit Mock; Checkbox ist beim Öffnen immer leer; Konto löschen entfernt Token und lokale Kontodaten.

### S8 – Sicherung, Wiederherstellung, Export

- Sicherung der Törns über `HullqBackupService` (Mock), nur für Mitglieder
- Wiederherstellung nach Neuinstallation
- Export von Einkaufsliste und Abrechnung als PDF und über das Teilen-Menü

**Abnahme:** Neuinstallation plus Login stellt alle Törns wieder her (Mock); PDF öffnet sich korrekt.

### S9 – Sechs Sprachen und Formate

ARB-Dateien für DE, EN, FR, ES, PT, HR; Lebensmittel und Abteilungen übersetzt; Zahlen, Datum und Währung nach Gerätesprache.

**Abnahme:** Keine fest eingebauten Texte mehr im Code; jede Sprache einmal komplett durchgeklickt.

### S10 – Store-Bereitschaft

App-Icons, Splash, Datenschutzerklärung verlinkt, App Privacy und Datensicherheit vorbereitet, Store-Texte in sechs Sprachen, Screenshots.

**Abnahme:** Checkliste Store-Pflichten aus dem PRD vollständig abgehakt.
