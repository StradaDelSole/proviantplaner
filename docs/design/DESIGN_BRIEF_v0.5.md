# Design-Brief v0.5 – Detailspezifikation

Stand: 25.09.2026 · Grundlage: `docs/PRD_v0.16.md`, `docs/KATALOG_v0.7.md`, Mockups in `docs/design/mockups/` · Ersetzt v0.3 vollständig (v0.3 bleibt als Historie im Repo)

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Stilrichtung, Stitch-Prompts, Animationshinweise |
| v0.2 | 25.09.2026 | Review der Mockups, 12 Designregeln, Hinweise je Bildschirm |
| v0.3 | 25.09.2026 | Modus "Nachtwache" (Rot auf Schwarz) |
| v0.4 | 25.09.2026 | Detailspezifikation: Informationsarchitektur, Startbildschirm und Törn-Setup, Hierarchie Kategorie → Bedarfsgruppe → Variante, Zeilentypen, alle Bildschirme mit Elementen, Zuständen und Verhalten, Design-Tokens für drei Modi, Komponenten, Texte, Barrierefreiheit, Bewegung, Bildschirm-Inventar |
| v0.5 | 26.09.2026 | Vorrang von FEEDBACK_R1: eine Liste mit Vorschlägen statt Sichten Planen/Einkaufen, keine Deckungsbewertung, nichts durchgestrichen, Bordkasse mit Kassenwart, Zahlungsdaten je Person |

> **Vorrang:** `docs/impl/FEEDBACK_R1_v0.1.md` geht diesem Dokument vor. Insbesondere entfallen: Sichten "Planen"/"Einkaufen" (5.1–5.3, ersetzt durch eine Liste mit Sortierung), Deckungsanzeige "gedeckt/knapp", Durchstreichen nicht gewählter Varianten, Revier-Auswahl (ersetzt durch "Wie warm wird es?"), Überweisungen "→ Kasse" (ersetzt durch Kassenwart).

## So ist dieses Dokument zu lesen

- **Verbindlich** für alle Oberflächen. Bei Widerspruch zu Mockups gilt dieses Dokument; bei Widerspruch zum PRD gilt das PRD.
- Mockups sind Vorlage für Anmutung, Layout und Komponenten. **Texte aus Mockups nie wörtlich übernehmen.**
- Markierung **[Vorschlag]** = Designvorschlag, der eine PRD-Entscheidung braucht; bis dahin nicht bauen.
- Bildschirm-IDs (z. B. `SC-LST-01`) werden in Code-Kommentaren und Tests referenziert.

---

## 1. Grundsätze

1. **Werkzeug, kein Spielzeug.** Ruhig, präzise, schnell bedienbar mit einer Hand an Deck.
2. **Packungen statt Rechenwerte.** Der Nutzer sieht, was er in den Wagen legt; Rechenwerte sind sekundär.
3. **Die App informiert, die Crew entscheidet.** Keine automatische Verteilung, keine Routenplanung, keine versteckte Logik.
4. **Alles veränderbar, nichts geht verloren.** Jede berechnete Zahl ist überschreibbar; Überschreibungen sind sichtbar und rücksetzbar.
5. **Offline zuerst.** Jeder Bildschirm funktioniert ohne Netz; Netzabhängiges ist klar gekennzeichnet.
6. **Aus einem Haus mit HullQ.** Gleiche Farben, Schriften, Linienästhetik und Stimme; "powered by HullQ" dezent.

### Verbindliche Designregeln (aus v0.2/v0.3, unverändert gültig)

1. Keine Schein-Technik (System-IDs, Versionskennungen, Log-Labels, Koordinaten, Pseudo-Vorschriften).
2. Monospace nur für Zahlen und kurze Etiketten.
3. Keine Sicherheitsversprechen ("Secure SSL" o. Ä.).
4. Einwilligungstext exakt: "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden." Checkbox immer leer.
5. Keine Anker, Kompassrosen, Wellen, Segelsilhouetten – auch nicht als Icon.
6. Keine sichtbare automatische Verteilung; "→ Tag X" nur bei Zuordnung durch den Nutzer.
7. Keine erfundene Logik in Texten.
8. Fließtext ≥ 14 sp, Etiketten ≥ 12 sp, Tippflächen ≥ 48 dp, Kontrast ≥ WCAG AA.
9. Einkaufsmodus schlank.
10. Törnansicht luftig.
11. Nur v1-Funktionen zeigen.
12. "powered by HullQ" nur auf Startbildschirm, Menü "Mehr", Freischalten-Dialog.
13. Drei Farbmodi: hell, dunkel, Nachtwache.

---

## 2. Design-Tokens

Alle Werte zentral im Theme. Keine Farben, Größen oder Abstände in Widgets.

### 2.1 Farben – hell (aus `technical_maritime_m3/DESIGN.md`)

| Rolle | Wert | Verwendung |
| --- | --- | --- |
| primary | #03111F | Primäre Buttons, aktive Tabs, Überschriften-Akzente |
| primary-container | #182635 | FAB, dunkle Karten, Kassenstand-Karte |
| on-primary-container | #7F8DA0 | Sekundärtext auf dunklen Karten |
| secondary | #006A61 | "erledigt", Fortschritt, Bestätigung |
| secondary-container | #9DF2E5 | Chips "vegetarisch", ausgewählte Segmente (Füllung) |
| tertiary-fixed | #FFDCC2 | Hinweis-Karten, Badge-Hintergrund "hält X Tage" |
| on-tertiary-container | #CC7720 | Hinweis-Text und -Icons (Amber) |
| error | #BA1A1A | NUR technische Fehler (Speichern fehlgeschlagen), nie für inhaltliche Hinweise |
| surface | #F8F9FF | Seitenhintergrund |
| surface-container-lowest | #FFFFFF | Karten |
| surface-container-low | #EFF4FF | Abschnittsflächen, Gruppenköpfe |
| on-surface | #0B1C30 | Haupttext |
| on-surface-variant | #44474C | Sekundärtext |
| outline | #74777D | Rahmen aktiver Felder |
| outline-variant | #C4C6CC | Trennlinien, Kartenrahmen |

### 2.2 Farben – dunkel

Aus den Nacht-Mockups ableiten; Referenzwerte:

| Rolle | Wert |
| --- | --- |
| surface | #0B1622 |
| surface-container | #122130 |
| surface-container-high | #182A3B |
| on-surface | #E3ECF7 |
| on-surface-variant | #9FB0C3 |
| primary (Buttons) | #2BBFAE (Petrol hell) |
| on-primary | #00201D |
| secondary ("erledigt") | #4FD6C4 |
| Hinweis (Amber) | #FFB77A auf #3C1D00 |
| outline-variant | #2A3B4D |

Kontrast aller Paare ≥ 4,5:1 für Text; im Code per Test prüfen.

### 2.3 Farben – Nachtwache

| Rolle | Wert |
| --- | --- |
| surface | #000000 |
| surface-container | #120000 |
| surface-container-high | #1E0303 |
| on-surface | #E0433A |
| on-surface-variant | #A8322B |
| primary (Buttons, Füllung) | #7A1510 mit Text #FF6B61 |
| Hervorhebung | #FF5449 |
| outline-variant | #3A0B08 |

Nur Rot/Schwarz. Keine Weiß-, Blau-, Grün- oder Amberwerte. Bedeutung ausschließlich über Icons und Text. Helligkeit: Standard-Systemhelligkeit wird nicht verändert, aber Flächen bleiben dunkel. Animationen auf Übergänge ≤ 150 ms reduzieren.

### 2.4 Typografie

| Rolle | Schrift | Größe / Zeilenhöhe | Gewicht | Verwendung |
| --- | --- | --- | --- | --- |
| displaySmall | IBM Plex Sans | 32 / 40 | 600 | Kassenstand, große Summen (mit Tabellenziffern) |
| headlineMedium | IBM Plex Sans | 26 / 32 | 600 | Bildschirmtitel groß (Startbildschirm) |
| headlineSmall | IBM Plex Sans | 22 / 28 | 600 | Bildschirmtitel |
| titleMedium | IBM Plex Sans | 18 / 24 | 600 | Karten- und Sheet-Titel, Gruppennamen |
| titleSmall | IBM Plex Sans | 16 / 22 | 600 | Variantennamen |
| bodyLarge | IBM Plex Sans | 16 / 24 | 400 | Fließtext |
| bodyMedium | IBM Plex Sans | 14 / 20 | 400 | Sekundärtext, Bedarfszeilen |
| labelLarge | IBM Plex Sans | 14 / 20 | 600 | Buttons |
| labelMedium | IBM Plex Sans | 12 / 16 | 600 | Chips, Abschnittsköpfe (VERSALIEN erlaubt, Laufweite +0,5) |
| numberLarge | JetBrains Mono | 18 / 24 | 600 | Packungsangabe "3 × 750 g", Beträge in Listen |
| numberMedium | JetBrains Mono | 14 / 20 | 500 | Bedarf, Zähler |
| numberSmall | JetBrains Mono | 12 / 16 | 500 | Badges ("hält 1 Tag") |

Schriften als lokale Assets. Systemschriftgröße des Nutzers respektieren (bis 200 %), Layouts dürfen dabei umbrechen, nicht abschneiden.

### 2.5 Abstände, Raster, Formen

- Basisraster 4 dp; Standardabstände 4 · 8 · 12 · 16 · 24 · 32
- Seitenrand 16 dp; Abstand zwischen Karten 12 dp; Innenabstand Karten 16 dp
- Radien: Chips/Badges 8 dp, Karten 12 dp, Bottom Sheets 28 dp oben, Buttons 12 dp, FAB 16 dp
- Linien: Hairline 1 dp in outline-variant; gestrichelte Linie 1 dp, Strich 4 dp, Lücke 4 dp
- Schatten: keine; Ebenen über Flächenfarben (M3 tonal elevation)

### 2.6 Icons

- Material Symbols **Outlined**, Stärke 300, Größe 24 dp (in Badges 16 dp)
- Kategorien (Vorschlag, konsistent überall):

| Kategorie | Icon |
| --- | --- |
| Frühstück | bakery_dining |
| Grundnahrung | ramen_dining |
| Saucen und Würzen | soup_kitchen |
| Frisches | nutrition |
| Süßes und Snacks | cookie |
| Getränke ohne Alkohol | water_full |
| Getränke mit Alkohol | wine_bar |
| Haushalt | cleaning_services |
| Hygiene | soap |
| Bord und Technik | build |

- Ausgabenkategorien: Proviant `shopping_basket`, Getränke `local_drink`, Hafen und Liegeplatz `location_on` (kein Anker!), Diesel `local_gas_station`, Charter und Kaution `sailing` ist VERBOTEN (Segel) → `receipt_long`, Restaurant `restaurant`, Sonstiges `more_horiz`
- Zustände: erledigt `check_circle`, Hinweis `info`, Haltbarkeit `schedule`, überschrieben `edit`, gekühlt `ac_unit`, Stopp-Zuordnung `arrow_forward`, offline `cloud_off`

---

## 3. Informationsarchitektur

```
App-Start
├── Willkommen (erster Start, kein Törn)          SC-ONB-01
├── Meine Törns (Startbildschirm)                  SC-HOME-01
│   ├── Neuer Törn → Törn-Setup (Assistent)        SC-SET-01…05
│   ├── Vorlage verwenden (Pro)                    SC-HOME-02
│   └── Archiv                                     SC-HOME-03
└── Innerhalb eines Törns (4 Reiter)
    ├── Liste                                      SC-LST-01
    │   ├── Bedarfsgruppe (Sheet)                  SC-LST-02
    │   ├── Packungsgröße ändern (Dialog)          SC-LST-03
    │   ├── Einem Stopp zuordnen (Sheet)           SC-LST-04
    │   ├── Eigene Position (Sheet)                SC-LST-05
    │   ├── Suche                                  SC-LST-06
    │   ├── Einkaufsmodus je Stopp                 SC-SHOP-01
    │   └── Einlagern                              SC-STO-01
    ├── Törn                                       SC-TRP-01
    │   ├── Tag bearbeiten (Sheet)                 SC-TRP-02
    │   ├── Einkaufsstopp anlegen/bearbeiten       SC-TRP-03
    │   └── Törn-Einstellungen (Crew, Boot, Verpflegung) SC-TRP-04
    ├── Bordkasse                                  SC-KAS-01
    │   ├── Ausgabe erfassen (Sheet)               SC-KAS-02
    │   ├── Einzahlung erfassen (Sheet)            SC-KAS-03
    │   ├── Beteiligung je Person                  SC-KAS-04
    │   └── Törn abschließen                       SC-KAS-05
    └── Mehr                                       SC-MORE-01
        ├── Konto / Freischalten (Sheet)           SC-ACC-01
        ├── Darstellung (hell/dunkel/Nachtwache)   SC-MORE-02
        ├── Meine Zahlungsdaten                    SC-MORE-03
        ├── Gemerkte Packungsgrößen                SC-MORE-04
        ├── Sprache                                SC-MORE-05
        └── Rechtliches, Hilfe, Über               SC-MORE-06
```

### 3.1 Navigationsmodell

- **Ebene 1:** Startbildschirm "Meine Törns" (ohne Reiterleiste).
- **Ebene 2:** Innerhalb eines Törns Reiterleiste mit vier Reitern. Oben links Zurück-Pfeil zu "Meine Törns"; Titel = Törnname; Untertitel = "5 Personen · 7 Tage".
- **Ebene 3:** Detailbildschirme im Stack (Einkaufsmodus, Einlagern, Abschluss) ohne Reiterleiste; Bearbeitungen als Bottom Sheets.
- Zurück-Geste des Systems funktioniert überall; ungespeicherte Eingaben in Sheets → Rückfrage "Änderungen verwerfen?".
- **Phasenvorschlag:** Beim Öffnen eines Törns wählt die App den Reiter nach Phase (Planen → Liste, Einkaufen → Liste mit aktivem Stopp, Einlagern → Einlagern-Hinweis, Unterwegs → Törn, Abschluss → Bordkasse). Der Nutzer kann jederzeit wechseln; die App merkt sich den zuletzt gewählten Reiter pro Törn und schlägt nur beim Phasenwechsel neu vor.

---

## 4. Startbildschirm und Törn-Setup

### 4.1 SC-ONB-01 Willkommen (erster Start)

- Linienzeichnung (Boot-Umriss einlinig, gestrichelte Kurslinie, zeichnet sich beim Erscheinen nach)
- Titel: "Proviant und Bordkasse für euren Törn"
- Drei kurze Zeilen mit Icon: "Einkaufsliste in Minuten" · "Einkaufsstopps selbst planen" · "Bordkasse fair abrechnen"
- Primär: "Ersten Törn planen" · Sekundär (Text-Button): "Ich habe ein HullQ-Konto" (öffnet SC-ACC-01)
- Unten: "powered by HullQ"

### 4.2 SC-HOME-01 Meine Törns

- App-Leiste: Titel "Meine Törns"; rechts Icon "Mehr" (öffnet SC-MORE-01 ohne Törnkontext)
- Abschnitt **"Aktiv und geplant"**: Törnkarten, sortiert nach Startdatum
  - Karte: Name (titleMedium), Datum "12.–19. Okt." (numberMedium), "5 Personen · 7 Tage", Phasen-Chip ("Planen", "Einkaufen", "Unterwegs", "Abschluss"), Fortschrittszeile je Phase (z. B. "Liste: 34 von 41 Positionen gewählt")
  - Tipp → Törn öffnen; langes Drücken → Menü "Umbenennen", "Duplizieren", "Archivieren", "Löschen" (mit Bestätigung)
- Abschnitt **"Archiv"** eingeklappt mit Anzahl
- FAB: "+ Neuer Törn"
- Zustand Probetörn verbraucht und kein Konto: FAB öffnet SC-ACC-01 statt Setup
- Leerzustand (alle archiviert): Linienzeichnung + "Kein aktiver Törn" + Button "Neuen Törn planen"

### 4.3 Törn-Setup-Assistent SC-SET-01…05

Vollbild, ohne Reiterleiste, Fortschrittsbalken in 5 Segmenten, "Zurück"/"Weiter" unten fix, Schließen oben links (Rückfrage). Jeder Schritt einzeln speicherbar; Abbruch legt einen Entwurf an ("Entwurf" auf der Törnkarte).

**SC-SET-01 Grunddaten**
- Törnname (Textfeld, Pflicht, Vorschlag "Törn Oktober")
- Startdatum (Datumswähler) und Anzahl Tage (Stepper 1–30, Standard 7)
- "Charter oder eigenes Boot?" – zwei große Auswahlkarten mit Icon und Einzeiler: "Charter · Technik stellt die Basis" / "Eigenes Boot · Technik als Prüfliste"
- Revier (Pflicht, drei Karten): "Gemäßigt (Nord-/Ostsee)", "Mittelmeer im Sommer", "Heiß oder abgelegen" – Unterzeile "bestimmt die Trinkwassermenge"

**SC-SET-02 Boot**
- Bootstyp: Segmente "Einrumpf" / "Katamaran"
- Kühlkapazität: Schieberegler mit Liter-Anzeige (numberLarge) und Voreinstellungen je Bootstyp (Einrumpf 90 l, Katamaran 150 l); Hinweis "Du kannst das später ändern"
- [Vorschlag] Ausstattung (Schalter): "Tiefkühlfach", "Backofen", "Grill" – würde Varianten wie Garnelen (TK), Aufbackbrötchen, Grillkohle automatisch vorab-/abwählen. PRD-Entscheidung offen; bis dahin weglassen.

**SC-SET-03 Crew**
- Liste der Crewkarten; jede Karte: Initialen-Avatar, Name, Chips "Erwachsener"/"Kind", "vegetarisch", "trinkt keinen Alkohol", Rolle "Skipper" (optional)
- "+ Person hinzufügen" öffnet kompakte Eingabe (Name + Chips) direkt in der Liste, Tastatur bleibt offen für die nächste Person
- Mindestens 1 Person; Zähler oben rechts "5 Personen"
- Wischen nach links → Entfernen (mit Rückgängig-Snackbar)

**SC-SET-04 Verpflegung**
- "Wie isst eure Crew?" – 4 Segmente (eher leicht · ganz normal · gut und gern · hungrige Segler), Untertext der Auswahl: "−10 %", "Standard", "+15 %", "+25 %"
- "Wie viel wird an Bord getrunken?" – 3 Segmente (gemütlich · normal · feierfreudig); ausgegraut mit Hinweis, wenn niemand Alkohol trinkt
- Schalter "Reserve für Ankertage und schlechtes Wetter", Untertext "+10 % auf haltbare Vorräte"
- Ausklappbar "Details pro Person": je Person Essen (klein/normal/groß) und Trinken (keiner/wenig/normal/viel); gesetzte Werte überstimmen die Crew-Einstellung für diese Person (Hinweis-Badge "individuell")

**SC-SET-05 Zusammenfassung**
- Karten: Grunddaten, Boot, Crew, Verpflegung – jeweils mit "Ändern"
- Vorschau: "Eure Liste: ca. 41 Positionen in 10 Kategorien" (echte Zahl aus der Engine)
- Hinweis-Karte (Amber, info): "Tage, Restaurantbesuche und Einkaufsstopps planst du danach im Reiter Törn – alles optional."
- Primär: "Liste erstellen" → öffnet Törn im Reiter Liste; kurze Einblendung "Liste erstellt" mit sanfter Aufbau-Animation

---

## 5. Reiter Liste – Hierarchie der Warengruppen

### 5.1 Zwei Sichten

| Sicht | Zweck | Gliederung |
| --- | --- | --- |
| **Planen** (Standard vor dem Einkauf) | Auswählen, Anteile, Mengen | Kategorie → Bedarfsgruppe → Varianten |
| **Einkaufen** (Standard ab Phase Einkaufen) | Im Laden abarbeiten | Supermarkt-Abteilung → Varianten (flach) |

Umschalter als Segment oben: "Planen" / "Einkaufen". Im Kopf zusätzlich Chip "Einkauf: Alle Stopps ▾" (Auswahl: Alle / Tag 1 Basis / Tag 4 Hvar …). Suchen-Icon rechts.

### 5.2 Sicht "Planen" – Aufbau

```
[Kategoriekopf]  Frühstück                          10 Gruppen · 2 offen
  [Gruppenzeile] Brot und Backwaren     ✓ gedeckt   4 Varianten
      Vollkornbrot · Baguette · Brötchen · Knäckebrot
  [Gruppenzeile] Käse                   ~ knapp     2 Varianten
  …
[Kategoriekopf]  Bord und Technik (eingeklappt beim Charter: "Motor, Elektrik … – beim Charter Sache der Basis")
```

- **Kategoriekopf** (sticky beim Scrollen): Kategorie-Icon, Name (titleMedium), rechts Zähler "10 Gruppen · 2 offen"; tippen klappt ein/aus. Reihenfolge wie Katalog.
- **Gruppenzeile** (Karte, 72–88 dp hoch):
  - Links Gruppenname (titleSmall), darunter gewählte Varianten als Kurzliste (bodyMedium, max. 2 Zeilen, dann "+2")
  - Rechts Deckungsanzeige: "✓ gedeckt" (secondary + Icon), "~ knapp" (Amber + Icon, Summe < Bedarf), "keine gewählt" (on-surface-variant); darunter Anzahl Packungen gesamt (numberMedium)
  - Tipp → Gruppen-Sheet SC-LST-02
  - Gruppen mit Modus "Prüfliste" zeigen statt Deckung "3 von 7 geprüft"
- **Abgewählte Gruppen** (keine Variante gewählt): eingegraut am Ende der Kategorie, Filter "Abgewählte ausblenden" im Menü
- **Eigene Positionen** erscheinen in ihrer Kategorie als eigene Gruppe "Eigene Positionen"

### 5.3 Sicht "Einkaufen" – Aufbau

- Abschnitte nach Abteilung in fester Ladenreihenfolge: Obst und Gemüse · Backwaren · Molkerei und Kühlregal · Fleisch und Fisch · Trockenware · Konserven · Süßwaren · Getränke · Drogerie · Haushalt · Apotheke / Drogerie · Technik / Bootszubehör
- Abschnittskopf sticky: Abteilungsname (labelMedium Versalien), Zähler "4 Posten"
- **Variantenzeile** (Standardzeile der App, ≥ 72 dp):
  - Zeile 1: Name (titleSmall) · rechts Packungsangabe **"3 × 750 g"** (numberLarge)
  - Zeile 2: "Bedarf ca. 2,1 kg · +150 g Reserve" (numberMedium, on-surface-variant)
  - Zeile 3 (nur wenn zutreffend, Badges): "hält 1 Tag" (Amber, schedule) · "gekühlt" (ac_unit) · "überschrieben" (edit) + Text-Button "zurücksetzen" · "→ Tag 4" (arrow_forward)
  - Rechts neben Zeile 1–2: Stepper [−] Zahl [+] (48 dp Tippflächen); die Zahl ist die Packungszahl
  - Tipp auf die Zeile (außerhalb Stepper) → Gruppen-Sheet mit markierter Variante
- Bei gewähltem Stopp zeigt die Liste nur die Mengen dieses Stopps; Kopfzeile "Einkauf Tag 4 · 18 Posten"

### 5.4 SC-LST-02 Gruppen-Sheet (Bottom Sheet, bis 90 % Höhe)

- Kopf: Gruppenname (titleMedium), Kategorie-Icon, Schließen
- Bedarfszeile: "Bedarf: 120 g pro Person und Tag · gesamt ca. 4,2 kg" (Werte aus Engine); bei Aufteilung "je Variante": "Jede Sorte wird einzeln berechnet"
- Variantenliste (Checkbox links):
  - Name + Packung "(750 g)" · Haltbarkeits-Badge
  - Bei Aufteilung "gleichmäßig": Anteilsregler (0–100 %, Schritte 5 %) mit Prozentzahl; Regler verteilen automatisch neu, Summe immer 100 %; Doppeltipp auf Regler = "gleichmäßig"
  - Ergebnis rechts: "2 × 750 g (1,5 kg)"
  - Link "Packungsgröße ändern" → SC-LST-03
- Summenleiste unten (sticky): "Gesamt 4,3 kg von 4,2 kg Bedarf" + Deckungsanzeige
- Aktionen: Sekundär "Teilmenge einem Einkaufsstopp zuordnen" (→ SC-LST-04), Primär "Übernehmen"
- Hinweis bei Gruppen "nur eigenes Boot" im Charter-Modus: Karte "Beim Charter stellt die Basis Motor und Technik. Trotzdem anzeigen?" mit Schalter

### 5.5 SC-LST-03 Packungsgröße ändern (Dialog)

- Titel "Packungsgröße Baguette"; Zahlenfeld + Einheit (Auswahl passend zur Einheit, z. B. g/kg)
- Schalter "Für künftige Törns merken" (Standard an)
- Hinweis: "Die Packungszahl wird neu berechnet."

### 5.6 SC-LST-04 Einem Stopp zuordnen

- Liste der Einkaufsstopps (Tag + Name); je Stopp Stepper für Packungen
- Anzeige "Verteilt: 5 von 5 Baguettes · davon Tag 1: 3, Tag 4: 2"
- Nicht zugeordnete Menge gehört automatisch zum ersten Stopp (Text so anzeigen)
- Kein Stopp vorhanden: Hinweis + Button "Einkaufsstopp anlegen" (→ SC-TRP-03)

### 5.7 SC-LST-05 Eigene Position

- Felder: Name, Menge, Einheit (Stück, g, kg, ml, l, Packung), Kategorie (Auswahl), Abteilung (vorbelegt aus Kategorie), Stopp (optional)
- Wird nicht berechnet, nur gezählt; Badge "eigene Position"

### 5.8 SC-LST-06 Suche

- Suchfeld mit Sofortergebnis über Variantennamen, Gruppen und Kategorien; Ergebnis öffnet das Gruppen-Sheet
- Kein Treffer: "Nicht im Katalog – als eigene Position anlegen?" (Button)

### 5.9 SC-SHOP-01 Einkaufsmodus je Stopp

- App-Leiste: Zurück, Titel "Einkauf Tag 4 · Supermarkt Hvar", Aktion "Ausgabe erfassen" (→ SC-KAS-02 mit Kategorie Proviant und Stopp vorbelegt)
- Fortschritt: "12 von 18 erledigt" + dünner Balken (secondary)
- Liste nach Abteilung; Zeilen: große Checkbox links (48 dp), Name, Packungsangabe rechts; keine Stepper (Änderungen nur per langem Drücken → Menge anpassen)
- Abgehakt: Zeile gedimmt, durchgestrichen, wandert ans Ende der Abteilung (Animation 200 ms)
- Unten fix: "Fertig eingekauft" – bei offenen Posten Rückfrage "6 Posten nicht gekauft – für einen späteren Stopp merken oder streichen?"
- Bildschirm bleibt an (Wakelock) solange geöffnet

### 5.10 SC-STO-01 Einlagern

- Hinweis-Karte oben (Amber): "Kartons an Land auspacken – Ungeziefer reist in Wellpappe mit."
- Checkliste nach Einlagerungs-Hinweisen gruppiert (Kennungen aus Katalog `storage_hints`): je Punkt Titel, ein Satz Erklärung, betroffene Posten als Kurzliste ("Mais, Kichererbsen, Thunfisch")
- Im Revier "heiß oder abgelegen" automatisch vorgeschlagen, sonst über Liste → Menü "Einlagern" erreichbar
- Unten: "Einlagerung abschließen"

---

## 6. Reiter Törn

### 6.1 SC-TRP-01 Übersicht

- **Phasenkarte** oben: aktuelle Phase als Stufenleiste (Planen · Einkaufen · Einlagern · Unterwegs · Abschluss), darunter nächste sinnvolle Aktion als Button (z. B. "Einkauf Tag 1 starten"). Phase wechselt der Nutzer per Tipp; die App schlägt nur vor.
- **Zusammenfassung:** "5 Bord-Abendessen · 4 Bord-Mittagessen · 2 Einkaufsstopps"
- **Tagesleiste** vertikal: eine Karte je Tag, verbunden durch feine gestrichelte Linie links
  - Kopf: "Tag 3 · Mi, 14. Okt." (titleSmall + numberMedium)
  - Optional (grau, nur wenn gesetzt): Tagestyp-Chip ("Ankerbucht") und Hafenname
  - Zwei Umschalt-Chips: "Mittags Restaurant" / "Abends Restaurant" (aktiv = gefüllt mit Icon restaurant)
  - Falls Einkaufsstopp an diesem Tag: Zeile "Einkauf · Supermarkt Hvar · 18 Posten" mit Pfeil (→ SC-SHOP-01)
  - Tipp auf Karte → SC-TRP-02
- Button "+ Einkaufsstopp" (→ SC-TRP-03); Menü: "Törn-Einstellungen" (→ SC-TRP-04)

### 6.2 SC-TRP-02 Tag bearbeiten (Sheet)

- Schalter Mittags/Abends Restaurant; Tagestyp (Marina · Hafen · Ankerbucht · Überfahrt · keiner); Hafenname (Text); Notiz (Text, optional)
- Hinweis: "Tagestyp und Hafen dienen nur deiner Übersicht."

### 6.3 SC-TRP-03 Einkaufsstopp

- Tag (Auswahl), Name (optional, z. B. "Supermarkt Hvar"); Löschen (erster Stopp nicht löschbar, nur umbenennbar)

### 6.4 SC-TRP-04 Törn-Einstellungen

- Abschnitte wie Setup (Grunddaten, Boot, Crew, Verpflegung); Änderungen rechnen die Liste sofort neu; Hinweis-Snackbar "Liste aktualisiert – 3 überschriebene Mengen bleiben unverändert"

---

## 7. Reiter Bordkasse

### 7.1 SC-KAS-01 Übersicht

- **Kopfkarte** (primary-container):
  - Modell-Chip: "Gemeinsame Bordkasse" oder "Einzelabrechnung" (Tipp → Wechsel mit Erklärung; Wechsel nur solange keine Ausgaben erfasst sind)
  - Bordkasse: "Kassenstand" (displaySmall) · "Eingezahlt 1.000,00 € · Ausgegeben 687,60 €"
  - Einzelabrechnung: "Gesamtausgaben" + "Offen: 3 Ausgleichszahlungen"
- Segment "Ausgaben" / "Personen"
- **Ausgaben:** chronologisch absteigend, nach Tag gruppiert; Zeile: Kategorie-Icon, Titel, "aus der Kasse" oder "bezahlt von Ben", Tag-Chip; Betrag rechts (numberLarge); Tipp → bearbeiten
- **Personen:** je Person Saldo ("bekommt 18,00 €" / "zahlt 42,10 €" / "ausgeglichen"), Chip "Skipper frei" bzw. "beteiligt an 5 von 7 Kategorien"; Tipp → SC-KAS-04
- FAB "+ Ausgabe"; Menü: "Einzahlung erfassen", "Törn abschließen"

### 7.2 SC-KAS-02 Ausgabe erfassen (Sheet)

- Betrag (großes Zahlenfeld, numberLarge, Währungsauswahl nur im Probetörn/Pro), Titel, Kategorie (Chips mit Icons), Tag (vorbelegt: heute), "Bezahlt von" (Kasse oder Person), Aufteilung (Standard: nach Beteiligung; optional "anders aufteilen" → Beträge je Person)
- Speichern mit Rückgängig-Snackbar

### 7.3 SC-KAS-03 Einzahlung (nur Bordkasse)

- Person, Betrag, Datum; Vorschlag "gleicher Betrag für alle" (Button)

### 7.4 SC-KAS-04 Beteiligung je Person

- Matrix: Personen als Zeilen, Kategorien als Spalten (Icons im Kopf), Schalter in Zellen; Schnellauswahl je Person: "überall beteiligt", "Skipper frei (ganz)", "Skipper frei (Charter, Hafen, Diesel)", "kein Alkohol"
- Querformat oder horizontales Scrollen erlaubt; erste Spalte fixiert

### 7.5 SC-KAS-05 Törn abschließen

- Liste "Wer zahlt wem" (minimale Anzahl Überweisungen); Zeile: "Ben → Kasse 42,10 €", Status "offen/erledigt"
- Aufklappen: QR-Karte (EPC, 240 dp, weißer Rand auch im Nachtmodus für Scanbarkeit – einzige erlaubte Ausnahme von der Nachtwache-Palette, mit Hinweis "Zum Scannen kurz hell"), Empfänger, IBAN teilmaskiert, Betrag, Verwendungszweck; Buttons "Daten kopieren", "PayPal-Link teilen", "Revolut-Link teilen" (nur wenn hinterlegt)
- Hinweis grau: "Die App wickelt keine Zahlungen ab."
- "Als erledigt markieren" je Zahlung; Primär "Törn archivieren" (aktiv, sobald alle erledigt oder bewusst bestätigt)

---

## 8. Reiter Mehr

- Konto-Karte: nicht angemeldet → "Kostenlos freischalten mit HullQ-Konto" (→ SC-ACC-01); angemeldet → E-Mail, "Sicherung: zuletzt heute 18:40", "Jetzt sichern", "Abmelden", "Konto löschen"
- Darstellung (SC-MORE-02): System · Hell · Dunkel · **Nachtwache**; Schnellzugriff "Nachtwache ein/aus" zusätzlich als oberste Zeile im Mehr-Menü
- Meine Zahlungsdaten (SC-MORE-03): Name, IBAN, PayPal-Link, Revolut-Link; Hinweis "Nur auf diesem Gerät gespeichert"
- Gemerkte Packungsgrößen (SC-MORE-04): Liste mit Zurücksetzen
- Sprache (SC-MORE-05): System · DE · EN · FR · ES · PT · HR
- Hilfe und Tipps, Datenschutz, Impressum, Nutzungsbedingungen, Über (Version im Klartext "Version 1.0.0"), "powered by HullQ"

### SC-ACC-01 Freischalten (Sheet)

- Titel "Weiteren Törn planen" (bzw. "Mit HullQ-Konto anmelden")
- Text: "Mit einem kostenlosen HullQ-Konto planst du unbegrenzt Törns und sicherst sie für den Gerätewechsel."
- Vorteile (drei Zeilen mit Icon): "Unbegrenzte Törns", "Sicherung und Wiederherstellung", "Mehrere eigene Geräte"
- Buttons: "Mit Google fortfahren", "Mit Apple fortfahren", "Mit E-Mail fortfahren"
- Checkbox leer: "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden."
- Links: Datenschutz · Nutzungsbedingungen · "powered by HullQ"
- Offline: Buttons deaktiviert + "Anmeldung braucht eine Internetverbindung"

---

## 9. Zustände

| Zustand | Gestaltung |
| --- | --- |
| Leer | Linienzeichnung (einlinig, gestrichelt), ein Satz in der Stimme des trockenen Freundes, ein Button |
| Laden | Sonar-Ringe (2–3 Ringe, 1,2 s Zyklus), nie länger als nötig; unter 300 ms nichts anzeigen |
| Offline | dezentes Symbol cloud_off in der App-Leiste nur bei netzabhängigen Aktionen; keine Dauerbanner |
| Fehler (technisch) | Snackbar mit Klartext und "Erneut versuchen"; Farbe error nur hier |
| Erfolg | kurze Snackbar ("Ausgabe gespeichert") mit "Rückgängig" (5 s) |
| Überschrieben | Badge "überschrieben" + "zurücksetzen" |
| Nicht gedeckt | "~ knapp" in Amber mit Icon, nie Rot |

Beispieltexte (trockener Freund): Leere Liste "Noch nichts zu kaufen. Das ändert sich gleich." · Laden "Rechnen, wie viel Brot fünf Leute essen …" · Offline-Hinweis "Ohne Netz geht alles – außer Anmelden und Sichern."

---

## 10. Texte und Formate

- **Zwei Stimmen:** sachlich bei Zahlen, Mengen, Beträgen, Hinweisen; trocken-freundlich nur bei Leer-, Lade- und Erfolgszuständen. Kein Humor bei Geld und Mengen.
- Duzen, kurze Sätze, aktive Verben ("Ausgabe erfassen", nicht "Erfassung der Ausgabe").
- Zahlen im Format der Gerätesprache (DE: 1.000,00 €, 2,5 kg); Einheiten mit schmalem Leerzeichen; "×" für Packungen.
- Plural sauber über ARB (1 Posten / 2 Posten).
- Textlänge: Layouts für +35 % Textlänge auslegen (FR, ES, PT); keine abgeschnittenen Buttons, lieber Umbruch.
- Keine Anglizismen, wo es gute deutsche Wörter gibt; Fachbegriffe der Segler sind erlaubt (Törn, Skipper, Bordkasse).

---

## 11. Bewegung

| Ereignis | Animation | Dauer / Kurve |
| --- | --- | --- |
| Abhaken | Häkchen "rastet ein" (leichtes Überschwingen), Zeile dimmt und gleitet ans Abschnittsende | 200 ms, spring |
| Packungszahl ändern | Zahl zählt kurz (AnimatedSwitcher, vertikal) | 150 ms |
| Deckungsanzeige | Wechsel "~ knapp" → "✓ gedeckt" mit kurzem Aufblenden | 200 ms |
| Sheet öffnen | M3 Standard | 250 ms emphasized |
| Zeile → Sheet | Container-Transform | 300 ms |
| Liste erstellen | Kategorien bauen sich gestaffelt auf | je 40 ms Versatz, max. 400 ms |
| Leerzustand | Linie zeichnet sich nach | 600 ms |

Systemeinstellung "Bewegung reduzieren" → alle Animationen aus, nur Überblendungen ≤ 100 ms. Nachtwache → nur Überblendungen.

---

## 12. Barrierefreiheit

- Screenreader-Beschriftung für jedes Icon und jede Zahl ("drei Packungen à 750 Gramm")
- Fokusreihenfolge logisch; Stepper als zusammenhängende Einheit angesagt
- Farben nie allein; jede Statusfarbe mit Icon und Text
- Große Schrift bis 200 % ohne abgeschnittene Inhalte
- Einhandbedienung: primäre Aktionen unten erreichbar

---

## 13. Bildschirm-Inventar

| ID | Bildschirm | Mockup | Slice |
| --- | --- | --- | --- |
| SC-ONB-01 | Willkommen | – (neu) | S3 |
| SC-HOME-01 | Meine Törns | – (neu) | S3 |
| SC-SET-01…05 | Törn-Setup | 01 (Schritt Crew/Verpflegung) | S3 |
| SC-LST-01 | Liste (Planen/Einkaufen) | 02 | S4 |
| SC-LST-02 | Gruppen-Sheet | 03 | S4 |
| SC-LST-03…06 | Packungsgröße, Zuordnen, Eigene Position, Suche | – | S4 |
| SC-SHOP-01 | Einkaufsmodus | 04 | S4 |
| SC-STO-01 | Einlagern | 05 | S4 |
| SC-TRP-01…04 | Törn, Tag, Stopp, Einstellungen | 06 | S3/S4 |
| SC-KAS-01…05 | Bordkasse, Ausgabe, Einzahlung, Beteiligung, Abschluss | 07, 08 | S5 |
| SC-MORE-01…06 | Mehr, Darstellung, Zahlungsdaten, Packungsgrößen, Sprache, Rechtliches | – | S-UI/S7 |
| SC-ACC-01 | Freischalten | 09 | S6/S7 |

---

## 14. Offene Designfragen

- [ ] [Vorschlag] Boot-Ausstattung (Tiefkühlfach, Backofen, Grill) im Setup – PRD-Entscheidung
- [ ] Mockups für neue Bildschirme (Willkommen, Meine Törns, Setup-Schritte 1, 2, 5, Mehr) in Stitch erzeugen
- [ ] Nachtwache-Mockup der Liste zur Prüfung der Rottöne
- [ ] App-Name und Icon
