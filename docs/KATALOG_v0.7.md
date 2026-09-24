# Vorratskatalog v0.7

Stand: 23.09.2026 · maschinenlesbar in `data/catalog_v0.7.json`

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 10 Kategorien, 71 Positionen |
| v0.2 | 23.09.2026 | Konsumprofile und Einlagerungs-Hinweise |
| v0.3 | 23.09.2026 | Neues Schema Kategorie → Bedarfsgruppe → Variante; Kategorie Frühstück umgestellt |
| v0.4 | 23.09.2026 | Alle 10 Kategorien im neuen Schema (47 Gruppen, 212 Varianten); Technik mit Sichtbarkeit (Alltag auch beim Charter, Motor/Elektrik/Rigg/Reparatur/Sanitär nur eigenes Boot) und Prüflisten-Modus; Bordapotheke als Prüfliste |
| v0.5 | 23.09.2026 | Neue Rechenbasis pro Mittagessen an Bord; Gemüse und Salat für Mittag rechnet pro Bord-Mittagessen (150 g), damit Mittags-Restaurant den Bedarf senkt |
| v0.6 | 23.09.2026 | Zucker vorläufig auf 250 g pro Crew und Woche gesenkt; alle geschätzten Mengen als vorläufig markiert, Baseline folgt später |
| v0.7 | 24.09.2026 | Review S2: Einheiten vereinheitlicht (Bedarf in Packungseinheit, umrechenbar oder 'Packung' = Anzahl Packungen), Bier 0,5 l pro Abend, Zwiebeln und Zitronen in Gramm; keine automatische Verteilung von Frischem; erlaubte applies_to-Werte festgelegt |

## Status

**Mengen vorläufig:** Werte mit Quelle `estimate` sind Platzhalter bis zur Baseline. Maßgeblich für die App ist `data/catalog_v0.7.json`.

## Regeln

- **Einheiten:** Die Bedarfseinheit entspricht der Packungseinheit, ist umrechenbar (g/kg, ml/l) oder lautet `Packung` (= Anzahl Packungen). `Portion` nur mit Portionsgröße an der Variante.
- **Zielgruppen (`applies_to`):** nur `all`, `non_vegetarian`, `vegetarian`, `adults`.
- **Frisches:** Die App verteilt Frisches nicht automatisch auf spätere Einkäufe; Haltbarkeit ist ein Hinweis an der Variante. Einkaufsstopps und Zuordnung legt der Nutzer fest.
- **split:** `equal` verteilt den Gruppenbedarf auf die gewählten Varianten; `each` gibt jeder Variante ihren eigenen Bedarf (sonst Gruppenbedarf je Variante).
- **Sichtbarkeit:** `all` immer, `owner` nur beim eigenen Boot. **Modus:** `quantity` oder `check` (Prüfliste).

## Rechenbasen

| Basis | Bedeutung |
| --- | --- |
| `per_person_day` | pro Person und Tag |
| `per_person_day_region` | pro Person und Tag, je nach Revier |
| `per_person_week` | pro Person und Woche (anteilig bei anderen Törnlängen) |
| `per_person_board_evening` | pro Person und Abendessen an Bord |
| `per_adult_evening` | pro erwachsener Person und Abend |
| `per_crew_week` | pro Crew und Woche (angefangene Woche zählt voll) |
| `per_trip` | einmal pro Törn |
| `per_person_trip` | einmal pro Person und Törn |
| `check` | Checkliste, keine Mengenberechnung |
| `per_person_board_lunch` | pro Person und Mittagessen an Bord |

## Frühstück

### Brot und Backwaren

Bedarf: **120 g pro Person und Tag** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Vollkornbrot | 750 g | – | 5 Tage | ja | Backwaren | – |
| Weißbrot / Bauernbrot | 750 g | – | 3 Tage | – | Backwaren | – |
| Baguette | 250 g | – | 1 Tage | ja | Backwaren | frisch in jedem Hafen nachkaufen |
| Brötchen | 60 g | – | 1 Tage | ja | Backwaren | frisch nachkaufen |
| Vollkornbrötchen | 70 g | – | 1 Tage | – | Backwaren | frisch nachkaufen |
| Aufbackbrötchen | 300 g | – | 21 Tage | – | Backwaren | nur mit Backofen an Bord |
| Toastbrot | 500 g | – | 7 Tage | – | Backwaren | – |
| Knäckebrot | 250 g | – | 90 Tage | ja | Backwaren | Reserve für Ankertage |
| Wraps / Tortillas | 320 g | – | 14 Tage | – | Backwaren | – |

### Butter und Streichfett

Bedarf: **125 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Butter | 250 g | – | 21 Tage | ja | Molkerei und Kühlregal | – |
| Gesalzene Butter | 250 g | – | 30 Tage | – | Molkerei und Kühlregal | hält ungekühlt länger |
| Margarine / veganes Streichfett | 250 g | – | 30 Tage | – | Molkerei und Kühlregal | – |

### Süße Aufstriche

Bedarf: **150 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Marmelade Erdbeere | 340 g | – | 60 Tage | ja | Trockenware | – |
| Marmelade Aprikose | 340 g | – | 60 Tage | – | Trockenware | – |
| Honig | 500 g | – | 365 Tage | ja | Trockenware | – |
| Nuss-Nougat-Creme | 400 g | – | 180 Tage | ja | Trockenware | – |
| Erdnussbutter | 350 g | – | 180 Tage | – | Trockenware | – |

### Herzhafte Aufstriche

Bedarf: **100 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Frischkäse | 200 g | – | 14 Tage | ja | Molkerei und Kühlregal | – |
| Hummus | 200 g | – | 7 Tage | – | Molkerei und Kühlregal | – |
| Streichwurst / Leberwurst | 125 g | – | 14 Tage | – | Fleisch und Fisch | nur nicht vegetarisch |

### Käse

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Gouda / Butterkäse in Scheiben | 200 g | – | 14 Tage | ja | Molkerei und Kühlregal | – |
| Emmentaler / Bergkäse | 200 g | – | 21 Tage | – | Molkerei und Kühlregal | – |
| Brie / Camembert | 200 g | – | 10 Tage | – | Molkerei und Kühlregal | – |
| Feta | 200 g | – | 21 Tage | ja | Molkerei und Kühlregal | – |
| Mozzarella | 125 g | – | 7 Tage | – | Molkerei und Kühlregal | – |
| Parmesan / Hartkäse am Stück | 200 g | – | 60 Tage | ja | Molkerei und Kühlregal | hält auch ungekühlt lange |

### Wurst und Aufschnitt

Bedarf: **200 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: nicht vegetarische Crewmitglieder · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Salami | 200 g | – | 30 Tage | ja | Fleisch und Fisch | luftgetrocknet, gut haltbar |
| Kochschinken | 150 g | – | 7 Tage | ja | Fleisch und Fisch | – |
| Rohschinken | 100 g | – | 21 Tage | – | Fleisch und Fisch | – |
| Putenbrust | 150 g | – | 7 Tage | – | Fleisch und Fisch | – |

### Eier

Bedarf: **12 Stück pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Eier (10er) | 10 Stück | – | 21 Tage | ja | Molkerei und Kühlregal | – |

### Milch und Alternativen

Bedarf: **0,5 l pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Frischmilch | 1 l | – | 5 Tage | – | Molkerei und Kühlregal | – |
| H-Milch | 1 l | – | 90 Tage | ja | Molkerei und Kühlregal | an Bord meist die bessere Wahl |
| Haferdrink | 1 l | – | 90 Tage | – | Molkerei und Kühlregal | – |
| Sojadrink | 1 l | – | 90 Tage | – | Molkerei und Kühlregal | – |

### Joghurt und Quark

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Naturjoghurt | 500 g | – | 14 Tage | ja | Molkerei und Kühlregal | – |
| Fruchtjoghurt | 150 g | – | 14 Tage | – | Molkerei und Kühlregal | – |
| Skyr / Quark | 500 g | – | 14 Tage | – | Molkerei und Kühlregal | – |

### Müsli und Cerealien

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Müsli | 750 g | – | 180 Tage | ja | Trockenware | – |
| Haferflocken | 500 g | – | 180 Tage | – | Trockenware | – |
| Cornflakes | 375 g | – | 180 Tage | – | Trockenware | – |
| Granola / Knuspermüsli | 500 g | – | 180 Tage | – | Trockenware | – |

## Grundnahrung

### Sättigungsbeilagen

Bedarf: **1 Portion pro Person und Abendessen an Bord** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Spaghetti | 500 g | 130 g je Portion | 365 Tage | ja | Trockenware | – |
| Penne / Fusilli | 500 g | 130 g je Portion | 365 Tage | ja | Trockenware | – |
| Reis | 1000 g | 70 g je Portion | 365 Tage | ja | Trockenware | – |
| Kartoffeln | 2000 g | 225 g je Portion | 21 Tage | ja | Obst und Gemüse | – |
| Couscous / Bulgur | 500 g | 70 g je Portion | 365 Tage | – | Trockenware | kocht mit wenig Wasser und Gas |
| Gnocchi | 500 g | 200 g je Portion | 60 Tage | – | Trockenware | – |
| Tortellini / Ravioli frisch | 250 g | 125 g je Portion | 14 Tage | – | Molkerei und Kühlregal | – |

### Tomatenprodukte und Pastasaucen

Bedarf: **100 g pro Person und Abendessen an Bord** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Passierte Tomaten | 500 g | – | 365 Tage | ja | Konserven | – |
| Gehackte Tomaten (Dose) | 400 g | – | 730 Tage | ja | Konserven | – |
| Fertigsauce im Glas | 400 g | – | 365 Tage | – | Konserven | – |
| Pesto | 190 g | – | 365 Tage | ja | Konserven | – |
| Tomatenmark | 200 g | – | 365 Tage | – | Konserven | – |

### Konserven

Bedarf: **2 Packung pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Thunfisch | 160 g | – | 1095 Tage | ja | Konserven | – |
| Mais | 340 g | – | 1095 Tage | ja | Konserven | – |
| Kidneybohnen | 400 g | – | 1095 Tage | – | Konserven | – |
| Kichererbsen | 400 g | – | 1095 Tage | ja | Konserven | – |
| Linsen | 400 g | – | 1095 Tage | – | Konserven | – |
| Oliven | 300 g | – | 365 Tage | ja | Konserven | – |
| Ravioli / Eintopf (Dose) | 800 g | – | 1095 Tage | – | Konserven | Notreserve bei schlechtem Wetter |

### Suppen und Brühe

Bedarf: **1 Packung pro Crew und Woche (angefangene Woche zählt voll)** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Gemüsebrühe | 100 g | – | 365 Tage | ja | Trockenware | – |
| Instantsuppe / Tütensuppe | 4 Beutel | – | 365 Tage | ja | Trockenware | warm auf Nachtfahrten |
| Instant-Nudelsuppe | 5 Beutel | – | 365 Tage | – | Trockenware | – |
| Mehl | 1000 g | 1 Packung einmal pro Törn | 365 Tage | – | Trockenware | – |

## Saucen und Würzen

### Öl und Essig

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Olivenöl | 1 l | 1 l pro Crew und Woche (angefangene Woche zählt voll) | 365 Tage | ja | Trockenware | – |
| Sonnenblumenöl | 1 l | 1 l einmal pro Törn | 365 Tage | – | Trockenware | – |
| Balsamico | 0,5 l | 1 Packung einmal pro Törn | 730 Tage | ja | Trockenware | – |
| Weißweinessig | 0,75 l | 1 Packung einmal pro Törn | 730 Tage | – | Trockenware | – |

### Grundwürzen

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Salz | 500 g | 1 Packung einmal pro Törn | unbegrenzt | ja | Trockenware | – |
| Pfeffer | 50 g | 1 Packung einmal pro Törn | 730 Tage | ja | Trockenware | – |
| Zucker | 500 g | 250 g pro Crew und Woche (angefangene Woche zählt voll) | unbegrenzt | ja | Trockenware | vorläufig, zu hoch eingeschätzt; Baseline offen |

### Kräuter und Gewürze

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Oregano | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | ja | Trockenware | – |
| Paprika edelsüß | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | ja | Trockenware | – |
| Curry | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |
| Chili / Cayenne | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |
| Italienische Kräuter | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | ja | Trockenware | – |
| Knoblauchpulver | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |
| Muskat | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |
| Zimt | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |

### Saucen

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Sojasauce | 250 ml | 1 Packung einmal pro Törn | 730 Tage | ja | Trockenware | – |
| Ketchup | 500 ml | 1 Packung pro Crew und Woche (angefangene Woche zählt voll) | 365 Tage | ja | Trockenware | – |
| Senf | 200 ml | 1 Packung einmal pro Törn | 365 Tage | ja | Trockenware | – |
| Mayonnaise | 250 ml | 1 Packung pro Crew und Woche (angefangene Woche zählt voll) | 180 Tage | ja | Trockenware | – |
| Grillsauce | 500 ml | 1 Packung einmal pro Törn | 365 Tage | – | Trockenware | – |
| Sweet-Chili-Sauce | 300 ml | 1 Packung einmal pro Törn | 365 Tage | – | Trockenware | – |
| Tabasco / scharfe Sauce | 60 ml | 1 Packung einmal pro Törn | 730 Tage | – | Trockenware | – |

## Frisches

### Obst

Bedarf: **1,5 kg pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Äpfel | 1 kg | – | 21 Tage | ja | Obst und Gemüse | halten lange |
| Bananen | 1 kg | – | 4 Tage | ja | Obst und Gemüse | nicht eine ganze Staude: reifen alle am selben Tag |
| Orangen / Mandarinen | 1,5 kg | – | 21 Tage | ja | Obst und Gemüse | – |
| Trauben | 0,5 kg | – | 5 Tage | – | Obst und Gemüse | – |
| Melone | 1,5 kg | – | 7 Tage | – | Obst und Gemüse | – |
| Nektarinen / Pfirsiche | 1 kg | – | 5 Tage | – | Obst und Gemüse | – |

### Gemüse und Salat für Mittag

Bedarf: **150 g pro Person und Mittagessen an Bord** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Tomaten | 0,5 kg | – | 7 Tage | ja | Obst und Gemüse | grüne und rote mischen, reifen gestaffelt |
| Gurke | 0,4 kg | – | 7 Tage | ja | Obst und Gemüse | – |
| Paprika | 0,5 kg | – | 10 Tage | ja | Obst und Gemüse | – |
| Kopfsalat / Eisbergsalat | 0,3 kg | – | 3 Tage | – | Obst und Gemüse | Eisberg hält länger |
| Karotten | 1 kg | – | 21 Tage | ja | Obst und Gemüse | – |
| Radieschen | 0,15 kg | – | 5 Tage | – | Obst und Gemüse | – |

### Gemüse für Bordabende

Bedarf: **175 g pro Person und Abendessen an Bord** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Zucchini | 500 g | – | 7 Tage | ja | Obst und Gemüse | – |
| Aubergine | 400 g | – | 7 Tage | – | Obst und Gemüse | – |
| Brokkoli | 500 g | – | 4 Tage | – | Obst und Gemüse | – |
| Champignons | 250 g | – | 4 Tage | ja | Obst und Gemüse | – |
| Grüne Bohnen | 500 g | – | 5 Tage | – | Obst und Gemüse | – |

### Zwiebeln, Knoblauch, Zitronen

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Zwiebeln | 1000 g | 60 g pro Person und Abendessen an Bord | 30 Tage | ja | Obst und Gemüse | – |
| Knoblauch | 1 Knolle | 1 Knolle pro Crew und Woche (angefangene Woche zählt voll) | 30 Tage | ja | Obst und Gemüse | – |
| Zitronen | 500 g | 50 g pro Person und Woche (anteilig bei anderen Törnlängen) | 21 Tage | ja | Obst und Gemüse | – |
| Ingwer | 100 g | 1 Packung einmal pro Törn | 21 Tage | – | Obst und Gemüse | auch gegen Seekrankheit beliebt |

### Fleisch und Fisch für Bordabende

Bedarf: **175 g pro Person und Abendessen an Bord** · gilt für: nicht vegetarische Crewmitglieder · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Hähnchenbrust / -schenkel | 400 g | – | 3 Tage | ja | Fleisch und Fisch | – |
| Hackfleisch | 500 g | – | 2 Tage | ja | Fleisch und Fisch | – |
| Steak / Rind | 300 g | – | 3 Tage | – | Fleisch und Fisch | – |
| Schweinekotelett / -filet | 500 g | – | 3 Tage | – | Fleisch und Fisch | – |
| Bratwurst / Grillwurst | 400 g | – | 5 Tage | ja | Fleisch und Fisch | – |
| Chorizo / luftgetrocknete Wurst | 200 g | – | 30 Tage | ja | Fleisch und Fisch | Reserve, hält ungekühlt |
| Fischfilet | 300 g | – | 2 Tage | – | Fleisch und Fisch | frisch im Hafen kaufen |
| Garnelen (TK) | 400 g | – | 1 Tage | – | Fleisch und Fisch | nur mit Tiefkühlfach |

### Vegetarische Hauptkomponente

Bedarf: **150 g pro Person und Abendessen an Bord** · gilt für: vegetarische Crewmitglieder · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Halloumi | 250 g | – | 30 Tage | ja | Molkerei und Kühlregal | – |
| Tofu | 400 g | – | 14 Tage | ja | Molkerei und Kühlregal | – |
| Falafel | 300 g | – | 7 Tage | – | Molkerei und Kühlregal | – |
| Veggie-Burger / -Würstchen | 226 g | – | 14 Tage | – | Molkerei und Kühlregal | – |

## Süßes und Snacks

### Süßes

Bedarf: **300 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Schokolade | 100 g | – | 365 Tage | ja | Süßwaren | schmilzt im Sommer: kühl lagern |
| Kekse | 200 g | – | 180 Tage | ja | Süßwaren | – |
| Gummibärchen / Fruchtgummi | 200 g | – | 365 Tage | ja | Süßwaren | – |
| Müsliriegel | 150 g | – | 180 Tage | – | Süßwaren | gut für Nachtwachen |

### Salzige Snacks

Bedarf: **300 g pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Chips | 175 g | – | 120 Tage | ja | Süßwaren | – |
| Nüsse / Studentenfutter | 200 g | – | 180 Tage | ja | Süßwaren | – |
| Salzstangen / Brezeln | 250 g | – | 180 Tage | ja | Süßwaren | – |
| Cracker | 200 g | – | 180 Tage | – | Süßwaren | – |

## Getränke ohne Alkohol

### Trinkwasser

Bedarf: **je Variante** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Wasser 5-l-Kanister | 5 l | – | 365 Tage | ja | Getränke | platzsparend, weniger Plastik |
| Wasser 1,5-l-Flaschen | 1,5 l | – | 365 Tage | ja | Getränke | handlich für unterwegs |
| Mineralwasser mit Kohlensäure | 1,5 l | – | 365 Tage | – | Getränke | – |

### Softdrinks

Bedarf: **0,5 l pro Person und Tag** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Cola | 1,5 l | – | 180 Tage | ja | Getränke | – |
| Zitronenlimonade | 1,5 l | – | 180 Tage | ja | Getränke | – |
| Eistee | 1,5 l | – | 180 Tage | – | Getränke | – |
| Tonic Water | 1 l | – | 180 Tage | – | Getränke | auch als Longdrink-Mixer |

### Säfte

Bedarf: **1 l pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Orangensaft | 1 l | – | 180 Tage | ja | Getränke | – |
| Apfelsaft | 1 l | – | 180 Tage | – | Getränke | – |
| Multivitaminsaft | 1 l | – | 180 Tage | – | Getränke | – |

### Kaffee

Bedarf: **15 g pro Person und Tag** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Kaffee gemahlen | 500 g | – | 180 Tage | ja | Trockenware | für Espressokocher oder Filter |
| Instantkaffee | 200 g | – | 365 Tage | – | Trockenware | schnell bei Seegang |

### Tee

Bedarf: **2 Beutel pro Person und Tag** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Schwarztee | 25 Beutel | – | 730 Tage | ja | Trockenware | – |
| Kräutertee / Pfefferminz | 20 Beutel | – | 730 Tage | ja | Trockenware | – |
| Früchtetee | 20 Beutel | – | 730 Tage | – | Trockenware | – |

### Kaffeemilch

Bedarf: **0,5 l pro Person und Woche (anteilig bei anderen Törnlängen)** · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| H-Milch für Kaffee | 1 l | – | 90 Tage | ja | Molkerei und Kühlregal | – |
| Kondensmilch | 0,34 l | – | 365 Tage | – | Molkerei und Kühlregal | – |

## Getränke mit Alkohol

### Bier

Bedarf: **0,5 l pro erwachsener Person und Abend** · gilt für: Erwachsene · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Bier Dose 0,5 l | 0,5 l | – | 180 Tage | ja | Getränke | Dosen brechen nicht |
| Bier Flasche 0,33 l | 0,33 l | – | 180 Tage | – | Getränke | – |
| Lokales Bier | 0,5 l | – | 180 Tage | – | Getränke | – |

### Wein und Sekt

Bedarf: **0,25 l pro erwachsener Person und Abend** · gilt für: Erwachsene · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Weißwein | 0,75 l | – | 365 Tage | ja | Getränke | – |
| Rotwein | 0,75 l | – | 365 Tage | ja | Getränke | – |
| Rosé | 0,75 l | – | 365 Tage | – | Getränke | – |
| Sekt / Prosecco | 0,75 l | – | 365 Tage | – | Getränke | – |
| Wein im Karton (Bag-in-Box) | 3 l | – | 180 Tage | – | Getränke | bruchsicher und platzsparend |

### Spirituosen und Aperitif

Bedarf: **je Variante** · gilt für: Erwachsene · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Rum | 0,7 l | 1 Packung einmal pro Törn | unbegrenzt | – | Getränke | – |
| Gin | 0,7 l | 1 Packung einmal pro Törn | unbegrenzt | – | Getränke | – |
| Aperol / Aperitif | 0,7 l | 1 Packung einmal pro Törn | unbegrenzt | – | Getränke | – |
| Lokale Spezialität (Ouzo, Rakija …) | 0,7 l | 1 Packung einmal pro Törn | unbegrenzt | – | Getränke | – |

## Haushalt

### Küche und Abwasch

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Spülmittel | 0,5 l | 1 Packung pro Crew und Woche (angefangene Woche zählt voll) | unbegrenzt | ja | Haushalt | – |
| Schwämme | 3 Stück | 2 Stück pro Crew und Woche (angefangene Woche zählt voll) | unbegrenzt | ja | Haushalt | – |
| Geschirrtücher | 2 Stück | 2 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | – |
| Küchenrolle | 2 Rollen | 0,5 Rollen pro Person und Woche (anteilig bei anderen Törnlängen) | unbegrenzt | ja | Haushalt | – |
| Allzweckreiniger | 0,5 l | 1 Packung einmal pro Törn | unbegrenzt | ja | Haushalt | – |

### Verpacken und Aufbewahren

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Müllsäcke | 20 Stück | 1 Packung einmal pro Törn | unbegrenzt | ja | Haushalt | – |
| Alufolie | 1 Rollen | 1 Rollen einmal pro Törn | unbegrenzt | ja | Haushalt | – |
| Frischhaltefolie | 1 Rollen | 1 Rollen einmal pro Törn | unbegrenzt | – | Haushalt | – |
| Gefrier- / Zipbeutel | 20 Stück | 1 Packung einmal pro Törn | unbegrenzt | ja | Haushalt | für umgefüllte Lebensmittel und nasse Sachen |
| Wasserfester Stift | 1 Stück | 1 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | für Dosen ohne Etikett |
| Wäscheklammern | 20 Stück | 20 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | – |

### Feuer und Grill

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Streichhölzer | 1 Packung | 1 Packung einmal pro Törn | unbegrenzt | ja | Haushalt | für den Gasherd |
| Gasfeuerzeug (Stabfeuerzeug) | 1 Stück | 1 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | – |
| Grillkohle | 3 kg | 1 Packung einmal pro Törn | unbegrenzt | – | Haushalt | nur wenn Grill an Bord |

## Hygiene

### Hygiene und Pflege

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Toilettenpapier (bordtauglich, schnell auflösend) | 8 Rollen | 2 Rollen pro Person und Woche (anteilig bei anderen Törnlängen) | unbegrenzt | ja | Drogerie | Bordtoiletten verstopfen leicht; Hinweis der Basis beachten |
| Handseife | 0,3 l | 1 Packung einmal pro Törn | unbegrenzt | ja | Drogerie | – |
| Duschgel (biologisch abbaubar) | 0,25 l | 0,25 Packung pro Person und Woche (anteilig bei anderen Törnlängen) | unbegrenzt | ja | Drogerie | – |
| Shampoo | 0,25 l | 1 Packung einmal pro Törn | unbegrenzt | – | Drogerie | – |
| Feuchttücher | 60 Stück | 1 Packung einmal pro Törn | unbegrenzt | ja | Drogerie | – |

### Sonne und Insekten

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Sonnencreme | 200 ml | 100 ml pro Person und Woche (anteilig bei anderen Törnlängen) | 730 Tage | ja | Drogerie | – |
| After-Sun | 200 ml | 1 Packung einmal pro Törn | 730 Tage | – | Drogerie | – |
| Mückenschutz | 100 ml | 1 Packung einmal pro Törn | 730 Tage | ja | Drogerie | – |

### Bordapotheke prüfen

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Pflaster und Wundversorgung | 1 Set | 1 Set Checkliste, keine Mengenberechnung | unbegrenzt | ja | Apotheke / Drogerie | – |
| Schmerzmittel | 1 Packung | 1 Packung Checkliste, keine Mengenberechnung | unbegrenzt | ja | Apotheke / Drogerie | – |
| Mittel gegen Seekrankheit | 1 Packung | 1 Packung Checkliste, keine Mengenberechnung | unbegrenzt | ja | Apotheke / Drogerie | – |

## Bord und Technik

### Alltag an Bord

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Batterien AA | 8 Stück | 8 Stück einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | Stirnlampen, Handfunkgerät |
| Batterien AAA | 8 Stück | 8 Stück einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | – |
| Stirnlampe | 1 Stück | 1 Stück einmal pro Person und Törn | unbegrenzt | ja | Technik / Bootszubehör | prüfen, ob jeder eine hat |
| Powerbank | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| 12-V-USB-Adapter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | für Handys am Bordnetz |
| Gewebeband | 1 Rollen | 1 Rollen einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | – |
| Kabelbinder | 1 Packung | 1 Packung einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | – |

### Motor

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Motoröl | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Ölfilter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Dieselfilter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Impeller | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Keilriemen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Kühlmittel | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Fett | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |

### Elektrik

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Ersatzsicherungen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Ersatzlampen / LED | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Kabelschuhe | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Isolierband | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Multimeter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |

### Rigg und Deck

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Schäkel | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Takelgarn | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Ersatzleinen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Segelreparaturband | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |

### Reparatur allgemein

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Kriechöl (z. B. WD-40) | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Dichtmasse | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Schlauchschellen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Epoxid-Knetmasse | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |

### Wasser und Sanitär

Bedarf: **je Variante** · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Ersatzdichtungen Pumpe / Toilette | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Bordtauglicher Toilettenreiniger | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
| Tankreiniger | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |
