# Design-Brief und Stitch-Prompts v0.3

Stand: 25.09.2026 · Grundlage: `docs/PRD_v0.16.md` · Mockups ablegen unter `docs/design/mockups/` (Dateiname `NN_bildschirm_v0.1.png`)

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: Stilrichtung aus HullQ-CI abgeleitet, globaler Stil-Prompt, 9 Bildschirm-Prompts, Animationshinweise für Flutter |
| v0.2 | 25.09.2026 | Review der Stitch-Mockups: verbindliche Designregeln, Design-System `technical_maritime_m3/DESIGN.md` als Theme-Grundlage, Abweichungen je Bildschirm |
| v0.3 | 25.09.2026 | Dritter Modus "Nachtwache" (Rot auf Schwarz) zur Schonung der Nachtsicht |

## Verbindliche Designregeln (v0.2, nach Review der Mockups)

Die Mockups unter `docs/design/mockups/` sind die **Vorlage für Layout, Hierarchie und Komponenten**. Wo sie diesen Regeln oder dem PRD widersprechen, gelten die Regeln und das PRD. Texte aus den Mockups werden NICHT wörtlich übernommen; maßgeblich sind PRD und Katalog.

**Theme-Grundlage:** `docs/design/mockups/technical_maritime_m3/DESIGN.md` (Farben, Typografie, Radien, Abstände) wird als zentrales Flutter-Theme für hell und dunkel umgesetzt. Der Nachtmodus der Mockups ist die Referenz für das dunkle Theme.

1. **Keine Schein-Technik:** keine System-IDs, Versionskennungen, Log-Bezeichnungen, Protokollnamen, Koordinaten oder Pseudo-Vorschriften als Dekoration (z. B. "SYS.ID // …", "REV 04.2", "M3.LOG.V2", "MARITIME SPEC V3.4", "Stauvorschrift · Quarantäne HULL-PROV-04", GPS-Koordinaten). Jedes Textelement muss dem Nutzer eine echte Information geben.
2. **Monospace (JetBrains Mono) nur für Zahlen und kurze Etiketten** (Mengen, Beträge, Zähler, Badges), nie als Stilmittel für Überschriften oder Fließtext.
3. **Keine Sicherheitsversprechen:** kein "SECURE SSL", "AUTH PROTOCOL" oder Ähnliches.
4. **Einwilligungstext exakt:** "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden." Nicht erweitern (z. B. nicht "und maritime Ausrüstung"). Checkbox immer leer.
5. **CI-Verbote gelten auch für Icons:** kein Anker, keine Kompassrose, keine Wellen, keine Segelsilhouetten. Für Liegeplatz/Boje ein neutrales Icon (z. B. Ort/Pin).
6. **Keine automatische Verteilung sichtbar machen:** keine Anzeigen wie "Tag 1 & 2" oder "Split Tag 1 & 4", solange der Nutzer nichts einem Stopp zugeordnet hat. Zuordnungen erscheinen nur als "→ Tag X", wenn der Nutzer sie gesetzt hat.
7. **Keine erfundene Logik in Texten:** Erklärtexte müssen dem PRD entsprechen, z. B. Reserve = "+10 % auf haltbare Vorräte".
8. **Lesbarkeit an Deck:** Fließtext mindestens 14 sp, Etiketten und Badges mindestens 12 sp, Tippflächen mindestens 48 dp, Kontrast mindestens WCAG AA in hell und dunkel.
9. **Einkaufsmodus schlank:** oben nur Titel des Stopps, Fortschritt und "Ausgabe erfassen"; darunter die Liste mit großen Häkchen. Keine Infokarten zu Lagerort, Währung, Besatzung oder Kassenstand.
10. **Törnansicht (Tagesleiste) luftig:** eine Karte pro Tag mit Tagesnummer, optional Tagestyp und Hafenname, zwei Schaltern (Mittags/Abends Restaurant) und ggf. Einkaufsstopp. Keine Zusatztexte pro Tag. Die feine gestrichelte Verbindungslinie darf bleiben.
11. **Nur v1-Funktionen zeigen:** Hinweise auf Funktionen aus v1.1 (z. B. "Crew-Einladungen per Link", "Cloud-Synchronisation" für die Crew) nicht in v1-Oberflächen; beim Freischalten nur die v1-Vorteile nennen (unbegrenzte Törns, Sicherung und Wiederherstellung, mehrere eigene Geräte).
13. **Drei Farbmodi:** hell, dunkel und **"Nachtwache"**. Standard folgt der Systemeinstellung (hell/dunkel); "Nachtwache" wird manuell gewählt (Einstellungen und Schnellzugriff im Menü "Mehr") und bleibt aktiv, bis er abgeschaltet wird.
    - Nachtwache: ausschließlich Rot- und Schwarztöne, keine weißen oder bläulichen Flächen, gedämpfte Helligkeit; Hintergrund reines oder nahezu reines Schwarz (z. B. #000000 / #0A0000), Text und Icons in gedämpftem Rot (z. B. #B3261E bis #FF5449 für Hervorhebungen), Flächen in sehr dunklem Rot
    - Bedeutung nie über Farbe: "erledigt", Hinweise und Warnungen über Symbole und Text (Regel: Farbe nie allein), da Petrol und Amber entfallen
    - Kein Widerspruch zur CI: Rot ist hier die Lichtfarbe des Modus, kein Warnsignal
    - Kontrast im Nachtwache-Modus so wählen, dass Text lesbar bleibt, ohne zu blenden; Animationen dort auf ein Minimum reduzieren
12. **"powered by HullQ"** dezent unten in Freischalten-Dialog, Menü "Mehr" und Startbildschirm; nicht auf jedem Bildschirm.

### Hinweise je Bildschirm

| Nr | Übernehmen | Ändern |
| --- | --- | --- |
| 01 Törn anlegen | Stepper, Crew-Karten mit Chips, Crew-Fragen als Segmente, Reserve-Schalter, "Details" einklappbar | Reserve-Text nach Regel 7; "Prognose"-Box entfernen; Personenzahl konsistent; Serifen-Darstellung ist ein Mockup-Fehler, überall IBM Plex |
| 02 Vorratsliste | Packungen groß ("3 × 750 g"), Bedarfszeile, Badges "hält X Tage", "überschrieben / zurücksetzen", "→ Tag 4", +/−-Stepper, Filter-Chips, FAB | Kopf-Statistik ("100 % proviantiert", "Verbrauchsplan Split …") entfernen; "Tag 1 & 2" entfernen (Regel 6) |
| 03 Varianten-Sheet | Checkboxen, Anteils-Regler, Packungen, "Packungsgröße ändern", Summenleiste, Buttons | "Modul // Proviantkalkulation · Rev" entfernen |
| 04 Einkaufsstopp | Fortschrittsbalken, Gruppen, abgehakte Zeilen, "Fertig eingekauft" | Infokarten entfernen (Regel 9) |
| 05 Einlagern | Amber-Hinweiskarte, Checkliste mit Kurztexten, Button | Koordinaten, "Stauvorschrift · Quarantäne …", Sektor-Kennungen entfernen |
| 06 Törn | Tageskarten, Restaurant-Schalter, Einkaufsstopp am Tag, gestrichelte Linie | deutlich größer und luftiger (Regel 10) |
| 07 Bordkasse | Kopfkarte mit Kassenstand, Skipper-frei-Zeile, Ausgabenliste mit Kategorien, FAB | Anker-Icon ersetzen (Regel 5); "Treasury-Log", "Online"-Status entfernen |
| 08 Abschluss | Liste "wer zahlt wem", QR-Karte, Kopieren, PayPal/Revolut, Hinweis "keine Zahlungsabwicklung" | Status-Zeile "Ausgleichsberechnung · Minimal Transfers" entfernen |
| 09 Freischalten | Aufbau, Login-Buttons, leere Checkbox, Rechtslinks | "Auth Protocol", "Secure SSL" entfernen; Einwilligungstext nach Regel 4; Vorteile nach Regel 11 |

## Stilrichtung

Schlicht und sachlich, Material Design 3, mit leichtem maritimem Touch. Erkennbar aus demselben Haus wie HullQ, auch wenn das HullQ-Design selbst noch nicht fertig ist. Die App ist zugleich ein Testfeld für das spätere HullQ-Mobile-Design.

Übernommen aus der HullQ-CI:

- **Minimalismus, technisch-editorial:** Zurückhaltung als Qualitätssignal, Referenzen Rams, Linear, Stripe
- **Farben:** entsättigtes Blueprint-Marineblau als Primärfarbe; Grün/Petrol als Akzent für "erledigt / bestätigt"; warmer Amber/Sand für Hinweise und Warnungen (bewusst nicht Rot); gedämpftes Grau für Nebensächliches. Farbe nie als einziges Unterscheidungsmerkmal, immer mit Icon oder Text
- **Typografie:** humanistische Sans-Serif für Text; Schrift mit tabellarischen Ziffern (z. B. Inter oder IBM Plex Sans) für Mengen und Beträge
- **Maritimer Touch ohne Klischees:** keine Anker, Kompassrosen, Wellen, Segelsilhouetten, keine Piraten- oder "Ahoy"-Sprache. Stattdessen feine Linienarbeit wie auf einer technischen Zeichnung oder Seekarte: dünne Linien, dezentes Raster in leeren Zuständen, gestrichelte Linien als Gestaltungsmittel
- **Persönlichkeit durch Mikro-Interaktionen,** nicht durch Dekoration
- **Zwei Stimmen:** sachlich-präzise bei Mengen, Beträgen und Hinweisen; trockener, kompetenter Freund bei Ladezuständen, leeren Listen und Onboarding. Humor nur über den Prozess, nie über Fakten
- **Marke:** "powered by HullQ" dezent, aber sichtbar (Startbildschirm, Menü "Mehr", Freischalten-Dialog)

Hell- und Dunkelmodus sind beide Pflicht (Dunkelmodus ist nachts an Bord wichtig).

## So mit Stitch arbeiten

1. Zuerst den globalen Stil-Prompt verwenden und einen Bildschirm erzeugen lassen (am besten 02 Vorratsliste, er prägt die App am stärksten).
2. Wenn der Stil passt, die weiteren Bildschirme einzeln im selben Projekt erzeugen, jeweils mit dem Zusatz "same design system as previous screens".
3. Ergebnisse als PNG exportieren und unter `docs/design/mockups/` ablegen; Abweichungen oder Entscheidungen im Changelog dieses Dokuments notieren.

Die Prompts sind auf Englisch (Stitch versteht Englisch am zuverlässigsten); die sichtbaren Texte in der App sind Deutsch.

## Globaler Stil-Prompt

```
Mobile app for Android, Material Design 3, clean and functional, calm and precise.
A provisioning and shared-expense planner for sailing trips (charter crews and boat owners).
Visual style: minimal technical-editorial (think Dieter Rams, Linear, Stripe), subtle maritime feel
through fine blueprint-like line work and a faint technical grid in empty states - NO anchors,
NO waves, NO compass roses, NO sail silhouettes, NO cartoon elements.
Colors: primary desaturated deep blueprint navy; accent petrol/teal-green for "done/confirmed";
warm amber/sand for hints and warnings (never red for warnings); muted greys for secondary info.
Never use color alone to convey meaning - always pair with an icon or label.
Typography: humanistic sans-serif for text; tabular figures (Inter or IBM Plex Sans style) for all
quantities and money amounts, right-aligned in lists.
Generous spacing, rounded Material 3 cards and bottom sheets, outlined line icons.
Bottom navigation with four tabs: "Liste", "Törn", "Bordkasse", "Mehr".
Small, understated "powered by HullQ" mark where specified.
All UI text in German. Provide light mode (and a dark mode variant if possible).
```

## Bildschirm-Prompts

### 01 Törn anlegen (Onboarding)

```
Screen: "Neuer Törn" - a short multi-step setup with a Material 3 stepper/progress indicator (step 3 of 4 shown).
Current step "Crew": list of crew members as compact cards (name, chips "Erwachsener/Kind", "vegetarisch",
"trinkt keinen Alkohol"), "+ Person hinzufügen" button.
Below, crew-level questions as segmented buttons:
"Wie isst eure Crew?" [eher leicht | ganz normal | gut und gern | hungrige Segler] (ganz normal selected),
"Wie viel wird an Bord getrunken?" [gemütlich | normal | feierfreudig],
a switch "Reserve für Ankertage und schlechtes Wetter (+10 %)".
A collapsed "Details" link for per-person settings. Primary button "Weiter". No bottom navigation on this flow.
```

### 02 Vorratsliste (Gesamtbedarf) – Kernbildschirm

```
Screen: tab "Liste", title "Vorratsliste", subtitle "Törn Kroatien · 5 Personen · 7 Tage".
Filter chips at top: "Nach Abteilung" (selected) / "Nach Kategorie", and a chip "Einkauf: Tag 1 (Basis)".
Sections by supermarket department (e.g. "Backwaren", "Molkerei und Kühlregal", "Obst und Gemüse").
Each row: product name, main value as purchasable packs in tabular figures (e.g. "3 × 500 g"),
small secondary line "Bedarf ca. 1,3 kg · +200 g Reserve", a compact - / + stepper,
optional small badges: "hält 1 Tag" (amber, with clock icon), "überschrieben" (with pencil icon),
"→ Tag 4" (assigned to a later shopping stop).
One row shows state "überschrieben" with a small "zurücksetzen" text button.
Floating action button "+ Eigene Position". Bottom navigation, "Liste" active.
```

### 03 Bedarfsgruppe mit Varianten (Bottom Sheet)

```
Screen: modal bottom sheet over the list, title "Brot und Backwaren", line "Bedarf: 120 g pro Person und Tag · gesamt ca. 4,2 kg".
List of variants with checkboxes: Vollkornbrot (750 g, hält 5 Tage), Baguette (250 g, hält 1 Tag),
Brötchen (60 g, hält 1 Tag), Knäckebrot (250 g, hält 90 Tage), Toastbrot, Wraps (unchecked).
Checked rows show share slider or percentage and resulting packs ("2 × 750 g").
Each row has a small "Packungsgröße ändern" action. Shelf-life shown as text + clock icon.
Footer: "Teilmenge einem Einkaufsstopp zuordnen" secondary button, primary "Übernehmen".
```

### 04 Einkaufsstopp (Einkaufsmodus)

```
Screen: title "Einkauf Tag 4 · Supermarkt Hvar", progress "12 von 18 erledigt" with a thin linear progress bar in petrol.
Checklist grouped by department, large tap targets, checked items struck through and dimmed with a petrol check icon.
Top right action "Einkauf als Ausgabe erfassen". Sticky bottom bar: "Fertig eingekauft".
```

### 05 Einlagerungs-Checkliste

```
Screen: title "Einlagern", info card in amber/sand with icon: "Kartons an Land auspacken - Ungeziefer reist in Wellpappe mit."
Checklist items with short hints: "Dosen: Etiketten entfernen, Inhalt auf den Deckel schreiben",
"Obst und Gemüse waschen und trocknen", "Kartoffeln trocken und dunkel, getrennt von Zwiebeln",
"Eier kühl lagern, regelmäßig wenden", "Fleisch sofort in den Kühlschrank".
Each item with outlined icon and checkbox. Calm, instructional, not alarming.
```

### 06 Törn (Tagesleiste und Einkaufsstopps)

```
Screen: tab "Törn". Horizontal or vertical day timeline "Tag 1 ... Tag 7".
Each day card: two compact toggle chips "Mittags Restaurant" and "Abends Restaurant",
optional small label for day type (e.g. "Ankerbucht") and port name, shown only if set, in grey.
Shopping stops appear as markers on their day ("Einkauf Tag 4 · Supermarkt Hvar") with a list icon.
Button "+ Einkaufsstopp". Summary line at top: "5 Bord-Abendessen · 4 Bord-Mittagessen".
Fine dashed line connecting the days like a course line on a technical chart (subtle).
```

### 07 Bordkasse (Übersicht)

```
Screen: tab "Bordkasse". Header card: model "Gemeinsame Bordkasse", balance "Kassenstand 312,40 €" in large tabular figures,
small line "Eingezahlt 1.000 € · Ausgegeben 687,60 €".
Segmented control: "Ausgaben" / "Personen".
Expense list with category icons (Proviant, Getränke, Hafen und Liegeplatz, Diesel, Charter und Kaution, Restaurant, Sonstiges),
amount right-aligned in tabular figures, "bezahlt aus Kasse" or "bezahlt von Anna".
A crew row shows chip "Skipper frei". FAB "+ Ausgabe".
```

### 08 Abschluss mit Überweisungs-QR

```
Screen: title "Törn abschließen". List "Wer zahlt wem": e.g. "Ben → Kasse 42,10 €", "Kasse → Clara 18,00 €",
minimal number of transfers. Selecting one opens a card with a large EPC/SEPA QR code ("GiroCode"),
recipient name, IBAN partly masked, amount, reference "Törn Kroatien".
Secondary actions: "PayPal-Link teilen", "Revolut-Link teilen". Note in small grey text:
"Die App wickelt keine Zahlungen ab." Primary button "Törn archivieren".
```

### 09 Freischalten mit HullQ-Login

```
Screen: modal bottom sheet "Weiteren Törn planen". Short explanation: "Mit einem kostenlosen HullQ-Konto planst du
unbegrenzt Törns und sicherst sie geräteübergreifend."
Buttons: "Mit Google fortfahren", "Mit Apple fortfahren", "Mit E-Mail fortfahren".
An UNCHECKED checkbox: "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden." (must be unchecked by default).
Links "Datenschutz" and "Nutzungsbedingungen". Small "powered by HullQ" mark at the bottom.
```

## Animationen (für Gemini/Flutter, nicht für Stitch)

Stitch erzeugt statische Entwürfe. Die Bewegung setzt Flutter um, sparsam und funktional:

- **Abhaken "rastet ein":** kurzes, gedämpftes Einrasten des Häkchens (Feder-Kurve), Zeile gleitet leicht nach unten in "erledigt"
- **Mengenänderung:** Zahlen zählen kurz hoch oder runter (AnimatedSwitcher / implizite Animation), keine Sprünge
- **Listen:** AnimatedList für Hinzufügen, Entfernen und Verschieben zu einem Einkaufsstopp
- **Ladezustand:** ruhige, sich ausbreitende Ringe (Sonar-Anmutung) statt Standard-Spinner, passend zur HullQ-Signatur
- **Übergänge:** Material-3-Container-Transform von Listenzeile zu Bottom Sheet; Hero für Törn-Karte
- **Leere Zustände:** feine Linienzeichnung mit gestrichelter Linie, die sich beim Erscheinen nachzeichnet
- Alle Animationen kurz (150–300 ms) und bei "Bewegung reduzieren" in den Systemeinstellungen abschaltbar

## Offene Punkte

- [ ] App-Name festlegen (in den Prompts vorerst ohne Namen)
- [x] Mockups erzeugen und ablegen
- [x] Stilentscheidungen festhalten: `technical_maritime_m3/DESIGN.md` als Theme-Grundlage
- [ ] Optional: Bildschirme 04, 06 und 09 mit den Regeln neu in Stitch erzeugen
