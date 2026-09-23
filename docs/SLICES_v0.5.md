# Proviantplaner – Umsetzungsplan in Slices v0.5

Stand: 23.09.2026 · Grundlage: `docs/PRD_v0.12.md`, `docs/KATALOG_v0.4.md`

Jeder Slice ist eine abgeschlossene Arbeitseinheit für eine Gemini-Sitzung: klein genug für eine Standzeit, mit klaren Abnahmekriterien. Ein Slice gilt erst als fertig, wenn alle Kriterien erfüllt sind und die Tests grün laufen.

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 11 Slices für v1 auf Basis PRD v0.7 |
| v0.2 | 23.09.2026 | Angepasst an PRD v0.8: Vorratsliste statt Menüplan als Kern, Konsumprofile, Überschreiben von Mengen, Einlagerungs-Checkliste, Charter oder eigenes Boot; Menüplan nach v1.1 |
| v0.3 | 23.09.2026 | S1, S2, S4 auf Katalog v0.4 umgestellt (Bedarfsgruppen, Varianten, split equal/each, Portionen, Sichtbarkeit, Prüflisten-Modus, frisch nachkaufen) |
| v0.4 | 23.09.2026 | Crew-Fragen statt Pflicht-Einstufung pro Person, Reserve-Schalter, Packungsanzeige mit +/−, intelligentes Runden und Gruppenausgleich, gemerkte Packungsgrößen |
| v0.5 | 23.09.2026 | S5 Bordkasse erweitert: zwei Kassenmodelle, Kategorien, Beteiligung pro Person und Kategorie, Skipper frei, EPC-QR und Zahlungslinks |
| v0.4.1 | 23.09.2026 | Verweis auf PRD v0.11; Hinweis: Törn-Code und Bestellung an die Basis sind v1.1 und nicht Teil dieser Slices. Vorbereitung in S6: Freischaltung so bauen, dass später eine zeitlich begrenzte Freischaltung per Code ergänzt werden kann |

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
- Katalog und Mengen nur aus `data/catalog_v0.4.json` und `data/quantities_v0.3.json` lesen, nie hart codieren
- Rechenlogik (Mengen, Bordkasse, Freischaltung) als reines Dart ohne Flutter-Abhängigkeit, mit Unit-Tests

## Slices

| Nr | Slice | Tag laut PRD |
| --- | --- | --- |
| S0 | Projekt-Setup und Architektur | 1 |
| S1 | Datenmodell und lokale Datenbank | 1 |
| S2 | Mengen-Engine mit Katalog und Konsumprofilen | 2 |
| S3 | Törn anlegen | 1 |
| S4 | Vorratsliste und Einlagerungs-Checkliste | 2–3 |
| S5 | Bordkasse und Kostenteilung | 3–4 |
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

Entitäten: `Trip` (Name, Start, Tage, Revier, Charter oder eigenes Boot, Bootstyp Mono/Kat, Kühlkapazität, Abende an Bord, Einlagerungs-Checkliste an/aus), `CrewMember` (Name, Erwachsener/Kind, vegetarisch, Essprofil, Trinkprofil, Essgewohnheiten), `ListItem` (Gruppen- oder Varianten-ID aus dem Katalog oder eigene Position, gewählt ja/nein, Anteil, berechnete Menge, überschriebene Menge oder leer, abgewählt, gekauft, eingelagert), `Expense` (Betrag, Währung, bezahlt von, aufgeteilt auf).

**Abnahme:** CRUD für alle Entitäten mit drift; Migrationstest; Daten überleben App-Neustart.

### S2 – Mengen-Engine mit Katalog und Konsumprofilen

- Liest `data/catalog_v0.4.json` und `data/quantities_v0.3.json` als Assets
- Berechnet den Bedarf pro Bedarfsgruppe nach Rechenbasis (`per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`)
- `split=equal`: Gruppenbedarf auf die gewählten Varianten verteilen (gleichmäßig oder nach Anteil); `split=each`: jede gewählte Variante mit eigenem `need`, sonst Gruppenbedarf je Variante; Portionen über `portion`
- In Packungen umrechnen nach `rounding` (haltbar immer aufrunden, frisch nur bis 25 % Überschuss, Gruppenausgleich), vom Nutzer geänderte Packungsgrößen verwenden; Varianten mit `buy_fresh_underway` nur für ihre Haltbarkeit einkaufen, Rest als "unterwegs frisch nachkaufen" ausweisen
- Gruppen mit `mode=check` erzeugen Prüflisten (vorhanden / fehlt / nachkaufen) statt Mengen
- Wendet an: Crew-Fragen aus `crew_questions` (Appetit-Aufschlag auf `eat`, Trinkfaktor auf `drink`, Nicht-Trinker zählen 0, Reserve nur auf Varianten mit Haltbarkeit ab 14 Tagen); optionale Einstufung pro Person ersetzt für diese Person die Crew-Einstellung; Kinderfaktor; `applies_to`
- Wochenmengen anteilig auf die Törnlänge, `per_crew_week` mit angefangener Woche voll, Ergebnis sinnvoll gerundet
- Überschriebene Mengen werden nie neu berechnet; "zurücksetzen" setzt die Überschreibung auf leer
- Warnung, wenn frische Mengen der ersten 3 Tage die Kühlkapazität grob übersteigen

**Abnahme:** Unit-Tests mit festen Beispielen (z. B. 5 Erwachsene, davon 1 vegetarisch und 1 ohne Alkohol, 7 Tage, Mittelmeer, 4 Bordabende); Tests für jede Rechenbasis, für Profile und für Überschreibungen, die eine Crewänderung überleben.

### S3 – Törn anlegen

Formular in wenigen Schritten: Name und Datum, Charter oder eigenes Boot, Revier, Boot und Kühlkapazität, Abende an Bord, Crew mit Erwachsener/Kind und vegetarisch; dann die Crew-Fragen "Wie isst eure Crew?", "Reserve für Ankertage", "Wie viel wird getrunken?" und "Wer trinkt keinen Alkohol?". Einstufung pro Person optional unter "Details".

**Abnahme:** Ein Törn mit 5 Personen lässt sich in unter 2 Minuten anlegen und bearbeiten; Profile haben sinnvolle Standardwerte (normal).

### S4 – Vorratsliste und Einlagerungs-Checkliste

- Vorratsliste gruppiert nach Supermarkt-Abteilung, alternativ nach Kategorie
- Jede Variante zeigt Packungen (z. B. "3 × 500 g") und klein darunter Bedarf und Reserve; +/− ändert die Packungszahl (= Überschreibung, markiert, "zurücksetzen"); Packungsgröße per Tipp änderbar und gemerkt; abwählen, eigene Positionen hinzufügen
- Gruppen mit `visibility=owner` beim Charter eingeklappt, beim eigenen Boot sichtbar
- Varianten innerhalb einer Gruppe an- und abwählen, Anteile optional einstellen
- Bereich "unterwegs frisch nachkaufen" für kurz haltbare Varianten
- Abhaken beim Einkauf; danach Modus "Einlagerung" mit den Hinweisen aus `storage_hints`, im Revier `hot_or_remote` standardmäßig aktiv
- Hinweis, dass Ernährungs-Tags kein Allergieschutz sind

**Abnahme:** Liste funktioniert komplett offline; Überschreibungen, Abwahlen und Häkchen bleiben nach Neustart und nach Crewänderung erhalten.

### S5 – Bordkasse und Kostenteilung

- Zwei Modelle: gemeinsame Bordkasse (Standard: Einzahlungen, Ausgaben aus der Kasse, Restverteilung oder Nachschuss) und Einzelabrechnung ("wer schuldet wem" mit möglichst wenigen Überweisungen)
- Ausgabe: Betrag, Währung, Kategorie (Proviant, Getränke, Hafen und Liegeplatz, Diesel, Charter und Kaution, Restaurant, Sonstiges), bezahlt von bzw. aus der Kasse, optional abweichende Aufteilung
- Beteiligung pro Person und Kategorie; Schnellauswahl "Skipper frei" (ganz frei oder nur Charter, Hafen, Diesel); Anteile Nichtbeteiligter werden auf die übrigen verteilt
- Zahlungen nur anstoßen: EPC-QR-Code (GiroCode) aus IBAN, Name, Betrag und Verwendungszweck; PayPal- und Revolut-Links; IBAN und Links nur lokal, Teilen nur auf Wunsch
- Keine Zahlungsabwicklung in der App
- Mehrere Währungen nur im Probetörn und in Pro (siehe S6), mit Abrechnungswährung pro Törn

**Abnahme:** Unit-Tests für beide Modelle, für Beteiligung pro Kategorie und "Skipper frei", ungleiche Aufteilung und Rundung auf Cent; Summe aller Salden ist immer 0; der erzeugte EPC-QR-Code wird von mindestens einer gängigen Banking-App korrekt gelesen.

### S6 – Freischaltungslogik

Reine Dart-Logik `Entitlements`: Probetörn (erster Törn, alles frei), Mitglied (HullQ-Login, unbegrenzte Törns, Funktionen laut PRD-Tabelle), Pro (Abo, Mock bis v1.1).

**Abnahme:** Unit-Tests decken jede Zeile der Funktionstabelle im PRD ab; der zweite Törn zeigt den Freischalten-Dialog; das Modell erlaubt später eine zeitlich begrenzte Freischaltung pro Törn (Törn-Code, v1.1), ohne Umbau.

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
