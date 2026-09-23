# Proviantplaner – Umsetzungsplan in Slices v0.2

Stand: 23.09.2026 · Grundlage: `docs/PRD_v0.8.md`, `docs/KATALOG_v0.2.md`

Jeder Slice ist eine abgeschlossene Arbeitseinheit für eine Gemini-Sitzung: klein genug für eine Standzeit, mit klaren Abnahmekriterien. Ein Slice gilt erst als fertig, wenn alle Kriterien erfüllt sind und die Tests grün laufen.

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 11 Slices für v1 auf Basis PRD v0.7 |
| v0.2 | 23.09.2026 | Angepasst an PRD v0.8: Vorratsliste statt Menüplan als Kern, Konsumprofile, Überschreiben von Mengen, Einlagerungs-Checkliste, Charter oder eigenes Boot; Menüplan nach v1.1 |

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
- Katalog und Mengen nur aus `data/catalog_v0.2.json` und `data/quantities_v0.2.json` lesen, nie hart codieren
- Rechenlogik (Mengen, Bordkasse, Freischaltung) als reines Dart ohne Flutter-Abhängigkeit, mit Unit-Tests

## Slices

| Nr | Slice | Tag laut PRD |
| --- | --- | --- |
| S0 | Projekt-Setup und Architektur | 1 |
| S1 | Datenmodell und lokale Datenbank | 1 |
| S2 | Mengen-Engine mit Katalog und Konsumprofilen | 2 |
| S3 | Törn anlegen | 1 |
| S4 | Vorratsliste und Einlagerungs-Checkliste | 2–3 |
| S5 | Bordkasse | 3 |
| S6 | Freischaltungslogik Probetörn, Mitglied, Pro | 4 |
| S7 | HullQ-Login, Einwilligung, Konto löschen (Mock) | 4 |
| S8 | Sicherung, Wiederherstellung, Export | 4 |
| S9 | Sechs Sprachen und Formate | 5 |
| S10 | Store-Bereitschaft | 6–7 |

### S0 – Projekt-Setup und Architektur

- Flutter-Projekt `proviantplaner` im Repo-Root anlegen, Ordnerstruktur feature-first: `lib/core`, `lib/features/<feature>/{data,domain,ui}`, `lib/l10n`
- Pakete aus den Leitplanken einbinden, Linting mit `flutter_lints`
- Startbildschirm mit App-Name (Platzhalter) und dezentem "powered by HullQ"

**Abnahme:** App startet auf iOS-Simulator und Android-Emulator; `flutter analyze` ohne Fehler; `flutter test` läuft.

### S1 – Datenmodell und lokale Datenbank

Entitäten: `Trip` (Name, Start, Tage, Revier, Charter oder eigenes Boot, Bootstyp Mono/Kat, Kühlkapazität, Abende an Bord, Einlagerungs-Checkliste an/aus), `CrewMember` (Name, Erwachsener/Kind, vegetarisch, Essprofil, Trinkprofil, Essgewohnheiten), `ListItem` (Katalog-ID oder eigene Position, berechnete Menge, überschriebene Menge oder leer, abgewählt, gekauft, eingelagert), `Expense` (Betrag, Währung, bezahlt von, aufgeteilt auf).

**Abnahme:** CRUD für alle Entitäten mit drift; Migrationstest; Daten überleben App-Neustart.

### S2 – Mengen-Engine mit Katalog und Konsumprofilen

- Liest `data/catalog_v0.2.json` und `data/quantities_v0.2.json` als Assets
- Berechnet für jede Katalogposition die Menge nach Rechenbasis (`per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`)
- Wendet pro Crewmitglied an: Essprofil auf Positionen mit Profil `eat`, Trinkprofil auf `drink`, Kinderfaktor, `applies_to` (vegetarisch, nicht vegetarisch, Erwachsene)
- Wochenmengen anteilig auf die Törnlänge, `per_crew_week` mit angefangener Woche voll, Ergebnis sinnvoll gerundet
- Überschriebene Mengen werden nie neu berechnet; "zurücksetzen" setzt die Überschreibung auf leer
- Warnung, wenn frische Mengen der ersten 3 Tage die Kühlkapazität grob übersteigen

**Abnahme:** Unit-Tests mit festen Beispielen (z. B. 5 Erwachsene, davon 1 vegetarisch und 1 ohne Alkohol, 7 Tage, Mittelmeer, 4 Bordabende); Tests für jede Rechenbasis, für Profile und für Überschreibungen, die eine Crewänderung überleben.

### S3 – Törn anlegen

Formular in wenigen Schritten: Name und Datum, Charter oder eigenes Boot, Revier, Boot und Kühlkapazität, Abende an Bord, Crew mit Erwachsener/Kind, vegetarisch, Essprofil (klein, normal, groß) und Trinkprofil (keiner, wenig, normal, viel).

**Abnahme:** Ein Törn mit 5 Personen lässt sich in unter 2 Minuten anlegen und bearbeiten; Profile haben sinnvolle Standardwerte (normal).

### S4 – Vorratsliste und Einlagerungs-Checkliste

- Vorratsliste gruppiert nach Supermarkt-Abteilung, alternativ nach Kategorie
- Jede Position: berechnete Menge, Überschreiben per Tipp (auch als Gesamtzahl), Markierung "überschrieben", "zurücksetzen", abwählen, eigene Positionen hinzufügen
- Technik-Positionen mit `hidden_for_charter` beim Charter eingeklappt
- Abhaken beim Einkauf; danach Modus "Einlagerung" mit den Hinweisen aus `storage_hints`, im Revier `hot_or_remote` standardmäßig aktiv
- Hinweis, dass Ernährungs-Tags kein Allergieschutz sind

**Abnahme:** Liste funktioniert komplett offline; Überschreibungen, Abwahlen und Häkchen bleiben nach Neustart und nach Crewänderung erhalten.

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
