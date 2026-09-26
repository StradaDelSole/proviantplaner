# Vorratskatalog v0.10

Stand: 23.09.2026 · maschinenlesbar in `data/catalog_v0.10.json`

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
| v0.8 | 25.09.2026 | Wasser mit need-Feld |
| v0.9 | 26.09.2026 | Revier → kühl/warm/heiß; alle Varianten wählbar |
| v0.10 | 26.09.2026 | Feedback-Runde 2: Feld chill (none/fridge/freezer), shelf_life_frozen_days, 20 Langfahrt- und Tiefkühlvarianten (Pumpernickel, Weißkohl, Kürbis, Konserven, TK-Fleisch/Fisch/Gemüse, Trockenobst, H-Sahne u. a.) |

## Status

Mengen vorläufig (Quelle `estimate`). Maßgeblich ist `data/catalog_v0.10.json`.

## Regeln

- **Einheiten:** Bedarfseinheit = Packungseinheit, umrechenbar (g/kg, ml/l) oder `Packung`.
- **Lagerung (`chill`):** `none` ungekühlt, `fridge` braucht Kühlschrank, `freezer` nur mit Tiefkühlfach vorschlagen.
- **Haltbarkeit:** Vorschlag je Variante höchstens bis zum Ende ihrer Haltbarkeit an Bord bzw. bis zum nächsten Einkaufsstopp; mit Tiefkühlfach gilt für einfrierbare Ware `shelf_life_frozen_days`.
- **Alle Varianten sind wählbar;** `default_selected` bestimmt nur "Alle Vorschläge übernehmen".

## Frühstück

### Brot und Backwaren

Bedarf: **120 g pro Person und Tag** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Vollkornbrot | 750 g | 5 Tage | 30 Tage | – | ja | Backwaren |
| Weißbrot / Bauernbrot | 750 g | 3 Tage | 30 Tage | – | – | Backwaren |
| Baguette | 250 g | 1 Tage | 30 Tage | – | ja | Backwaren |
| Brötchen | 60 g | 1 Tage | 30 Tage | – | ja | Backwaren |
| Vollkornbrötchen | 70 g | 1 Tage | 30 Tage | – | – | Backwaren |
| Aufbackbrötchen | 300 g | 21 Tage | – | – | – | Backwaren |
| Toastbrot | 500 g | 7 Tage | – | – | – | Backwaren |
| Knäckebrot | 250 g | 90 Tage | – | – | ja | Backwaren |
| Wraps / Tortillas | 320 g | 14 Tage | – | – | – | Backwaren |
| Pumpernickel | 500 g | 90 Tage | – | – | – | Backwaren |
| Schnittbrot, lange haltbar (in Folie) | 500 g | 60 Tage | – | – | – | Backwaren |

### Butter und Streichfett

Bedarf: **125 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Butter | 250 g | 21 Tage | – | Kühlschrank | ja | Molkerei und Kühlregal |
| Gesalzene Butter | 250 g | 30 Tage | – | – | – | Molkerei und Kühlregal |
| Margarine / veganes Streichfett | 250 g | 30 Tage | – | – | – | Molkerei und Kühlregal |

### Süße Aufstriche

Bedarf: **150 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Marmelade Erdbeere | 340 g | 60 Tage | – | – | ja | Trockenware |
| Marmelade Aprikose | 340 g | 60 Tage | – | – | – | Trockenware |
| Honig | 500 g | 365 Tage | – | – | ja | Trockenware |
| Nuss-Nougat-Creme | 400 g | 180 Tage | – | – | ja | Trockenware |
| Erdnussbutter | 350 g | 180 Tage | – | – | – | Trockenware |

### Herzhafte Aufstriche

Bedarf: **100 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Frischkäse | 200 g | 14 Tage | – | Kühlschrank | ja | Molkerei und Kühlregal |
| Hummus | 200 g | 7 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |
| Streichwurst / Leberwurst | 125 g | 14 Tage | – | Kühlschrank | – | Fleisch und Fisch |

### Käse

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Gouda / Butterkäse in Scheiben | 200 g | 14 Tage | – | Kühlschrank | ja | Molkerei und Kühlregal |
| Emmentaler / Bergkäse | 200 g | 21 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |
| Brie / Camembert | 200 g | 10 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |
| Feta | 200 g | 21 Tage | – | Kühlschrank | ja | Molkerei und Kühlregal |
| Mozzarella | 125 g | 7 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |
| Parmesan / Hartkäse am Stück | 200 g | 60 Tage | – | – | ja | Molkerei und Kühlregal |

### Wurst und Aufschnitt

Bedarf: **200 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Salami | 200 g | 30 Tage | – | – | ja | Fleisch und Fisch |
| Kochschinken | 150 g | 7 Tage | – | Kühlschrank | ja | Fleisch und Fisch |
| Rohschinken | 100 g | 21 Tage | – | Kühlschrank | – | Fleisch und Fisch |
| Putenbrust | 150 g | 7 Tage | – | Kühlschrank | – | Fleisch und Fisch |

### Eier

Bedarf: **12 Stück pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Eier (10er) | 10 Stück | 21 Tage | – | – | ja | Molkerei und Kühlregal |

### Milch und Alternativen

Bedarf: **0,5 l pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Frischmilch | 1 l | 5 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |
| H-Milch | 1 l | 90 Tage | – | – | ja | Molkerei und Kühlregal |
| Haferdrink | 1 l | 90 Tage | – | – | – | Molkerei und Kühlregal |
| Sojadrink | 1 l | 90 Tage | – | – | – | Molkerei und Kühlregal |
| H-Sahne | 200 ml | 180 Tage | – | – | – | Molkerei und Kühlregal |

### Joghurt und Quark

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Naturjoghurt | 500 g | 14 Tage | – | Kühlschrank | ja | Molkerei und Kühlregal |
| Fruchtjoghurt | 150 g | 14 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |
| Skyr / Quark | 500 g | 14 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |

### Müsli und Cerealien

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Müsli | 750 g | 180 Tage | – | – | ja | Trockenware |
| Haferflocken | 500 g | 180 Tage | – | – | – | Trockenware |
| Cornflakes | 375 g | 180 Tage | – | – | – | Trockenware |
| Granola / Knuspermüsli | 500 g | 180 Tage | – | – | – | Trockenware |

## Grundnahrung

### Sättigungsbeilagen

Bedarf: **1 Portion pro Person und Abendessen an Bord** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Spaghetti | 500 g | 365 Tage | – | – | ja | Trockenware |
| Penne / Fusilli | 500 g | 365 Tage | – | – | ja | Trockenware |
| Reis | 1000 g | 365 Tage | – | – | ja | Trockenware |
| Kartoffeln | 2000 g | 21 Tage | – | – | ja | Obst und Gemüse |
| Couscous / Bulgur | 500 g | 365 Tage | – | – | – | Trockenware |
| Gnocchi | 500 g | 60 Tage | – | – | – | Trockenware |
| Tortellini / Ravioli frisch | 250 g | 14 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |

### Tomatenprodukte und Pastasaucen

Bedarf: **100 g pro Person und Abendessen an Bord** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Passierte Tomaten | 500 g | 365 Tage | – | – | ja | Konserven |
| Gehackte Tomaten (Dose) | 400 g | 730 Tage | – | – | ja | Konserven |
| Fertigsauce im Glas | 400 g | 365 Tage | – | – | – | Konserven |
| Pesto | 190 g | 365 Tage | – | – | ja | Konserven |
| Tomatenmark | 200 g | 365 Tage | – | – | – | Konserven |

### Konserven

Bedarf: **2 Packung pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Thunfisch | 160 g | 1095 Tage | – | – | ja | Konserven |
| Mais | 340 g | 1095 Tage | – | – | ja | Konserven |
| Kidneybohnen | 400 g | 1095 Tage | – | – | – | Konserven |
| Kichererbsen | 400 g | 1095 Tage | – | – | ja | Konserven |
| Linsen | 400 g | 1095 Tage | – | – | – | Konserven |
| Oliven | 300 g | 365 Tage | – | – | ja | Konserven |
| Ravioli / Eintopf (Dose) | 800 g | 1095 Tage | – | – | – | Konserven |

### Suppen und Brühe

Bedarf: **1 Packung pro Crew und Woche (angefangene Woche zählt voll)** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Gemüsebrühe | 100 g | 365 Tage | – | – | ja | Trockenware |
| Instantsuppe / Tütensuppe | 4 Beutel | 365 Tage | – | – | ja | Trockenware |
| Instant-Nudelsuppe | 5 Beutel | 365 Tage | – | – | – | Trockenware |
| Mehl | 1000 g | 365 Tage | – | – | – | Trockenware |

## Saucen und Würzen

### Öl und Essig

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Olivenöl | 1 l | 365 Tage | – | – | ja | Trockenware |
| Sonnenblumenöl | 1 l | 365 Tage | – | – | – | Trockenware |
| Balsamico | 0,5 l | 730 Tage | – | – | ja | Trockenware |
| Weißweinessig | 0,75 l | 730 Tage | – | – | – | Trockenware |

### Grundwürzen

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Salz | 500 g | unbegrenzt | – | – | ja | Trockenware |
| Pfeffer | 50 g | 730 Tage | – | – | ja | Trockenware |
| Zucker | 500 g | unbegrenzt | – | – | ja | Trockenware |

### Kräuter und Gewürze

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Oregano | 1 Dose | 730 Tage | – | – | ja | Trockenware |
| Paprika edelsüß | 1 Dose | 730 Tage | – | – | ja | Trockenware |
| Curry | 1 Dose | 730 Tage | – | – | – | Trockenware |
| Chili / Cayenne | 1 Dose | 730 Tage | – | – | – | Trockenware |
| Italienische Kräuter | 1 Dose | 730 Tage | – | – | ja | Trockenware |
| Knoblauchpulver | 1 Dose | 730 Tage | – | – | – | Trockenware |
| Muskat | 1 Dose | 730 Tage | – | – | – | Trockenware |
| Zimt | 1 Dose | 730 Tage | – | – | – | Trockenware |

### Saucen

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Sojasauce | 250 ml | 730 Tage | – | – | ja | Trockenware |
| Ketchup | 500 ml | 365 Tage | – | – | ja | Trockenware |
| Senf | 200 ml | 365 Tage | – | – | ja | Trockenware |
| Mayonnaise | 250 ml | 180 Tage | – | – | ja | Trockenware |
| Grillsauce | 500 ml | 365 Tage | – | – | – | Trockenware |
| Sweet-Chili-Sauce | 300 ml | 365 Tage | – | – | – | Trockenware |
| Tabasco / scharfe Sauce | 60 ml | 730 Tage | – | – | – | Trockenware |

## Frisches

### Obst

Bedarf: **1,5 kg pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Äpfel | 1 kg | 21 Tage | – | – | ja | Obst und Gemüse |
| Bananen | 1 kg | 4 Tage | – | – | ja | Obst und Gemüse |
| Orangen / Mandarinen | 1,5 kg | 21 Tage | – | – | ja | Obst und Gemüse |
| Trauben | 0,5 kg | 5 Tage | – | – | – | Obst und Gemüse |
| Melone | 1,5 kg | 7 Tage | – | – | – | Obst und Gemüse |
| Nektarinen / Pfirsiche | 1 kg | 5 Tage | – | – | – | Obst und Gemüse |
| Trockenobst (Aprikosen, Pflaumen) | 200 g | 180 Tage | – | – | – | Trockenware |
| Obstkonserve | 425 g | 730 Tage | – | – | – | Konserven |

### Gemüse und Salat für Mittag

Bedarf: **150 g pro Person und Mittagessen an Bord** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Tomaten | 0,5 kg | 7 Tage | – | – | ja | Obst und Gemüse |
| Gurke | 0,4 kg | 7 Tage | – | – | ja | Obst und Gemüse |
| Paprika | 0,5 kg | 10 Tage | – | – | ja | Obst und Gemüse |
| Kopfsalat / Eisbergsalat | 0,3 kg | 3 Tage | – | – | – | Obst und Gemüse |
| Karotten | 1 kg | 21 Tage | – | – | ja | Obst und Gemüse |
| Radieschen | 0,15 kg | 5 Tage | – | – | – | Obst und Gemüse |
| Sauerkraut (Glas/Beutel) | 500 g | 180 Tage | – | – | – | Konserven |
| Knollensellerie | 700 g | 30 Tage | – | – | – | Obst und Gemüse |

### Gemüse für Bordabende

Bedarf: **175 g pro Person und Abendessen an Bord** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Zucchini | 500 g | 7 Tage | – | – | ja | Obst und Gemüse |
| Aubergine | 400 g | 7 Tage | – | – | – | Obst und Gemüse |
| Brokkoli | 500 g | 4 Tage | – | – | – | Obst und Gemüse |
| Champignons | 250 g | 4 Tage | – | Kühlschrank | ja | Obst und Gemüse |
| Grüne Bohnen | 500 g | 5 Tage | – | – | – | Obst und Gemüse |
| Weißkohl | 1000 g | 30 Tage | – | – | – | Obst und Gemüse |
| Rotkohl | 1000 g | 30 Tage | – | – | – | Obst und Gemüse |
| Kürbis (ganz) | 1500 g | 60 Tage | – | – | – | Obst und Gemüse |
| Rote Bete, gekocht (vakuumiert) | 500 g | 30 Tage | – | Kühlschrank | – | Obst und Gemüse |
| Champignons, Konserve | 290 g | 730 Tage | – | – | – | Konserven |
| Erbsen und Karotten, Konserve | 400 g | 730 Tage | – | – | – | Konserven |
| Grüne Bohnen, Konserve | 400 g | 730 Tage | – | – | – | Konserven |
| Gemüsemischung, tiefgekühlt | 750 g | 90 Tage | – | Tiefkühl | – | Molkerei und Kühlregal |

### Zwiebeln, Knoblauch, Zitronen

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Zwiebeln | 1000 g | 30 Tage | – | – | ja | Obst und Gemüse |
| Knoblauch | 1 Knolle | 30 Tage | – | – | ja | Obst und Gemüse |
| Zitronen | 500 g | 21 Tage | – | – | ja | Obst und Gemüse |
| Ingwer | 100 g | 21 Tage | – | – | – | Obst und Gemüse |

### Fleisch und Fisch für Bordabende

Bedarf: **175 g pro Person und Abendessen an Bord** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Hähnchenbrust / -schenkel | 400 g | 3 Tage | 90 Tage | Kühlschrank | ja | Fleisch und Fisch |
| Hackfleisch | 500 g | 2 Tage | 60 Tage | Kühlschrank | ja | Fleisch und Fisch |
| Steak / Rind | 300 g | 3 Tage | 90 Tage | Kühlschrank | – | Fleisch und Fisch |
| Schweinekotelett / -filet | 500 g | 3 Tage | 90 Tage | Kühlschrank | – | Fleisch und Fisch |
| Bratwurst / Grillwurst | 400 g | 5 Tage | 60 Tage | Kühlschrank | ja | Fleisch und Fisch |
| Chorizo / luftgetrocknete Wurst | 200 g | 30 Tage | – | – | ja | Fleisch und Fisch |
| Fischfilet | 300 g | 2 Tage | 60 Tage | Kühlschrank | – | Fleisch und Fisch |
| Garnelen (TK) | 400 g | 1 Tage | 60 Tage | Kühlschrank | – | Fleisch und Fisch |
| Fleischkonserve (z. B. Corned Beef, Rindfleisch im eigenen Saft) | 300 g | 730 Tage | – | – | – | Konserven |
| Hähnchen, tiefgekühlt | 1000 g | 90 Tage | – | Tiefkühl | – | Fleisch und Fisch |
| Hackfleisch, tiefgekühlt | 500 g | 60 Tage | – | Tiefkühl | – | Fleisch und Fisch |
| Fischfilet, tiefgekühlt | 400 g | 60 Tage | – | Tiefkühl | – | Fleisch und Fisch |
| Garnelen, tiefgekühlt | 400 g | 60 Tage | – | Tiefkühl | – | Fleisch und Fisch |

### Vegetarische Hauptkomponente

Bedarf: **150 g pro Person und Abendessen an Bord** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Halloumi | 250 g | 30 Tage | – | Kühlschrank | ja | Molkerei und Kühlregal |
| Tofu | 400 g | 14 Tage | – | Kühlschrank | ja | Molkerei und Kühlregal |
| Falafel | 300 g | 7 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |
| Veggie-Burger / -Würstchen | 226 g | 14 Tage | – | Kühlschrank | – | Molkerei und Kühlregal |

## Süßes und Snacks

### Süßes

Bedarf: **300 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Schokolade | 100 g | 365 Tage | – | – | ja | Süßwaren |
| Kekse | 200 g | 180 Tage | – | – | ja | Süßwaren |
| Gummibärchen / Fruchtgummi | 200 g | 365 Tage | – | – | ja | Süßwaren |
| Müsliriegel | 150 g | 180 Tage | – | – | – | Süßwaren |

### Salzige Snacks

Bedarf: **300 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Chips | 175 g | 120 Tage | – | – | ja | Süßwaren |
| Nüsse / Studentenfutter | 200 g | 180 Tage | – | – | ja | Süßwaren |
| Salzstangen / Brezeln | 250 g | 180 Tage | – | – | ja | Süßwaren |
| Cracker | 200 g | 180 Tage | – | – | – | Süßwaren |

## Getränke ohne Alkohol

### Trinkwasser

Bedarf: **je Klima l pro Person und Tag, je nach Revier** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Wasser 5-l-Kanister | 5 l | 365 Tage | – | – | ja | Getränke |
| Wasser 1,5-l-Flaschen | 1,5 l | 365 Tage | – | – | ja | Getränke |
| Mineralwasser mit Kohlensäure | 1,5 l | 365 Tage | – | – | – | Getränke |

### Softdrinks

Bedarf: **0,5 l pro Person und Tag** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Cola | 1,5 l | 180 Tage | – | – | ja | Getränke |
| Zitronenlimonade | 1,5 l | 180 Tage | – | – | ja | Getränke |
| Eistee | 1,5 l | 180 Tage | – | – | – | Getränke |
| Tonic Water | 1 l | 180 Tage | – | – | – | Getränke |

### Säfte

Bedarf: **1 l pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Orangensaft | 1 l | 180 Tage | – | – | ja | Getränke |
| Apfelsaft | 1 l | 180 Tage | – | – | – | Getränke |
| Multivitaminsaft | 1 l | 180 Tage | – | – | – | Getränke |

### Kaffee

Bedarf: **15 g pro Person und Tag** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Kaffee gemahlen | 500 g | 180 Tage | – | – | ja | Trockenware |
| Instantkaffee | 200 g | 365 Tage | – | – | – | Trockenware |

### Tee

Bedarf: **2 Beutel pro Person und Tag** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Schwarztee | 25 Beutel | 730 Tage | – | – | ja | Trockenware |
| Kräutertee / Pfefferminz | 20 Beutel | 730 Tage | – | – | ja | Trockenware |
| Früchtetee | 20 Beutel | 730 Tage | – | – | – | Trockenware |

### Kaffeemilch

Bedarf: **0,5 l pro Person und Woche (anteilig bei anderen Törnlängen)** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| H-Milch für Kaffee | 1 l | 90 Tage | – | – | ja | Molkerei und Kühlregal |
| Kondensmilch | 0,34 l | 365 Tage | – | – | – | Molkerei und Kühlregal |

## Getränke mit Alkohol

### Bier

Bedarf: **0,5 l pro erwachsener Person und Abend** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Bier Dose 0,5 l | 0,5 l | 180 Tage | – | – | ja | Getränke |
| Bier Flasche 0,33 l | 0,33 l | 180 Tage | – | – | – | Getränke |
| Lokales Bier | 0,5 l | 180 Tage | – | – | – | Getränke |

### Wein und Sekt

Bedarf: **0,25 l pro erwachsener Person und Abend** · Aufteilung: equal · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Weißwein | 0,75 l | 365 Tage | – | – | ja | Getränke |
| Rotwein | 0,75 l | 365 Tage | – | – | ja | Getränke |
| Rosé | 0,75 l | 365 Tage | – | – | – | Getränke |
| Sekt / Prosecco | 0,75 l | 365 Tage | – | – | – | Getränke |
| Wein im Karton (Bag-in-Box) | 3 l | 180 Tage | – | – | – | Getränke |

### Spirituosen und Aperitif

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Rum | 0,7 l | unbegrenzt | – | – | – | Getränke |
| Gin | 0,7 l | unbegrenzt | – | – | – | Getränke |
| Aperol / Aperitif | 0,7 l | unbegrenzt | – | – | – | Getränke |
| Lokale Spezialität (Ouzo, Rakija …) | 0,7 l | unbegrenzt | – | – | – | Getränke |

## Haushalt

### Küche und Abwasch

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Spülmittel | 0,5 l | unbegrenzt | – | – | ja | Haushalt |
| Schwämme | 3 Stück | unbegrenzt | – | – | ja | Haushalt |
| Geschirrtücher | 2 Stück | unbegrenzt | – | – | ja | Haushalt |
| Küchenrolle | 2 Rollen | unbegrenzt | – | – | ja | Haushalt |
| Allzweckreiniger | 0,5 l | unbegrenzt | – | – | ja | Haushalt |

### Verpacken und Aufbewahren

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Müllsäcke | 20 Stück | unbegrenzt | – | – | ja | Haushalt |
| Alufolie | 1 Rollen | unbegrenzt | – | – | ja | Haushalt |
| Frischhaltefolie | 1 Rollen | unbegrenzt | – | – | – | Haushalt |
| Gefrier- / Zipbeutel | 20 Stück | unbegrenzt | – | – | ja | Haushalt |
| Wasserfester Stift | 1 Stück | unbegrenzt | – | – | ja | Haushalt |
| Wäscheklammern | 20 Stück | unbegrenzt | – | – | ja | Haushalt |

### Feuer und Grill

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Streichhölzer | 1 Packung | unbegrenzt | – | – | ja | Haushalt |
| Gasfeuerzeug (Stabfeuerzeug) | 1 Stück | unbegrenzt | – | – | ja | Haushalt |
| Grillkohle | 3 kg | unbegrenzt | – | – | – | Haushalt |

## Hygiene

### Hygiene und Pflege

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Toilettenpapier (bordtauglich, schnell auflösend) | 8 Rollen | unbegrenzt | – | – | ja | Drogerie |
| Handseife | 0,3 l | unbegrenzt | – | – | ja | Drogerie |
| Duschgel (biologisch abbaubar) | 0,25 l | unbegrenzt | – | – | ja | Drogerie |
| Shampoo | 0,25 l | unbegrenzt | – | – | – | Drogerie |
| Feuchttücher | 60 Stück | unbegrenzt | – | – | ja | Drogerie |

### Sonne und Insekten

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Sonnencreme | 200 ml | 730 Tage | – | – | ja | Drogerie |
| After-Sun | 200 ml | 730 Tage | – | – | – | Drogerie |
| Mückenschutz | 100 ml | 730 Tage | – | – | ja | Drogerie |

### Bordapotheke prüfen

Bedarf: **je Variante** · Aufteilung: each · Prüfliste

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Pflaster und Wundversorgung | 1 Set | unbegrenzt | – | – | ja | Apotheke / Drogerie |
| Schmerzmittel | 1 Packung | unbegrenzt | – | – | ja | Apotheke / Drogerie |
| Mittel gegen Seekrankheit | 1 Packung | unbegrenzt | – | – | ja | Apotheke / Drogerie |

## Bord und Technik

### Alltag an Bord

Bedarf: **je Variante** · Aufteilung: each · Menge

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Batterien AA | 8 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Batterien AAA | 8 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Stirnlampe | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Powerbank | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| 12-V-USB-Adapter | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Gewebeband | 1 Rollen | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Kabelbinder | 1 Packung | unbegrenzt | – | – | ja | Technik / Bootszubehör |

### Motor

Bedarf: **je Variante** · Aufteilung: each · Prüfliste

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Motoröl | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Ölfilter | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Dieselfilter | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Impeller | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Keilriemen | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Kühlmittel | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Fett | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |

### Elektrik

Bedarf: **je Variante** · Aufteilung: each · Prüfliste

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Ersatzsicherungen | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Ersatzlampen / LED | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Kabelschuhe | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Isolierband | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Multimeter | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |

### Rigg und Deck

Bedarf: **je Variante** · Aufteilung: each · Prüfliste

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Schäkel | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Takelgarn | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Ersatzleinen | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Segelreparaturband | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |

### Reparatur allgemein

Bedarf: **je Variante** · Aufteilung: each · Prüfliste

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Kriechöl (z. B. WD-40) | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Dichtmasse | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Schlauchschellen | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Epoxid-Knetmasse | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |

### Wasser und Sanitär

Bedarf: **je Variante** · Aufteilung: each · Prüfliste

| Variante | Packung | Haltbarkeit | TK-Haltbarkeit | Lagerung | Standard | Abteilung |
| --- | --- | --- | --- | --- | --- | --- |
| Ersatzdichtungen Pumpe / Toilette | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Bordtauglicher Toilettenreiniger | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
| Tankreiniger | 1 Stück | unbegrenzt | – | – | ja | Technik / Bootszubehör |
