# Provy UX Wireframes v0.1

Stand: 05.10.2026  
Status: **OWNER-ACCEPTED / UX-D DESIGN FROZEN**

Grundlage:
- `docs/design/PROVY_UX_DIRECTION_v0.3.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/PRODUCT_GUEST_SHOPPING_v0.2.md`

Dieses Dokument friert die Screen-by-Screen-Runde gemäß Entscheidung 40B ein. Die folgenden sechs Kernbereiche gelten als verbindliche Informations- und Interaktionsarchitektur. Pixelmaße, exakte Tokens und Motion-Durations werden im UX-D-Implementierungsslice aus dem bestehenden Design-System abgeleitet; die hier festgelegte Hierarchie und das Verhalten dürfen dabei nicht eigenmächtig verändert werden.

## 1. Home

Zweck: relevanten Törn zeigen, Situation verständlich machen, direkten Einstieg ermöglichen.

Verbindlich:
- nur der aktuell relevante Törn prominent
- keine Karten für weitere zukünftige Törns
- Situationsstatus zuerst: z. B. `In 8 Tagen`, `Tag 4 von 14`, `Törn beendet`
- danach Törnidentität: Revier/Name, Datum, Bootsname, optional Modell, Crew, Dauer
- Karte selbst öffnet Törnübersicht
- separater CTA öffnet die aktuelle Next Action
- `+ Neuer Törn` sichtbar
- `Alle Törns` sekundär
- keine Wetter-, Backup-, Settings- oder sonstigen Dashboardkarten
- Empty State: direkte Aktion `Törn anlegen`, kein Tutorial-Karussell

## 2. Törnübersicht / Command Center

Verbindliche Struktur:
1. kompakter Törnheader
2. genau eine dominante Next Action
3. vier gleich große permanente Kacheln:
   - Vorräte
   - Einkaufen
   - Crew & Boot
   - Bordkasse
4. kontextabhängiger Quick Action/FAB, wenn sinnvoll

Feste Anordnung:
`Vorräte | Einkaufen`
`Crew & Boot | Bordkasse`

Regeln:
- Kachelpositionen und Größen bleiben stabil
- jede Kachel zeigt höchstens 1–2 relevante Statuswerte
- Einlagern und Abrechnung sind situative Unterfunktionen, keine permanenten Kacheln
- Next Action basiert auf Lifecycle + tatsächlichem Datenzustand
- bei Konkurrenz: eine Hauptaktion + maximal eine kleine sekundäre Aktion
- Next Action bleibt Empfehlung und ist grundsätzlich ignorierbar
- Tap auf Header öffnet Törn bearbeiten

## 3. Vorräte

Zweck: Search-first, skipper-gesteuerte Liste, intelligente Hinweise ohne automatische Vollversorgung.

Verbindlich:
- leerer Start mit prominenter Produktsuche
- keine ungefragt vorbefüllte Liste
- `Zuletzt verwendet` / `Für dieses Boot üblich` nur als Shortcuts
- bei gefüllter Liste Suche kompakt/sticky erreichbar
- Standardgruppierung nach Supermarkt-Abteilung
- Suchtreffer direkt auf Variantenebene
- Tap auf Variante öffnet kompaktes Bottom Sheet
- Packungsgrößen als Chips
- Anzahl als `− Zahl +`; Tap auf Zahl öffnet Pickwheel/Direkteingabe
- eigene Position über sichtbaren Pfad
- vorhandene Position über dasselbe Muster bearbeitbar

Hinweise:
- kontextuell am Artikel
- needs-based darf Provy rechnen und Empfehlungen geben
- guided darf Provy vorsichtig plausibilisieren
- preference-based keine automatische Crew×Tage-Menge
- keine heimlichen Mengenänderungen
- `Liste prüfen` als verdichtete, nicht verpflichtende Review-Ansicht
- Readiness: Bereit / Noch prüfen / Aktion nötig
- Gewicht nicht permanent prominent; eher Review/Detail

## 4. Einkaufen + Guest Shopping

### Einkaufen
Einstieg zeigt Einkaufsstopps mit Status; relevantester Stopp prominent.

Stoppdetail:
- Positionen und Abteilungsübersicht
- dominante Aktion `Einkauf starten`
- sichtbare sekundäre Aktion `Einkauf aufteilen`
- Stop bearbeiten separat

Shopping Mode:
- große Touch-Ziele
- Tap auf Zeile = gekauft
- Fortschritt sichtbar
- kein Swipe/Long-Press als notwendiger Pfad
- `Später kaufen` verlangt transparentes Ziel; keine still erzeugten Stopps
- Abschluss führt situativ zu Einlagern

### Guest Shopping
- Einstieg ausschließlich unter `Einkaufen`
- standardmäßig Abteilungsgruppen vorgeschlagen
- Einzelpositionen optional anpassbar
- Helfername optional
- Share ist QR-first
- darunter Link teilen / Offline teilen
- Provy wählt Online/Offline normalerweise automatisch und erklärt den Zustand verständlich
- kein Account, keine App, keine Gastlizenz
- Gastseite extrem reduziert auf freigegebenes Paket
- bereits geladene Gastseite funktioniert bei Verbindungsverlust offline weiter und synchronisiert später
- Zero-Internet-Share muss aus lokaler DB möglich sein
- bei zu großem Payload Multi-QR statt Kürzung
- rein offline erledigtes Paket beim Owner: `Alles gekauft` + Ausnahmen
- Rückgabe-QR nicht Pflicht für GUEST1 v1
- dieselbe Menge darf nicht gleichzeitig zwei aktiven Paketen zugewiesen werden; echte Splits explizit als Mengenallocation

## 5. Crew & Boot

Ein Screen, zwei Sektionen, Boot zuerst.

Boot:
- Bootsname prominent
- optional Hersteller/Modell
- nur für Provy relevante technische Daten: Kühlschrank, Gefrierfach, Wassertank, Trinkbarkeit, Watermaker, ggf. spätere Storage-Kapazitäten
- keine Bootsregister-Überladung
- gespeichertes Bootsprofil mit Snapshot-Semantik
- Profiländerungen ändern historische Törns nie automatisch
- explizites Resync möglich
- numerische Werte über Stepper/Pickwheel/Direkteingabe

Crew:
- kompakte Liste
- relevante Abweichungen sichtbar, z. B. vegetarisch / kein Alkohol
- keine unnötige Ernährungs-/Allergie-Engine
- Allergie-Freitext nur mit klarer Nicht-Sicherheitssemantik
- Restauranttage gehören in Törndetails, nicht Crew
- Törn darf mit reiner Crewanzahl angelegt werden; Namen sind optional nachpflegbar
- Guest Shopper ist keine Identity und kein automatisches Crewmitglied

## 6. Bordkasse

Primär während des Törns:
- aktueller Kassenstand
- große Aktionen `Einzahlen` und `Ausgabe`
- zuletzt relevante Bewegungen
- Abrechnung sekundär, bis sie zeitlich relevant wird

Ausgabe:
- Betrag
- Kategorie
- bezahlt aus/von
- Beschreibung
- seltene Details unter Progressive Disclosure
- Geldbetrag per Tastatur, nicht Pickwheel

Einzahlung:
- Person
- Betrag
- speichern

Abrechnung:
- gegen Törnende prominent und zugleich mögliche Next Action
- Fokus auf `Wer zahlt wem wie viel?`
- keine Schuldenmatrix als Primäransicht
- Zahlung nur anstoßen: Banking/EPC-QR, IBAN kopieren, ggf. externe Links
- Provy wickelt kein Geld ab
- persönliche Salden dominieren nicht den laufenden Bordkassen-Screen
- Nachschuss-Hinweise ruhig formulieren

## 7. Visual / Motion / Nightwatch

Für alle sechs Bereiche:
- Light Default: ruhiges Off-White, Navy-Typografie, maritime Akzente
- Dark Mode erhält dieselbe Informationshierarchie
- Nightwatch/Rotlicht erhält dieselbe Informationshierarchie und Bedienbarkeit, nicht bloß Farbinvertierung
- Status nie nur über Farbe
- Bereichsidentität: Icon + Akzentlinie + leichte Tönung
- Motion funktional: Press, Confirm, räumlich nachvollziehbare Transition, Value Change
- Haptics: Tick für mechanische Controls, Confirm für wichtige Aktionen, Error nur bei echten Fehlern
- Reduce Motion respektieren

## 8. Freeze-Regel

Mit Owner-Akzeptanz aller sechs Wireframes ist die UX-Detailrunde abgeschlossen.

Ab jetzt:
- Verhalten, Hierarchie, Hauptnavigation, Screen-Zwecke und zentrale Interaktionsmuster gelten als **frozen**
- Implementierung darf Pixelmaße, Tokens, exakte Abstände und Easing innerhalb des Design-Systems ausarbeiten
- neue Hauptbereiche, neue permanente Dashboard-Kacheln oder abweichende Navigationshierarchien benötigen eine ausdrückliche neue Owner-Entscheidung
