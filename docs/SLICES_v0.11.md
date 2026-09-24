# Proviantplaner – Umsetzungsplan in Slices v0.11

Stand: 23.09.2026 · Grundlage: `docs/PRD_v0.16.md`, `docs/KATALOG_v0.7.md`

Jeder Slice ist eine abgeschlossene Arbeitseinheit für eine Gemini-Sitzung: klein genug für eine Standzeit, mit klaren Abnahmekriterien. Ein Slice gilt erst als fertig, wenn alle Kriterien erfüllt sind und die Tests grün laufen.

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 11 Slices für v1 auf Basis PRD v0.7 |
| v0.2 | 23.09.2026 | Angepasst an PRD v0.8: Vorratsliste statt Menüplan als Kern, Konsumprofile, Überschreiben von Mengen, Einlagerungs-Checkliste, Charter oder eigenes Boot; Menüplan nach v1.1 |
| v0.3 | 23.09.2026 | S1, S2, S4 auf Katalog v0.4 umgestellt (Bedarfsgruppen, Varianten, split equal/each, Portionen, Sichtbarkeit, Prüflisten-Modus, frisch nachkaufen) |
| v0.4 | 23.09.2026 | Crew-Fragen statt Pflicht-Einstufung pro Person, Reserve-Schalter, Packungsanzeige mit +/−, intelligentes Runden und Gruppenausgleich, gemerkte Packungsgrößen |
| v0.5 | 23.09.2026 | S5 Bordkasse erweitert: zwei Kassenmodelle, Kategorien, Beteiligung pro Person und Kategorie, Skipper frei, EPC-QR und Zahlungslinks |
| v0.6 | 23.09.2026 | Törnverlauf (Tage mit Mittags-/Abends-Restaurant, optional Tagestyp und Hafenname), Einkaufsstopps mit manueller Zuordnung, Phasen und Navigation in S1, S3, S4 ergänzt; Katalog v0.5 |
| v0.7 | 23.09.2026 | Auf Katalog v0.6 umgestellt; Hinweis: Mengen vorläufig, UI vorläufig bis Mockups; S2 bis S6 freigegeben |
| v0.8 | 23.09.2026 | S0: Abnahme nur auf Android-Emulator, Paket-ID festgelegt |
| v0.9 | 24.09.2026 | Neuer Korrektur-Slice S2a nach Review (docs/impl/REVIEW_S2_v0.1.md); Katalog v0.7, Quantities v0.4; S2/S4: keine automatische Verteilung von Frischem |
| v0.10 | 25.09.2026 | Design: Mockups und Design-Brief v0.2 verbindlich für alle UI-Slices; neuer Slice S-UI zur Angleichung bereits gebauter Oberflächen |
| v0.11 | 25.09.2026 | S-UI um dritten Farbmodus "Nachtwache" (Rot auf Schwarz) erweitert; Design-Brief v0.3 |
| v0.4.1 | 23.09.2026 | Verweis auf PRD v0.11; Hinweis: Törn-Code und Bestellung an die Basis sind v1.1 und nicht Teil dieser Slices. Vorbereitung in S6: Freischaltung so bauen, dass später eine zeitlich begrenzte Freischaltung per Code ergänzt werden kann |

## Technische Leitplanken (für alle Slices)

- **Design:** Für jede Oberfläche gelten `docs/design/DESIGN_BRIEF_v0.3.md` (verbindliche Designregeln 1–13 und Hinweise je Bildschirm) und die Mockups in `docs/design/mockups/`; Theme aus `technical_maritime_m3/DESIGN.md`, hell und dunkel

- **Vorläufigkeit:** Mengen sind Platzhalter bis zur Baseline, die Oberfläche ist vorläufig bis zu den Mockups in `docs/design/mockups/`. Deshalb: alle Werte aus den JSON-Dateien lesen, Farben, Abstände und Schriften zentral im Theme halten, Widgets klein und austauschbar bauen

- Navigation: vier Reiter unten (Liste, Törn, Bordkasse, Mehr); die App öffnet die zur Phase passende Ansicht, sperrt aber nie andere Bereiche

- Flutter stable, Dart mit null safety, nur iOS und Android
- State-Management: Riverpod
- Lokale Datenbank: drift (SQLite)
- Navigation: go_router
- Übersetzung: flutter_localizations + intl mit ARB-Dateien
- Sichere Token-Ablage: flutter_secure_storage
- Offline zuerst: Keine Funktion außer Login, Sicherung und Konto löschen darf Netz voraussetzen
- HullQ-Anbindung nur über ein Interface (`HullqAuthService`, `HullqBackupService`) mit Mock-Implementierung, bis die echte API steht
- Keine Bootsinhalte, keine Push-Nachrichten, keine Werbung in der App
- Katalog und Mengen nur aus `data/catalog_v0.7.json` und `data/quantities_v0.4.json` lesen, nie hart codieren
- Rechenlogik (Mengen, Bordkasse, Freischaltung) als reines Dart ohne Flutter-Abhängigkeit, mit Unit-Tests

## Slices

| Nr | Slice | Tag laut PRD |
| --- | --- | --- |
| S0 | Projekt-Setup und Architektur | 1 |
| S1 | Datenmodell und lokale Datenbank | 1 |
| S2 | Mengen-Engine mit Katalog und Konsumprofilen | 2 |
| S2a | Korrektur Mengen-Engine (Vorrang) | – |
| S-UI | Angleichung an Design-System (nach S2a) | – |
| S3 | Törn anlegen und Törnverlauf | 1–2 |
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

**Abnahme:** App startet auf dem Android-Emulator (iOS erst später über Cloud-Build); `flutter analyze` ohne Fehler; `flutter test` läuft. Paket-ID `com.hullq.proviantplaner` für Android und iOS (nach der ersten Veröffentlichung nicht mehr änderbar).

### S1 – Datenmodell und lokale Datenbank

Entitäten:

- `Trip`: Name, Start, Anzahl Tage, Revier, Charter oder eigenes Boot, Bootstyp Mono/Kat, Kühlkapazität, Crew-Fragen (Appetit, Reserve, Trinken), Einlagerungs-Checkliste an/aus, aktuelle Phase (planen, einkaufen, einlagern, unterwegs, abschluss), archiviert
- `TripDay`: Tag-Nr., Mittags Restaurant, Abends Restaurant, optional Tagestyp (marina, hafen, ankerbucht, ueberfahrt) und Hafenname (reine Info, keine Rechenlogik)
- `CrewMember`: Name, Erwachsener/Kind, vegetarisch, trinkt keinen Alkohol, optionale Einstufung Essen/Trinken, Beteiligung pro Ausgabenkategorie, Skipper frei
- `ShoppingStop`: Tag-Nr., Name (z. B. "Supermarkt Hvar"); der erste Stopp wird automatisch angelegt
- `ListItem`: Gruppen- oder Varianten-ID aus dem Katalog oder eigene Position, gewählt, Anteil, berechnete Menge, überschriebene Packungszahl oder leer, gemerkte Packungsgröße
- `ListItemAllocation`: Zuordnung von Teilmengen eines `ListItem` zu einem `ShoppingStop`; nicht zugeordnete Mengen gehören zum ersten Stopp; je Zuordnung gekauft und eingelagert
- `Expense`: Betrag, Währung, Kategorie, bezahlt von oder aus der Kasse, Aufteilung
- `KittyPayment`: Einzahlung in die gemeinsame Bordkasse

**Abnahme:** CRUD für alle Entitäten mit drift; Migrationstest; Daten überleben App-Neustart; die Summe der Zuordnungen eines ListItem kann die Gesamtmenge nicht überschreiten.

### S2 – Mengen-Engine mit Katalog und Konsumprofilen

- Liest `data/catalog_v0.7.json` und `data/quantities_v0.4.json` als Assets
- Berechnet den Bedarf pro Bedarfsgruppe nach Rechenbasis (`per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`)
- `split=equal`: Gruppenbedarf auf die gewählten Varianten verteilen (gleichmäßig oder nach Anteil); `split=each`: jede gewählte Variante mit eigenem `need`, sonst Gruppenbedarf je Variante; Portionen über `portion`
- In Packungen umrechnen nach `rounding` (haltbar immer aufrunden, frisch nur bis 25 % Überschuss, sonst abrunden mit Rest-Hinweis; Gruppenausgleich), vom Nutzer geänderte Packungsgrößen verwenden; KEINE automatische Verteilung von Frischem auf spätere Einkäufe, Haltbarkeit nur als Hinweis
- Gruppen mit `mode=check` erzeugen Prüflisten (vorhanden / fehlt / nachkaufen) statt Mengen
- Bordmahlzeiten aus `TripDay`: `per_person_board_lunch` zählt Tage ohne Mittags-Restaurant, `per_person_board_evening` Tage ohne Abends-Restaurant
- Wendet an: Crew-Fragen aus `crew_questions` (Appetit-Aufschlag auf `eat`, Trinkfaktor auf `drink`, Nicht-Trinker zählen 0, Reserve nur auf Varianten mit Haltbarkeit ab 14 Tagen); optionale Einstufung pro Person ersetzt für diese Person die Crew-Einstellung; Kinderfaktor; `applies_to`
- Wochenmengen anteilig auf die Törnlänge, `per_crew_week` mit angefangener Woche voll, Ergebnis sinnvoll gerundet
- Überschriebene Mengen werden nie neu berechnet; "zurücksetzen" setzt die Überschreibung auf leer
- Warnung, wenn frische Mengen der ersten 3 Tage die Kühlkapazität grob übersteigen

**Abnahme:** Unit-Tests mit festen Beispielen (z. B. 5 Erwachsene, davon 1 vegetarisch und 1 ohne Alkohol, 7 Tage, Mittelmeer, 4 Bordabende); Tests für jede Rechenbasis, für Profile und für Überschreibungen, die eine Crewänderung überleben.

### S2a – Korrektur Mengen-Engine (Vorrang)

Grundlage: `docs/impl/REVIEW_S2_v0.1.md`. Alle Befunde 1–6 beheben und die dort genannten Tests ergänzen.

- `applies_to` exakt mit `all`, `non_vegetarian`, `vegetarian`, `adults`; unbekannter Wert wirft einen Fehler
- Einheiten: g/kg und ml/l umrechnen; Bedarf in `Packung` = Packungszahl; inkompatible Einheiten = Fehler (nie stillschweigend rechnen)
- Gruppenausgleich nach `quantities_v0.4.json` → `rounding.group_balancing`
- Keine automatische Aufteilung von Frischem; beim Abrunden nur Rest-Hinweis im Ergebnis
- Urlaubszuschlag auf die Gruppen aus `factors.holiday_snack_drink_uplift.applies_to_groups`
- Wasser generisch über `per_person_day_region`
- Engine an die Programmierregeln aus GEMINI.md v0.4 angleichen: feste Typen beim Laden, lange Hauptfunktion zerlegen, doppelte Ergebnis-Konstruktion zusammenführen, Eingabeobjekt statt langer Parameterliste, Toleranz beim Runden, keine harten IDs/Abteilungen (Kühlschätzung über Daten oder als Vorschlag melden)

**Abnahme:** Katalog-Validierungstest über alle Varianten grün; Tests für Vegetarier, Packungszahlen (Bier, Wein, Spülmittel, Duschgel, Konserven, Brot, Spaghetti/Reis), Gruppenausgleich und Urlaubszuschlag grün; bestehende Tests nur angepasst, wo sie das alte Fehlverhalten festschrieben (im Bericht begründen). Falls S4 bereits umgesetzt ist: dortige Anzeige der automatischen "unterwegs"-Mengen entfernen.

### S-UI – Angleichung an Design-System (nach S2a)

- Zentrales Flutter-Theme (hell und dunkel) aus `docs/design/mockups/technical_maritime_m3/DESIGN.md`: Farben, IBM Plex Sans und JetBrains Mono (nur Zahlen/Etiketten), Radien, Abstände
- Bereits gebaute Oberflächen (S0, S3 und ggf. weitere) an Design-Brief v0.2 und Mockups angleichen
- Schriften lokal als Assets einbinden (offline zuerst), nicht per Download zur Laufzeit
- Dritter Farbmodus "Nachtwache" (Rot auf Schwarz) nach Designregel 13: manuell wählbar in den Einstellungen und per Schnellzugriff im Menü "Mehr", Auswahl lokal gespeichert

**Abnahme:** Theme zentral, keine Farb- oder Schriftwerte in Widgets; Designregeln 1–13 im Bericht einzeln geprüft; Widget-Tests für hell, dunkel und Nachtwache der angeglichenen Bildschirme; im Nachtwache-Modus keine Farbe außerhalb der Rot-/Schwarzpalette; Mindestgrößen (14 sp, 12 sp, 48 dp) eingehalten.

### S3 – Törn anlegen und Törnverlauf

- Formular in wenigen Schritten: Name und Datum, Anzahl Tage, Charter oder eigenes Boot, Revier, Boot und Kühlkapazität, Crew (Erwachsener/Kind, vegetarisch, trinkt keinen Alkohol), Crew-Fragen; Einstufung pro Person optional unter "Details"
- Tagesleiste: pro Tag Schalter Mittags und Abends Restaurant; optional Tagestyp und Hafenname
- Einkaufsstopps anlegen, umbenennen, löschen (der erste Stopp bleibt)

**Abnahme:** Ein Törn mit 5 Personen lässt sich in unter 2 Minuten anlegen; die Tagesleiste ist ohne Pflichtangaben nutzbar; Änderungen an Restaurant-Schaltern ändern die berechneten Mengen sofort (außer überschriebene).

### S4 – Vorratsliste und Einlagerungs-Checkliste

- Vorratsliste gruppiert nach Supermarkt-Abteilung, alternativ nach Kategorie; Gesamtbedarf und pro Einkaufsstopp eine eigene abhakbare Liste
- Positionen oder Teilmengen per Tipp einem Stopp zuordnen (z. B. 2 von 5 Baguettes auf Tag 4); Haltbarkeit an jeder Variante sichtbar, keine automatische Verteilung
- Jede Variante zeigt Packungen (z. B. "3 × 500 g") und klein darunter Bedarf und Reserve; +/− ändert die Packungszahl (= Überschreibung, markiert, "zurücksetzen"); Packungsgröße per Tipp änderbar und gemerkt; abwählen, eigene Positionen hinzufügen
- Gruppen mit `visibility=owner` beim Charter eingeklappt, beim eigenen Boot sichtbar
- Varianten innerhalb einer Gruppe an- und abwählen, Anteile optional einstellen
- Haltbarkeit als Hinweis an der Variante (z. B. "hält 1 Tag"); keine automatische "unterwegs"-Liste
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
