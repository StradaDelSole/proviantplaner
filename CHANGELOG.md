# Changelog

## 2026-09-25 – Design-Brief v0.3, Slice-Plan v0.11

- Dritter Farbmodus "Nachtwache" (Rot auf Schwarz) zur Schonung der Nachtsicht, umgesetzt in S-UI

## 2026-09-25 – Design-Brief v0.2, Slice-Plan v0.10

- Review der Stitch-Mockups: 12 verbindliche Designregeln, Hinweise je Bildschirm, Theme aus `technical_maritime_m3/DESIGN.md`
- Neuer Slice S-UI (nach S2a): Theme zentral, bereits gebaute Oberflächen angleichen

## 2026-09-24 – GEMINI.md v0.4

- Gehärtete Programmierregeln (feste Typen, keine versteckten Platzhalter, ehrliche Berichte, datengetrieben, Toleranz bei Kommazahlen, Cent-Beträge, Struktur, Testregeln); erweiterter Abschlussbericht mit Selbstprüfung

## 2026-09-24 – Review S2, Korrektur-Slice S2a

- `docs/impl/REVIEW_S2_v0.1.md`: 2 kritische, 2 hohe, 1 mittlerer, 2 niedrige Befunde
- Katalog v0.7, Quantities v0.4, PRD v0.16, Slice-Plan v0.9 (S2a mit Vorrang)

## 2026-09-24 – S3: Törn anlegen und Törnverlauf

- Mehrschritt-Assistent `TripWizardScreen` zum Anlegen eines Törns implementiert (Schritt 1: Basisdaten & Reisedauer, Schritt 2: Bootstyp, Revier & Kühlkapazität, Schritt 3: Crew-Zusammenstellung mit individuellen Profilen und Crew-Fragen zu Appetit & Alkohol)
- `TripService` mit reaktiver Mengen-Neuberechnung bei Änderungen an Restaurant-Schaltern oder Crew
- Tagesleiste `TripTimelineScreen` mit Schaltern für Mittag- und Abendessen (Bordküche vs. Restaurant)
- Reine Info-Felder für Hafenname und Tagestyp ohne Pflichtangaben
- CRUD für Einkaufsstopps (Hinzufügen, Umbenennen, Löschen) mit automatischem Löschschutz für den ersten Einkaufsstopp ("Ersteinkauf Basis")
- Reaktive Kennzahlenkarte zur Törn-Bilanz (Bord-Abendessen, Bord-Mittagessen, Restaurantbesuche)
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` alle 37 Tests grün

## 2026-09-24 – S2: Mengen-Engine mit Katalog und Konsumprofilen

- Reine Dart-Rechen-Engine `QuantityEngine` ohne Flutter-Abhängigkeit implementiert
- Alle 10 Rechenbasen umgesetzt: `per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_person_board_lunch`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`
- Konsumprofile und Crew-Fragen integriert (Appetit-Aufschlag, Trinklevel, Nicht-Trinker, Kinderfaktor 0.6) inklusive Vorrang personenspezifischer Details vor Crew-Einstellungen
- Dynamische Revier-Wasserbedarfe aus `quantities_v0.3.json` (gemäßigt 2,0 l, Mittelmeer 2,5 l, heiß/abgelegen 3,5 l)
- Aufteilung: `split=equal` (anteilig oder gleichmäßig, mit Portionsunterstützung und Gruppenausgleich) sowie `split=each`
- Rundungslogik für Packungen: haltbare Artikel immer aufrunden (ceil), frische Artikel nur bei Überschuss <= 25 % aufrunden, sonst abrunden und Rest als Nachkauf unterwegs
- Reserve-Zuschlag (+10 %) gezielt nur auf haltbare Produkte (Haltbarkeit >= 14 Tage) angewendet
- Persistenz von Mengenangaben: Vom Nutzer überschriebene Packungszahlen bleiben bei Änderungen an Crew oder Reisedauer unangetastet
- Automatische Berechnung des Kühlraum-Bedarfs für die ersten 3 Tage mit Warnung bei Überschreitung der Kühlkapazität
- `CatalogRepository` zum Laden und Parsen von `catalog_v0.6.json` und `quantities_v0.3.json`
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` alle 31 Tests grün inkl. festem PRD-Referenzszenario (5 Erwachsene, 1 veg, 1 kein Alk, 7 Tage, Mittelmeer, 4 Bordabende)

## 2026-09-24 – S1: Datenmodell und lokale Datenbank

- Alle 8 Entitäten in Drift (SQLite) modelliert: `Trip`, `TripDay`, `CrewMember`, `ShoppingStop`, `ListItem`, `ListItemAllocation`, `Expense`, `KittyPayment`
- Automatische Initialisierung des ersten Einkaufsstopps ("Ersteinkauf Basis") und der `TripDays` (1..daysCount) beim Anlegen eines Törns
- Schutz vor Löschung des initialen Einkaufsstopps
- Strenge Allokationsvalidierung: Die Summe aller zugeordneten Teilmengen eines `ListItem` kann die Gesamtpackungszahl nicht überschreiten (`AllocationExceededException`)
- Ermittlung nicht zugeordneter Restmengen, die standardmäßig dem ersten Stopp zugeordnet sind
- DAOs für Trips, Vorratsliste und Bordkasse implementiert inkl. Riverpod-Provider
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 17/17 Tests grün (CRUD, Schema-Migration, Allokations-Constraint, Persistenz über DB-Neustart)

## 2026-09-24 – S0: Projekt-Setup und Architektur

- Flutter-Projekt im Repo-Root aufgesetzt (`com.hullq.proviantplaner`)
- Technische Leitplanken integriert: Riverpod, GoRouter, Drift, Flutter Secure Storage, Intl/Localizations
- Feature-First Ordnerstruktur angelegt (`lib/core`, `lib/features/<feature>/{data,domain,ui}`, `lib/l10n`)
- Zentrales Theme mit Blueprint Navy, Petrol Akzent und Amber Hinweisen gemäß Design-Brief
- Interfaces und Mock-Implementierungen für `HullqAuthService` und `HullqBackupService`
- Startbildschirm mit App-Name, dezentem "powered by HullQ" und 4 Hauptnavigationsreitern
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 8/8 Tests grün, Android-Debug-APK gebaut und Start im Android-Emulator verifiziert

## 2026-09-23 – GEMINI.md v0.3 (Durchlauf-Modus)

- Gemini arbeitet alle freigegebenen Slices nacheinander ab, committet und pusht nach jedem grünen Slice auf main
- Pläne und Berichte in `docs/impl/`; Review gesammelt am Ende

## 2026-09-23 – Slice-Plan v0.8

- S0: Abnahme nur auf dem Android-Emulator, Paket-ID `com.hullq.proviantplaner`

## 2026-09-23 – GEMINI.md v0.2, Startprompt v0.1

- GEMINI.md: Darf/Darf nicht, Pflichtablauf mit Plan und Freigabe, Stoppregeln, Berichtsformat, kein Commit/Push durch Gemini
- `docs/PROMPT_SESSION_START_v0.1.md`: Startprompt und Folgeprompts

## 2026-09-23 – PRD v0.15, Katalog v0.6, Slice-Plan v0.7, Freigabe S2–S6

- Mengen vorläufig (Zucker gesenkt), Baseline folgt später
- Umsetzung mit Google AI Pro
- S2 bis S6 freigegeben; UI vorläufig bis Mockups, alles datengetrieben und im Theme zentral

## 2026-09-23 – Design-Brief v0.1

- `docs/design/DESIGN_BRIEF_v0.1.md`: Stilrichtung aus HullQ-CI, globaler Stil-Prompt und 9 Bildschirm-Prompts für Stitch, Animationshinweise für Flutter
- Ordner `docs/design/mockups/` für die Entwürfe

## 2026-09-23 – PRD v0.14, Katalog v0.5, Slice-Plan v0.6, Freigabe S1

- Törnverlauf: Mittags-/Abends-Restaurant pro Tag, optional Tagestyp und Hafenname; Einkaufsstopps mit manueller Zuordnung
- Törnablauf in fünf Phasen, Navigation mit vier Reitern
- Katalog v0.5: Rechenbasis pro Mittagessen an Bord
- S1 freigegeben

## 2026-09-23 – PRD v0.13, Freigabe S0

- Android zuerst, iOS später über Cloud-Build; Umsetzung mit Antigravity im lokalen Repo
- Abschnitt "Offen vor dem Start" (10 Punkte), Start kostenlos, Abo mit v1.1
- S0 für Gemini freigegeben; S1 nach Klärung von Törnverlauf und Törnablauf

## 2026-09-23 – PRD v0.12, Slice-Plan v0.5

- Bordkasse und Kostenteilung: gemeinsame Kasse und Einzelabrechnung, Kategorien, Beteiligung pro Person, "Skipper frei"
- Zahlungen nur anstoßen: EPC-QR-Code, PayPal-/Revolut-Links; Splitwise-Export später; keine Zahlungsabwicklung

## 2026-09-23 – PRD v0.11

- B2B-Kanal Charterfirmen: Törn-Code und Bestellung an den Proviantservice der Basis (beides v1.1)
- Slice-Plan: S6 so vorbereiten, dass eine zeitlich begrenzte Freischaltung per Code später ohne Umbau möglich ist

## 2026-09-23 – PRD v0.10, Quantities v0.3, Slice-Plan v0.4

- Liste zeigt Packungen statt Rechenwerte, +/− je Packung, Packungsgröße editierbar und gemerkt
- Intelligentes Runden (haltbar immer auf, frisch nur bis 25 % Überschuss) und Ausgleich innerhalb der Gruppe
- Appetit und Trinken als Crew-Fragen mit Aufschlag, Reserve für Ankertage getrennt, Einstufung pro Person optional

## 2026-09-23 – Katalog v0.4, PRD v0.9, Slice-Plan v0.3

- `docs/KATALOG_v0.4.md`, `data/catalog_v0.4.json`: alle 10 Kategorien im Schema Bedarfsgruppe → Variante (47 Gruppen, 212 Varianten), Technik mit Sichtbarkeit (Alltag auch beim Charter) und Prüflisten-Modus, Bordapotheke als Prüfliste
- `docs/PRD_v0.9.md`, `docs/SLICES_v0.3.md`: auf Katalog v0.4 umgestellt
- Status: noch nicht bereit für S0 (Baseline der Mengen offen)

## 2026-09-23 – Katalog v0.3 (in Arbeit)

- Neues Schema Kategorie → Bedarfsgruppe → Variante mit Packungsgröße und Haltbarkeit
- Kategorie Frühstück vollständig umgestellt; übrige Kategorien folgen
- Hinweis für Gemini: Katalog noch nicht als Bauvorlage verwenden

## 2026-09-23 – PRD v0.8, Katalog v0.2, Slice-Plan v0.2

- `docs/PRD_v0.8.md`: Vorratsliste als Kern, Menüplan optional (v1.1), Konsumprofile Essen/Trinken, Mengen überschreibbar, Einlagerungs-Checkliste, Charter oder eigenes Boot, Scope 6–7 Tage
- `docs/KATALOG_v0.2.md`, `data/catalog_v0.2.json`: Profilzuordnung und Einlagerungs-Hinweise pro Position
- `data/quantities_v0.2.json`: Appetit-Faktor durch Konsumprofile ersetzt, Kinderfaktor
- `docs/SLICES_v0.2.md`: S1–S4 an das neue Konzept angepasst
- `GEMINI.md`, `README.md` auf die neuen Dateien verwiesen

## 2026-09-23 – Vorratskatalog v0.1

- `docs/KATALOG_v0.1.md` und `data/catalog_v0.1.json`: 10 Kategorien, 71 Positionen mit Rechenbasis, Abteilung, Ernährungs-Tags und Charter-Modus
- Konzeptentscheidung: Die Vorratsliste ist der Kern der App, der Menüplan wird optional (wird in PRD v0.8 und Slice-Plan v0.2 nachgezogen)

## 2026-09-23 – Repo angelegt

- PRD v0.7, Slice-Plan v0.1, Mengentabelle v0.1 und Arbeitsanleitung für Gemini abgelegt
- Noch kein Code; nächster Schritt: S0 Projekt-Setup

## Vorschläge für das PRD

- (noch keine)
