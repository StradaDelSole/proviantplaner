# Design-Brief und Stitch-Prompts v0.1

Stand: 23.09.2026 · Grundlage: `docs/PRD_v0.14.md` · Mockups ablegen unter `docs/design/mockups/` (Dateiname `NN_bildschirm_v0.1.png`)

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: Stilrichtung aus HullQ-CI abgeleitet, globaler Stil-Prompt, 9 Bildschirm-Prompts, Animationshinweise für Flutter |

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
- [ ] Mockups erzeugen und ablegen
- [ ] Nach den Mockups: Stilentscheidungen hier festhalten (Farbwerte, Schriften, Radien) als Grundlage für das Flutter-Theme
