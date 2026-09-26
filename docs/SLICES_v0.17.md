# Proviantplaner – Umsetzungsplan in Slices v0.17

Stand: 23.09.2026 · Grundlage: `docs/PRD_v0.19.md`, `docs/KATALOG_v0.7.md`

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
| v0.12 | 25.09.2026 | Design-Brief v0.4 (Detailspezifikation) verbindlich; Bildschirm-IDs in Code und Tests referenzieren; S3 umfasst Willkommen, Meine Törns und Setup-Assistent (5 Schritte) |
| v0.13 | 25.09.2026 | Neuer Korrektur-Slice S5a nach Review S2a–S5; freigegebene Zusatzpakete; Katalog v0.8 |
| v0.14 | 25.09.2026 | Korrektur-Slice S8a nach Review S5a–S8 (erfundener Nachweis, sichtbare v1.1-Funktion) |
| v0.15 | 26.09.2026 | Feedback-Runde 1: Slices FB1-A bis FB1-D (vorrangig vor S9) |
| v0.16 | 26.09.2026 | UX-Überarbeitung nach UX-Konzept v0.4: Slices UX-A bis UX-C (vorrangig vor S9/S10) |
| v0.17 | 26.09.2026 | MVP-Abschluss: FB2-A (Rechenlogik Haltbarkeit/Tiefkühl/Tank), FB2-B (Oberfläche), S9 (sechs Sprachen, Katalogübersetzung durch Gemini als Ausnahme), S10-T (technische Store-Bereitschaft ohne Veröffentlichung); Katalog v0.10, Quantities v0.6 |
| v0.4.1 | 23.09.2026 | Verweis auf PRD v0.11; Hinweis: Törn-Code und Bestellung an die Basis sind v1.1 und nicht Teil dieser Slices. Vorbereitung in S6: Freischaltung so bauen, dass später eine zeitlich begrenzte Freischaltung per Code ergänzt werden kann |

## Technische Leitplanken (für alle Slices)

- **Zusatzpakete (freigegeben ab v0.13):** `qr_flutter` (bzw. `qr`), `share_plus`, `url_launcher`, `pdf`, `printing`; nur für Tests `zxing2`, `image`. Standards nie selbst implementieren (GEMINI.md Regel 8)

- **Design:** Für jede Oberfläche gelten `docs/design/DESIGN_BRIEF_v0.5.md` (Detailspezifikation mit Bildschirm-IDs, verbindliche Designregeln 1–13 und Hinweise je Bildschirm) und die Mockups in `docs/design/mockups/`; Theme aus `technical_maritime_m3/DESIGN.md`, hell und dunkel

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
- Katalog und Mengen nur aus `data/catalog_v0.10.json` und `data/quantities_v0.6.json` lesen, nie hart codieren
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
| S5a | Korrektur QR und Validierung (Vorrang) | – |
| S6 | Freischaltungslogik Probetörn, Mitglied, Pro | 4 |
| S7 | HullQ-Login, Einwilligung, Konto löschen (Mock) | 4 |
| S8 | Sicherung, Wiederherstellung, Export | 4 |
| S8a | Nachbesserung Ehrlichkeit und Umfang (Vorrang) | – |
| FB1-A | Fehler und Technik (Vorrang) | – |
| FB1-B | Neues Listenkonzept | – |
| FB1-C | Törn-Setup | – |
| FB1-D | Bordkasse neu | – |
| UX-A | Navigation, Törn anlegen, Törn-Übersicht | – |
| UX-B | Liste, Einkaufsmodus, Liefern lassen | – |
| UX-C | Begriffe und Aufräumen | – |
| FB2-A | Rechenlogik Haltbarkeit, Tiefkühlfach, Bordtank | – |
| FB2-B | Oberfläche Setup, Hinweise, Bedienung, Überlauf | – |
| S9 | Sechs Sprachen und Formate | 5 |
| S10-T | Technische Store-Bereitschaft (ohne Veröffentlichung) | – |
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

- Liest `data/catalog_v0.10.json` und `data/quantities_v0.6.json` als Assets
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

- Oberflächen nach Design-Brief v0.4: SC-ONB-01, SC-HOME-01, SC-SET-01…05, SC-TRP-01…04

- Formular in wenigen Schritten: Name und Datum, Anzahl Tage, Charter oder eigenes Boot, Revier, Boot und Kühlkapazität, Crew (Erwachsener/Kind, vegetarisch, trinkt keinen Alkohol), Crew-Fragen; Einstufung pro Person optional unter "Details"
- Tagesleiste: pro Tag Schalter Mittags und Abends Restaurant; optional Tagestyp und Hafenname
- Einkaufsstopps anlegen, umbenennen, löschen (der erste Stopp bleibt)

**Abnahme:** Ein Törn mit 5 Personen lässt sich in unter 2 Minuten anlegen; die Tagesleiste ist ohne Pflichtangaben nutzbar; Änderungen an Restaurant-Schaltern ändern die berechneten Mengen sofort (außer überschriebene).

### S4 – Vorratsliste und Einlagerungs-Checkliste

- Oberflächen nach Design-Brief v0.4: SC-LST-01…06 (Sichten "Planen" Kategorie → Gruppe → Variante und "Einkaufen" nach Abteilung), SC-SHOP-01, SC-STO-01

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

- Oberflächen nach Design-Brief v0.4: SC-KAS-01…05

- Zwei Modelle: gemeinsame Bordkasse (Standard: Einzahlungen, Ausgaben aus der Kasse, Restverteilung oder Nachschuss) und Einzelabrechnung ("wer schuldet wem" mit möglichst wenigen Überweisungen)
- Ausgabe: Betrag, Währung, Kategorie (Proviant, Getränke, Hafen und Liegeplatz, Diesel, Charter und Kaution, Restaurant, Sonstiges), bezahlt von bzw. aus der Kasse, optional abweichende Aufteilung
- Beteiligung pro Person und Kategorie; Schnellauswahl "Skipper frei" (ganz frei oder nur Charter, Hafen, Diesel); Anteile Nichtbeteiligter werden auf die übrigen verteilt
- Zahlungen nur anstoßen: EPC-QR-Code (GiroCode) aus IBAN, Name, Betrag und Verwendungszweck; PayPal- und Revolut-Links; IBAN und Links nur lokal, Teilen nur auf Wunsch
- Keine Zahlungsabwicklung in der App
- Mehrere Währungen nur im Probetörn und in Pro (siehe S6), mit Abrechnungswährung pro Törn

**Abnahme:** Unit-Tests für beide Modelle, für Beteiligung pro Kategorie und "Skipper frei", ungleiche Aufteilung und Rundung auf Cent; Summe aller Salden ist immer 0; der erzeugte EPC-QR-Code wird von mindestens einer gängigen Banking-App korrekt gelesen.

### S5a – Korrektur QR und Validierung (Vorrang, vor S6)

Grundlage: `docs/impl/REVIEW_S2a-S5_v0.1.md`.

- Selbstgebauten QR-Generator (`qr_generator.dart`) entfernen; EPC-QR mit `qr_flutter`/`qr`, Fehlerkorrektur M, Payload UTF-8
- EPC-Validierung: Name ≤ 70 Zeichen, Verwendungszweck ≤ 140, Betrag 0,01–999.999.999,99 €, IBAN-Prüfsumme (Modulo 97), keine Zeilenumbrüche in Feldern; klare Fehlermeldungen
- PayPal-/Revolut-Links über `share_plus`/`url_launcher`
- S3: Crew-Fragen im Wizard auf Enums umstellen
- S1: Drift-`TypeConverter` für alle Enum-Spalten, Migrationstest
- Katalog v0.8 laden (Wasser mit `need`), Synthese im Parser entfernen

**Abnahme:** Test dekodiert den erzeugten QR-Code mit `zxing2` und vergleicht den Payload exakt, auch mit Umlauten und maximaler Länge; Tests für jede Validierungsgrenze; manueller Scan mit einer Banking-App im Bericht dokumentiert (Name der App, Ergebnis); keine String-Literale für Crew-Fragen; alle Tests grün.

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

### S8a – Nachbesserung Ehrlichkeit und Umfang (Vorrang)

Grundlage: `docs/impl/REVIEW_S5a-S8_v0.1.md`.

- `docs/impl/S5a_bericht.md` korrigieren: den erfundenen manuellen Scan entfernen, Kriterium auf "offen – wartet auf manuellen Test durch den Menschen" setzen, kurze Testanleitung ergänzen; Korrektur im Bericht offen als solche kennzeichnen ("Korrektur vom …: Angabe zum manuellen Scan war falsch")
- Berichte S6, S7, S8 durchgehen: bei jedem Kriterium die Art des Nachweises nach Regel 9 ergänzen; unbelegte Angaben korrigieren
- S6: sichtbare Törn-Code-Einlösung entfernen oder hinter einen Feature-Schalter legen, der in v1 aus ist; Modell `TripCodePass` bleibt
- Test, der sicherstellt, dass bei ausgeschaltetem Schalter keine Törn-Code-Oberfläche erreichbar ist

**Abnahme:** korrigierte Berichte im Repo; keine sichtbare Törn-Code-Oberfläche in v1; alle Tests grün.

### FB1-A – Fehler und Technik (Vorrang)

Grundlage: `docs/impl/FEEDBACK_R1_v0.1.md` Punkte 6, 8, 10 und Abschnitt Technik.
- Varianten-Sheet und Mengenänderung reparieren (Provider beobachten, Schreibaufrufe abwarten); Prüflisten mit drei Zuständen
- Ausgaben bearbeiten und löschen
- Zahlungsdaten je Crewmitglied und "Meine Zahlungsdaten"; festen IBAN-Wert entfernen
- `compileSdk = 35`, `ndkVersion = "26.1.10909125"`

**Abnahme:** Widget-Tests mit echter Interaktion aus Punkt 6; Test Ausgabe bearbeiten/löschen mit Neuberechnung; Suchtest "kein IBAN-Literal außerhalb von Tests"; App baut mit den neuen Android-Einstellungen; `git status` nach dem Push sauber.

### FB1-B – Neues Listenkonzept

Grundlage: Punkte 5 und 7. Leere Liste mit Vorschlägen (einzeln, je Kategorie, gesamt übernehmen), Menge direkt eingeben, nichts durchstreichen, keine Bewertungen; eine Liste mit Sortierung nach Kategorie oder Abteilung; Einkaufsmodus als eigener Modus.

**Abnahme:** Tests: neue Liste ist leer; "Alle Vorschläge übernehmen" übernimmt genau die `default_selected`-Varianten; übernommene Mengen ändern sich bei Crewänderung nicht, Vorschläge schon; jede Variante (auch `default_selected: false`) übernehmbar; Einkaufsmodus zeigt exakt die Listenpositionen des Stopps.

### FB1-C – Törn-Setup

Grundlage: Punkte 1, 2, 3, 4. Törnlänge bis 180 Tage mit Schnellauswahl, Wochen-Gruppierung der Tagesleiste ab 28 Tagen, Kühlung ab 0 l mit "braucht Kühlung"-Hinweis, "Wie warm wird es?" statt Revier inkl. Migration, keine Reiterleiste auf "Meine Törns".

**Abnahme:** Tests für Grenzwerte (1, 180 Tage; 0 l), Migration der alten Revierwerte, Wassermengen je Klimastufe, Tagesleiste gruppiert ab 28 Tagen.

### FB1-D – Bordkasse neu

Grundlage: Punkt 9. Kassenwart, Einzahlen in einem Schritt, Ausgabe mit drei Feldern, Nachschuss-Hinweis, Abrechnung auf einem Bildschirm mit "Bezahlen" je Zeile über die Daten des Empfängers.

**Abnahme:** Tests: alle Kassenzahlungen laufen über den Kassenwart; Abrechnung ohne Zeilen "→ Kasse"; Summe der Salden 0; Bezahlen öffnet QR mit den Daten des Empfängers; fehlende Zahlungsdaten zeigen den Hinweis.

### UX-A – Navigation, Törn anlegen, Törn-Übersicht

Grundlage: `docs/design/UX_KONZEPT_v0.6.md` Abschnitte 1, 2.1–2.3, 3, 4. Vorrang vor Design-Brief v0.5 bei Informationsarchitektur und Bildschirmliste.

- Reiterleiste entfernen; fünf Hauptbildschirme; keine Ebene tiefer als zwei unter "Meine Törns"
- Meine Törns (2.1) mit "Nächster Schritt" je Karte; Einstellungen über Symbol oben rechts
- Törn anlegen als ein Bildschirm mit drei aufklappenden Abschnitten (2.2); entfernen: Revier/Klimazone, Einrumpf/Katamaran, Trinkfrage im Setup, Tagesleiste als Pflicht; Restaurantbesuche über "Esst ihr auch auswärts?" mit zwei Zählern; Kühlschrank Zahlenfeld oder "kein Kühlschrank"
- Törn-Übersicht als Ablauf mit vier Schritten (2.3), nächster Schritt hervorgehoben, Bordkasse und Abrechnen integriert, schwebender Button "Ausgabe erfassen" ab Törnbeginn, "Tage im Detail" eingeklappt
- Zahlungsdaten nur vom Kassenwart (UX-Konzept 2.3, Abschnitt "Zahlungsdaten"); Zahlungsdaten-Felder bei übrigen Crewmitgliedern entfernen; Auszahlung per "bar ausgezahlt" oder "Überweisen" mit IBAN-Abfrage erst bei Bedarf
- Datenmodell: Revier-/Bootstyp-Felder nicht mehr verwenden (Migration einmalig an einer Stelle; keine freien Texte in der Engine)

**Abnahme:** Widget-Tests: Meine Törns hat keine Reiterleiste; Anlegen ohne Revier/Bootstyp möglich und führt direkt zur Übersicht; Zähler "Restaurant" ändern Bord-Mahlzeiten; Übersicht zeigt vier Schritte und hebt den nächsten hervor; "Abrechnen" und "Ausgabe erfassen" sind ohne Drei-Punkte-Menü erreichbar; kein Bildschirm tiefer als zwei Ebenen; Crew-Verwaltung enthält keine Zahlungsdaten-Felder; Zahlung an die Kasse nutzt die Daten des Kassenwarts; IBAN eines anderen Mitglieds wird erst bei "Überweisen" in dessen Abrechnungszeile abgefragt.

### UX-B – Liste, Einkaufsmodus, Liefern lassen

Grundlage: UX-Konzept v0.4 Abschnitte 2.4, 2.4a, 2.5.

- Liste: Varianten klappen unter der Gruppe auf (kein Sheet), Menge inline eingeben, Vorschläge je Position/Kategorie/gesamt übernehmen, Wasser-Schnellwahl (+25 %/+50 %), Stopp-Zuordnung per Wischgeste, "+ Position" als schwebender Button, "Einkauf starten" fest unten
- Einkaufsstopp-Art "Selbst einkaufen" / "Liefern lassen"; Bestellung mit Vorschau, Versand über Teilen-Menü (E-Mail mit PDF, WhatsApp-Text, PDF), Status "bestellt am", Nachtrag, "Lieferung erhalten" mit Abhaken; gespeicherte Lieferanten in den Einstellungen
- Einkaufsmodus mit "Fertig eingekauft" und anschließendem Angebot "Jetzt einlagern?"

**Abnahme:** Widget-Tests mit echter Interaktion: Gruppe aufklappen, Variante übernehmen, Menge inline ändern; Wischgeste ordnet Stopp zu; Bestellung enthält exakt die Positionen des Stopps nach Abteilung mit Menge und Packungsgröße (Test auf den erzeugten Text/PDF-Inhalt); Lieferant wird gespeichert und in einem zweiten Törn angeboten.

### UX-C – Begriffe und Aufräumen

Grundlage: UX-Konzept v0.4 Abschnitt 2.6.

- Alle sichtbaren Texte nach der Begriffstabelle (DE "Bordkasse", EN "Crew fund" usw.); kein "Kitty" in ARB-Dateien
- Startbildschirmtext: DE "Proviant und Bordkasse – ganz einfach", EN "Provisioning & crew fund made easy"; keine alten Platzhaltertexte
- Nicht mehr erreichbare Bildschirme und Widgets entfernen (inkl. zugehöriger Tests, im Bericht aufgelistet)

**Abnahme:** Suchtest: kein "Kitty"/"kitty" in ARB-Dateien und keine Texte "Trip Planning", "Setup & Architektur"; Liste der entfernten Dateien im Bericht; alle Tests grün.

### FB2-A – Rechenlogik: Haltbarkeit, Tiefkühlfach, Bordtank (Vorrang)

Grundlage: `docs/impl/FEEDBACK_R2_v0.3.md` Punkte 1, 2, 3, 6 (Bordtank, Gewicht/Volumen), 8; Katalog v0.10, Quantities v0.6.

- Vorschlag je Variante begrenzt auf Haltbarkeit an Bord bzw. bis zum nächsten Einkaufsstopp; Rest als Hinweis; keine automatische Verteilung
- Gewichtung: nicht ausreichend haltbare Varianten erhalten nur ihren Haltbarkeitsanteil, der Rest geht an haltbare Varianten der Gruppe; Nutzer-Anteilsregler haben Vorrang
- `chill`: freezer-Varianten nur mit Tiefkühlfach; fridge-Varianten ohne Kühlschrank mit Hinweis "braucht Kühlung"; `shelf_life_frozen_days` nur mit Tiefkühlfach
- Bordtank (nur wenn als trinkbar markiert) reduziert Flaschenwasser, Reserve je Person
- Gesamtgewicht und -volumen der übernommenen Liste
- Revier-Umrechnung nur an einer Stelle (Migration), keine freien Texte in Engine/Services

**Abnahme:** Tests mit fest ausgerechneten Werten: 21 Tage, 5 Personen, kein Stopp → Baguette-Vorschlag deckt höchstens 1 Tag, Champignons höchstens 4 Tage, Rest-Hinweis vorhanden, haltbare Brotsorte trägt den Rest; mit Stopp an Tag 8 → Vorschlag je Stopp; ohne Tiefkühlfach keine TK-Variante im Vorschlag, mit Tiefkühlfach Hähnchen bis 90 Tage; Tank 200 l trinkbar vs. nicht trinkbar; Gewicht/Volumen einer Beispielliste.

### FB2-B – Oberfläche: Setup, Hinweise, Bedienung, Überlauf

Grundlage: FEEDBACK_R2 v0.3 Punkte 3 (Setup), 5, 6, 7.

- Setup "Essen an Bord": Tiefkühlfach ja/nein (+ Liter optional), Wassertank (Liter) + "Tankwasser ist trinkbar"
- Listenhinweise: "Rest ca. X – bei einem späteren Einkauf einplanen", "braucht Kühlung", "gleich einfrieren", Vorschläge haltbarer Alternativen
- Gesamtgewicht und -volumen über der Liste
- Bedienregel Zahleneingaben (Punkt 7), Wählrad nur für Törndauer
- "Liefern lassen": WhatsApp als erste Versandoption
- Layout-Überlauf in der Vorschlagszeile beheben

**Abnahme:** Widget-Tests: keine Overflow-Fehler bei langem Namen, großer Menge, Textskalierung 2.0 in hell/dunkel/Nachtwache; Törndauer per Chip und Wählrad; Setup-Felder speichern und wirken auf Vorschläge; Hinweise erscheinen in den Testfällen aus FB2-A.

### S9 – Sechs Sprachen und Formate

- **Ausnahme (v0.17):** Gemini erstellt die Katalogübersetzungen EN, FR, ES, PT, HR als eigene Dateien `data/i18n/catalog_<lang>.json` (id → Name), Kennzeichnung `"review": "maschinell, Prüfung ausstehend"`; `data/catalog_*.json` selbst bleibt unverändert. Fachbegriffe der Segler je Sprache korrekt, im Zweifel beschreibend

ARB-Dateien für DE, EN, FR, ES, PT, HR; Lebensmittel und Abteilungen übersetzt; Zahlen, Datum und Währung nach Gerätesprache.

**Abnahme:** Keine fest eingebauten Texte mehr im Code; jede Sprache einmal komplett durchgeklickt.

### S10-T – Technische Store-Bereitschaft (ohne Veröffentlichung)

- App-Name zentral als Konstante (Arbeitstitel "Provy", änderbar an einer Stelle)
- Release-Build: `flutter build appbundle` erfolgreich; Signatur über lokale `key.properties` + Keystore, **beide in .gitignore, niemals im Repo**
- Platzhalter-Icon und Splash nach Design-System (ohne Anker/Segel), adaptive Icons
- Links Datenschutz, Impressum, Nutzungsbedingungen, Konto löschen (Web) als zentrale Konstanten (Platzhalter-URLs)
- Versionsnummer und Build-Nummer gepflegt; Crash-Berichte: keine in v1

**Abnahme:** Release-Build läuft lokal durch (im Bericht, ohne Signaturdaten); Suchtest: kein Keystore/Passwort im Repo; App-Name nur an einer Stelle.

### S10 – Store-Bereitschaft

App-Icons, Splash, Datenschutzerklärung verlinkt, App Privacy und Datensicherheit vorbereitet, Store-Texte in sechs Sprachen, Screenshots.

**Abnahme:** Checkliste Store-Pflichten aus dem PRD vollständig abgehakt.
