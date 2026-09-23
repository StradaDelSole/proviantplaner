# Vorratskatalog v0.5

Stand: 23.09.2026 · maschinenlesbar in `data/catalog_v0.5.json`

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 10 Kategorien, 71 Positionen |
| v0.2 | 23.09.2026 | Konsumprofile und Einlagerungs-Hinweise |
| v0.3 | 23.09.2026 | Neues Schema Kategorie → Bedarfsgruppe → Variante; Kategorie Frühstück umgestellt |
| v0.4 | 23.09.2026 | Alle 10 Kategorien im neuen Schema (47 Gruppen, 212 Varianten); Technik mit Sichtbarkeit (Alltag auch beim Charter, Motor/Elektrik/Rigg/Reparatur/Sanitär nur eigenes Boot) und Prüflisten-Modus; Bordapotheke als Prüfliste |
| v0.5 | 23.09.2026 | Neue Rechenbasis pro Mittagessen an Bord; Gemüse und Salat für Mittag rechnet pro Bord-Mittagessen (150 g), damit Mittags-Restaurant den Bedarf senkt |

## Status

Alle Kategorien sind im neuen Schema. Die Mengen sind Startwerte und werden in der Baseline-Runde kalibriert; weitere Varianten können jederzeit ergänzt werden.

## Schema

- **Kategorie:** Gliederung für die App, z. B. Frühstück
- **Bedarfsgruppe:** hier wird der Bedarf berechnet, z. B. Brot und Backwaren 120 g pro Person und Tag; mit Konsumprofil, Kinderfaktor und Zielgruppe
- **Variante:** konkretes Produkt mit Packungsgröße und Haltbarkeit, z. B. Baguette 250 g, 1 Tag. Die Crew wählt Varianten, die App verteilt den Gruppenbedarf gleichmäßig oder nach Anteilen und rundet auf Packungen auf
- **Frisch nachkaufen:** Varianten mit höchstens 2 Tagen Haltbarkeit werden nur für die ersten Tage gekauft und als "unterwegs frisch nachkaufen" pro Hafentag ausgewiesen; haltbare Varianten decken Ankertage ab
- **split:** `equal` verteilt den Gruppenbedarf auf die gewählten Varianten (z. B. Brot); `each` gibt jeder gewählten Variante ihren eigenen Bedarf (z. B. Salz, Pfeffer, Sojasauce); ohne eigenen Bedarf gilt der Gruppenbedarf je Variante; ohne eigenen Bedarf gilt der Gruppenbedarf je Variante
- **Portionen:** Bei Sättigungsbeilagen rechnet jede Variante mit ihrer eigenen Portionsgröße (Spaghetti 130 g, Reis 70 g, Kartoffeln 225 g)
- **Sichtbarkeit:** `all` immer sichtbar; `owner` nur beim eigenen Boot, beim Charter eingeklappt
- **Modus:** `quantity` berechnet Mengen; `check` ist eine Prüfliste mit vorhanden / fehlt / nachkaufen
- Mengen sind je Gruppe und je Variante überschreibbar, auch als Gesamtzahl

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

Bordabend = Abendessen an Bord (Tag ohne Abends-Restaurant); Bord-Mittagessen = Tag ohne Mittags-Restaurant.

## Frühstück

### Brot und Backwaren

Bedarf: **120 g pro Person und Tag** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · Recherche nennt ca. einen halben Laib pro Person und Woche plus täglich frisches Brot; als Tagesbedarf zusammengefasst

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Vollkornbrot | 750 g | – | 5 Tage | ja | Backwaren | – | Tags: gluten |
| Weißbrot / Bauernbrot | 750 g | – | 3 Tage | – | Backwaren | – | Tags: gluten |
| Baguette | 250 g | – | 1 Tage | ja | Backwaren | – | frisch in jedem Hafen nachkaufen; Tags: gluten |
| Brötchen | 60 g | – | 1 Tage | ja | Backwaren | – | frisch nachkaufen; Tags: gluten |
| Vollkornbrötchen | 70 g | – | 1 Tage | – | Backwaren | – | frisch nachkaufen; Tags: gluten |
| Aufbackbrötchen | 300 g | – | 21 Tage | – | Backwaren | – | nur mit Backofen an Bord; Tags: gluten |
| Toastbrot | 500 g | – | 7 Tage | – | Backwaren | keep_dry | Tags: gluten |
| Knäckebrot | 250 g | – | 90 Tage | ja | Backwaren | keep_dry | Reserve für Ankertage; Tags: gluten |
| Wraps / Tortillas | 320 g | – | 14 Tage | – | Backwaren | – | Tags: gluten |

### Butter und Streichfett

Bedarf: **125 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Butter | 250 g | – | 21 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Gesalzene Butter | 250 g | – | 30 Tage | – | Molkerei und Kühlregal | – | hält ungekühlt länger; Tags: dairy |
| Margarine / veganes Streichfett | 250 g | – | 30 Tage | – | Molkerei und Kühlregal | – |  |

### Süße Aufstriche

Bedarf: **150 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Marmelade Erdbeere | 340 g | – | 60 Tage | ja | Trockenware | – |  |
| Marmelade Aprikose | 340 g | – | 60 Tage | – | Trockenware | – |  |
| Honig | 500 g | – | 365 Tage | ja | Trockenware | – |  |
| Nuss-Nougat-Creme | 400 g | – | 180 Tage | ja | Trockenware | – | Tags: nuts, dairy |
| Erdnussbutter | 350 g | – | 180 Tage | – | Trockenware | – | Tags: nuts |

### Herzhafte Aufstriche

Bedarf: **100 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Frischkäse | 200 g | – | 14 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Hummus | 200 g | – | 7 Tage | – | Molkerei und Kühlregal | cool_first |  |
| Streichwurst / Leberwurst | 125 g | – | 14 Tage | – | Fleisch und Fisch | cool_first | nur nicht vegetarisch; Tags: meat |

### Käse

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Gouda / Butterkäse in Scheiben | 200 g | – | 14 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Emmentaler / Bergkäse | 200 g | – | 21 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Brie / Camembert | 200 g | – | 10 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Feta | 200 g | – | 21 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Mozzarella | 125 g | – | 7 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Parmesan / Hartkäse am Stück | 200 g | – | 60 Tage | ja | Molkerei und Kühlregal | – | hält auch ungekühlt lange; Tags: dairy |

### Wurst und Aufschnitt

Bedarf: **200 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: nicht vegetarische Crewmitglieder · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Salami | 200 g | – | 30 Tage | ja | Fleisch und Fisch | – | luftgetrocknet, gut haltbar; Tags: meat |
| Kochschinken | 150 g | – | 7 Tage | ja | Fleisch und Fisch | cool_first | Tags: meat |
| Rohschinken | 100 g | – | 21 Tage | – | Fleisch und Fisch | cool_first | Tags: meat |
| Putenbrust | 150 g | – | 7 Tage | – | Fleisch und Fisch | cool_first | Tags: meat |

### Eier

Bedarf: **12 Stück pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Eier (10er) | 10 Stück | – | 21 Tage | ja | Molkerei und Kühlregal | eggs, remove_cardboard | Tags: egg |

### Milch und Alternativen

Bedarf: **0,5 l pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research · ohne Kaffeemilch (Getränke)

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Frischmilch | 1 l | – | 5 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| H-Milch | 1 l | – | 90 Tage | ja | Molkerei und Kühlregal | – | an Bord meist die bessere Wahl; Tags: dairy |
| Haferdrink | 1 l | – | 90 Tage | – | Molkerei und Kühlregal | – | Tags: gluten |
| Sojadrink | 1 l | – | 90 Tage | – | Molkerei und Kühlregal | – |  |

### Joghurt und Quark

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Naturjoghurt | 500 g | – | 14 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Fruchtjoghurt | 150 g | – | 14 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Skyr / Quark | 500 g | – | 14 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |

### Müsli und Cerealien

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Müsli | 750 g | – | 180 Tage | ja | Trockenware | remove_cardboard, keep_dry | Tags: gluten, nuts |
| Haferflocken | 500 g | – | 180 Tage | – | Trockenware | remove_cardboard, keep_dry | Tags: gluten |
| Cornflakes | 375 g | – | 180 Tage | – | Trockenware | remove_cardboard, keep_dry |  |
| Granola / Knuspermüsli | 500 g | – | 180 Tage | – | Trockenware | remove_cardboard, keep_dry | Tags: gluten, nuts |

## Grundnahrung

### Sättigungsbeilagen

Bedarf: **1 Portion pro Person und Bordabend** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research · Portionsgrößen je Variante

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Spaghetti | 500 g | 130 g je Portion | 365 Tage | ja | Trockenware | remove_cardboard, keep_dry | Tags: gluten |
| Penne / Fusilli | 500 g | 130 g je Portion | 365 Tage | ja | Trockenware | remove_cardboard, keep_dry | Tags: gluten |
| Reis | 1000 g | 70 g je Portion | 365 Tage | ja | Trockenware | remove_cardboard, keep_dry |  |
| Kartoffeln | 2000 g | 225 g je Portion | 21 Tage | ja | Obst und Gemüse | potatoes_onions |  |
| Couscous / Bulgur | 500 g | 70 g je Portion | 365 Tage | – | Trockenware | keep_dry | kocht mit wenig Wasser und Gas; Tags: gluten |
| Gnocchi | 500 g | 200 g je Portion | 60 Tage | – | Trockenware | – | Tags: gluten |
| Tortellini / Ravioli frisch | 250 g | 125 g je Portion | 14 Tage | – | Molkerei und Kühlregal | cool_first | Tags: gluten, dairy |

### Tomatenprodukte und Pastasaucen

Bedarf: **100 g pro Person und Bordabend** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research · Recherche: ca. 4 Dosen pro Crew und Woche

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Passierte Tomaten | 500 g | – | 365 Tage | ja | Konserven | remove_cardboard |  |
| Gehackte Tomaten (Dose) | 400 g | – | 730 Tage | ja | Konserven | remove_labels |  |
| Fertigsauce im Glas | 400 g | – | 365 Tage | – | Konserven | – |  |
| Pesto | 190 g | – | 365 Tage | ja | Konserven | – | Tags: nuts, dairy |
| Tomatenmark | 200 g | – | 365 Tage | – | Konserven | – |  |

### Konserven

Bedarf: **2 Dose pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · Reserve für Ankertage

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Thunfisch | 160 g | – | 1095 Tage | ja | Konserven | remove_labels | Tags: fish |
| Mais | 340 g | – | 1095 Tage | ja | Konserven | remove_labels |  |
| Kidneybohnen | 400 g | – | 1095 Tage | – | Konserven | remove_labels |  |
| Kichererbsen | 400 g | – | 1095 Tage | ja | Konserven | remove_labels |  |
| Linsen | 400 g | – | 1095 Tage | – | Konserven | remove_labels |  |
| Oliven | 300 g | – | 365 Tage | ja | Konserven | – |  |
| Ravioli / Eintopf (Dose) | 800 g | – | 1095 Tage | – | Konserven | remove_labels | Notreserve bei schlechtem Wetter; Tags: gluten |

### Suppen und Brühe

Bedarf: **1 Packung pro Crew und Woche (angefangene Woche zählt voll)** · Profil: eat · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Gemüsebrühe | 100 g | – | 365 Tage | ja | Trockenware | keep_dry |  |
| Instantsuppe / Tütensuppe | 4 Beutel | – | 365 Tage | ja | Trockenware | keep_dry | warm auf Nachtfahrten; Tags: gluten |
| Instant-Nudelsuppe | 5 Beutel | – | 365 Tage | – | Trockenware | keep_dry | Tags: gluten |
| Mehl | 1000 g | 1 Packung einmal pro Törn | 365 Tage | – | Trockenware | keep_dry | Tags: gluten |

## Saucen und Würzen

### Öl und Essig

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Olivenöl | 1 l | 1 l pro Crew und Woche (angefangene Woche zählt voll) | 365 Tage | ja | Trockenware | – |  |
| Sonnenblumenöl | 1 l | 1 l einmal pro Törn | 365 Tage | – | Trockenware | – |  |
| Balsamico | 0,5 l | 1 Flasche einmal pro Törn | 730 Tage | ja | Trockenware | – |  |
| Weißweinessig | 0,75 l | 1 Flasche einmal pro Törn | 730 Tage | – | Trockenware | – |  |

### Grundwürzen

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · oft von zu Hause mitgebracht

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Salz | 500 g | 1 Packung einmal pro Törn | unbegrenzt | ja | Trockenware | keep_dry |  |
| Pfeffer | 50 g | 1 Packung einmal pro Törn | 730 Tage | ja | Trockenware | – |  |
| Zucker | 500 g | 500 g pro Crew und Woche (angefangene Woche zählt voll) | unbegrenzt | ja | Trockenware | keep_dry |  |

### Kräuter und Gewürze

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Oregano | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | ja | Trockenware | – |  |
| Paprika edelsüß | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | ja | Trockenware | – |  |
| Curry | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |  |
| Chili / Cayenne | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |  |
| Italienische Kräuter | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | ja | Trockenware | – |  |
| Knoblauchpulver | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |  |
| Muskat | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |  |
| Zimt | 1 Dose | 1 Dose einmal pro Törn | 730 Tage | – | Trockenware | – |  |

### Saucen

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sojasauce | 250 ml | 1 Flasche einmal pro Törn | 730 Tage | ja | Trockenware | – | Tags: gluten |
| Ketchup | 500 ml | 1 Flasche pro Crew und Woche (angefangene Woche zählt voll) | 365 Tage | ja | Trockenware | – |  |
| Senf | 200 ml | 1 Tube einmal pro Törn | 365 Tage | ja | Trockenware | – |  |
| Mayonnaise | 250 ml | 1 Tube pro Crew und Woche (angefangene Woche zählt voll) | 180 Tage | ja | Trockenware | – | Tags: egg |
| Grillsauce | 500 ml | 1 Flasche einmal pro Törn | 365 Tage | – | Trockenware | – |  |
| Sweet-Chili-Sauce | 300 ml | 1 Flasche einmal pro Törn | 365 Tage | – | Trockenware | – |  |
| Tabasco / scharfe Sauce | 60 ml | 1 Flasche einmal pro Törn | 730 Tage | – | Trockenware | – |  |

## Frisches

### Obst

Bedarf: **1,5 kg pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research · frisch zuerst, unterwegs nachkaufen

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Äpfel | 1 kg | – | 21 Tage | ja | Obst und Gemüse | wash_produce | halten lange |
| Bananen | 1 kg | – | 4 Tage | ja | Obst und Gemüse | wash_produce | nicht eine ganze Staude: reifen alle am selben Tag |
| Orangen / Mandarinen | 1,5 kg | – | 21 Tage | ja | Obst und Gemüse | wash_produce |  |
| Trauben | 0,5 kg | – | 5 Tage | – | Obst und Gemüse | wash_produce |  |
| Melone | 1,5 kg | – | 7 Tage | – | Obst und Gemüse | wash_produce |  |
| Nektarinen / Pfirsiche | 1 kg | – | 5 Tage | – | Obst und Gemüse | wash_produce |  |

### Gemüse und Salat für Mittag

Bedarf: **150 g pro Person und Mittagessen an Bord** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research · aus ca. 1 kg pro Person und Woche abgeleitet; Mittags-Restaurant reduziert den Bedarf

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Tomaten | 0,5 kg | – | 7 Tage | ja | Obst und Gemüse | wash_produce | grüne und rote mischen, reifen gestaffelt |
| Gurke | 0,4 kg | – | 7 Tage | ja | Obst und Gemüse | wash_produce |  |
| Paprika | 0,5 kg | – | 10 Tage | ja | Obst und Gemüse | wash_produce |  |
| Kopfsalat / Eisbergsalat | 0,3 kg | – | 3 Tage | – | Obst und Gemüse | wash_produce | Eisberg hält länger |
| Karotten | 1 kg | – | 21 Tage | ja | Obst und Gemüse | wash_produce |  |
| Radieschen | 0,15 kg | – | 5 Tage | – | Obst und Gemüse | wash_produce |  |

### Gemüse für Bordabende

Bedarf: **175 g pro Person und Bordabend** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Zucchini | 500 g | – | 7 Tage | ja | Obst und Gemüse | wash_produce |  |
| Aubergine | 400 g | – | 7 Tage | – | Obst und Gemüse | wash_produce |  |
| Brokkoli | 500 g | – | 4 Tage | – | Obst und Gemüse | wash_produce |  |
| Champignons | 250 g | – | 4 Tage | ja | Obst und Gemüse | cool_first |  |
| Grüne Bohnen | 500 g | – | 5 Tage | – | Obst und Gemüse | wash_produce |  |

### Zwiebeln, Knoblauch, Zitronen

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Zwiebeln | 1 kg | 0,5 Stück pro Person und Bordabend | 30 Tage | ja | Obst und Gemüse | potatoes_onions |  |
| Knoblauch | 1 Knolle | 1 Knolle pro Crew und Woche (angefangene Woche zählt voll) | 30 Tage | ja | Obst und Gemüse | potatoes_onions |  |
| Zitronen | 0,5 kg | 0,5 Stück pro Person und Woche (anteilig bei anderen Törnlängen) | 21 Tage | ja | Obst und Gemüse | wash_produce |  |
| Ingwer | 100 g | 1 Stück einmal pro Törn | 21 Tage | – | Obst und Gemüse | – | auch gegen Seekrankheit beliebt |

### Fleisch und Fisch für Bordabende

Bedarf: **175 g pro Person und Bordabend** · Profil: eat · gilt für: nicht vegetarische Crewmitglieder · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research · kurze Haltbarkeit: für die ersten Tage kaufen, später in Häfen nachkaufen

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Hähnchenbrust / -schenkel | 400 g | – | 3 Tage | ja | Fleisch und Fisch | cool_first | Tags: meat |
| Hackfleisch | 500 g | – | 2 Tage | ja | Fleisch und Fisch | cool_first | Tags: meat |
| Steak / Rind | 300 g | – | 3 Tage | – | Fleisch und Fisch | cool_first | Tags: meat |
| Schweinekotelett / -filet | 500 g | – | 3 Tage | – | Fleisch und Fisch | cool_first | Tags: meat |
| Bratwurst / Grillwurst | 400 g | – | 5 Tage | ja | Fleisch und Fisch | cool_first | Tags: meat |
| Chorizo / luftgetrocknete Wurst | 200 g | – | 30 Tage | ja | Fleisch und Fisch | – | Reserve, hält ungekühlt; Tags: meat |
| Fischfilet | 300 g | – | 2 Tage | – | Fleisch und Fisch | cool_first | frisch im Hafen kaufen; Tags: fish |
| Garnelen (TK) | 400 g | – | 1 Tage | – | Fleisch und Fisch | cool_first | nur mit Tiefkühlfach; Tags: fish |

### Vegetarische Hauptkomponente

Bedarf: **150 g pro Person und Bordabend** · Profil: eat · gilt für: vegetarische Crewmitglieder · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Halloumi | 250 g | – | 30 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Tofu | 400 g | – | 14 Tage | ja | Molkerei und Kühlregal | cool_first |  |
| Falafel | 300 g | – | 7 Tage | – | Molkerei und Kühlregal | cool_first |  |
| Veggie-Burger / -Würstchen | 226 g | – | 14 Tage | – | Molkerei und Kühlregal | cool_first |  |

## Süßes und Snacks

### Süßes

Bedarf: **300 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · Urlaubszuschlag beachten

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Schokolade | 100 g | – | 365 Tage | ja | Süßwaren | – | schmilzt im Sommer: kühl lagern; Tags: dairy |
| Kekse | 200 g | – | 180 Tage | ja | Süßwaren | remove_cardboard, keep_dry | Tags: gluten |
| Gummibärchen / Fruchtgummi | 200 g | – | 365 Tage | ja | Süßwaren | – |  |
| Müsliriegel | 150 g | – | 180 Tage | – | Süßwaren | – | gut für Nachtwachen; Tags: gluten, nuts |

### Salzige Snacks

Bedarf: **300 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Chips | 175 g | – | 120 Tage | ja | Süßwaren | keep_dry |  |
| Nüsse / Studentenfutter | 200 g | – | 180 Tage | ja | Süßwaren | keep_dry | Tags: nuts |
| Salzstangen / Brezeln | 250 g | – | 180 Tage | ja | Süßwaren | keep_dry | Tags: gluten |
| Cracker | 200 g | – | 180 Tage | – | Süßwaren | keep_dry | Tags: gluten |

## Getränke ohne Alkohol

### Trinkwasser

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: research · Menge je Revier aus quantities; Kochwasser aus dem Bordtank

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Wasser 5-l-Kanister | 5 l | – | 365 Tage | ja | Getränke | remove_cardboard | platzsparend, weniger Plastik |
| Wasser 1,5-l-Flaschen | 1,5 l | – | 365 Tage | ja | Getränke | remove_cardboard | handlich für unterwegs |
| Mineralwasser mit Kohlensäure | 1,5 l | – | 365 Tage | – | Getränke | – |  |

### Softdrinks

Bedarf: **0,5 l pro Person und Tag** · Profil: none · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cola | 1,5 l | – | 180 Tage | ja | Getränke | remove_cardboard |  |
| Zitronenlimonade | 1,5 l | – | 180 Tage | ja | Getränke | remove_cardboard |  |
| Eistee | 1,5 l | – | 180 Tage | – | Getränke | remove_cardboard |  |
| Tonic Water | 1 l | – | 180 Tage | – | Getränke | – | auch als Longdrink-Mixer |

### Säfte

Bedarf: **1 l pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: none · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Orangensaft | 1 l | – | 180 Tage | ja | Getränke | – |  |
| Apfelsaft | 1 l | – | 180 Tage | – | Getränke | – |  |
| Multivitaminsaft | 1 l | – | 180 Tage | – | Getränke | – |  |

### Kaffee

Bedarf: **15 g pro Person und Tag** · Profil: none · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · ca. 2 Tassen

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Kaffee gemahlen | 500 g | – | 180 Tage | ja | Trockenware | keep_dry | für Espressokocher oder Filter |
| Instantkaffee | 200 g | – | 365 Tage | – | Trockenware | keep_dry | schnell bei Seegang |

### Tee

Bedarf: **2 Beutel pro Person und Tag** · Profil: none · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Schwarztee | 25 Beutel | – | 730 Tage | ja | Trockenware | keep_dry |  |
| Kräutertee / Pfefferminz | 20 Beutel | – | 730 Tage | ja | Trockenware | keep_dry |  |
| Früchtetee | 20 Beutel | – | 730 Tage | – | Trockenware | keep_dry |  |

### Kaffeemilch

Bedarf: **0,5 l pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: none · gilt für: alle · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H-Milch für Kaffee | 1 l | – | 90 Tage | ja | Molkerei und Kühlregal | – | Tags: dairy |
| Kondensmilch | 0,34 l | – | 365 Tage | – | Molkerei und Kühlregal | – | Tags: dairy |

## Getränke mit Alkohol

### Bier

Bedarf: **1 Portion 0,5 l pro erwachsener Person und Abend** · Profil: drink · gilt für: Erwachsene · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · Startwert, über Trinkprofil und Gesamtzahl einstellbar

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Bier Dose 0,5 l | 0,5 l | – | 180 Tage | ja | Getränke | remove_cardboard | Dosen brechen nicht; Tags: alcohol, gluten |
| Bier Flasche 0,33 l | 0,33 l | – | 180 Tage | – | Getränke | remove_cardboard | Tags: alcohol, gluten |
| Lokales Bier | 0,5 l | – | 180 Tage | – | Getränke | – | Tags: alcohol, gluten |

### Wein und Sekt

Bedarf: **0,25 l pro erwachsener Person und Abend** · Profil: drink · gilt für: Erwachsene · Aufteilung: equal · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · Praxisberichte liegen teils deutlich höher

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Weißwein | 0,75 l | – | 365 Tage | ja | Getränke | – | Tags: alcohol |
| Rotwein | 0,75 l | – | 365 Tage | ja | Getränke | – | Tags: alcohol |
| Rosé | 0,75 l | – | 365 Tage | – | Getränke | – | Tags: alcohol |
| Sekt / Prosecco | 0,75 l | – | 365 Tage | – | Getränke | – | Tags: alcohol |
| Wein im Karton (Bag-in-Box) | 3 l | – | 180 Tage | – | Getränke | – | bruchsicher und platzsparend; Tags: alcohol |

### Spirituosen und Aperitif

Bedarf: **je Variante** · Profil: drink · gilt für: Erwachsene · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Rum | 0,7 l | 1 Flasche einmal pro Törn | unbegrenzt | – | Getränke | – | Tags: alcohol |
| Gin | 0,7 l | 1 Flasche einmal pro Törn | unbegrenzt | – | Getränke | – | Tags: alcohol |
| Aperol / Aperitif | 0,7 l | 1 Flasche einmal pro Törn | unbegrenzt | – | Getränke | – | Tags: alcohol |
| Lokale Spezialität (Ouzo, Rakija …) | 0,7 l | 1 Flasche einmal pro Törn | unbegrenzt | – | Getränke | – | Tags: alcohol |

## Haushalt

### Küche und Abwasch

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: research · wird laut Charter-Leitfäden oft vergessen

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Spülmittel | 0,5 l | 1 Flasche pro Crew und Woche (angefangene Woche zählt voll) | unbegrenzt | ja | Haushalt | – |  |
| Schwämme | 3 Stück | 2 Stück pro Crew und Woche (angefangene Woche zählt voll) | unbegrenzt | ja | Haushalt | – |  |
| Geschirrtücher | 2 Stück | 2 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | – |  |
| Küchenrolle | 2 Rollen | 0,5 Rolle pro Person und Woche (anteilig bei anderen Törnlängen) | unbegrenzt | ja | Haushalt | keep_dry |  |
| Allzweckreiniger | 0,5 l | 1 Flasche einmal pro Törn | unbegrenzt | ja | Haushalt | – |  |

### Verpacken und Aufbewahren

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Müllsäcke | 20 Stück | 1 Rolle einmal pro Törn | unbegrenzt | ja | Haushalt | – |  |
| Alufolie | 1 Rolle | 1 Rolle einmal pro Törn | unbegrenzt | ja | Haushalt | – |  |
| Frischhaltefolie | 1 Rolle | 1 Rolle einmal pro Törn | unbegrenzt | – | Haushalt | – |  |
| Gefrier- / Zipbeutel | 20 Stück | 1 Packung einmal pro Törn | unbegrenzt | ja | Haushalt | – | für umgefüllte Lebensmittel und nasse Sachen |
| Wasserfester Stift | 1 Stück | 1 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | – | für Dosen ohne Etikett |
| Wäscheklammern | 20 Stück | 20 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | – |  |

### Feuer und Grill

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: research

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Streichhölzer | 1 Packung | 1 Packung einmal pro Törn | unbegrenzt | ja | Haushalt | keep_dry | für den Gasherd |
| Gasfeuerzeug (Stabfeuerzeug) | 1 Stück | 1 Stück einmal pro Törn | unbegrenzt | ja | Haushalt | – |  |
| Grillkohle | 3 kg | 1 Sack einmal pro Törn | unbegrenzt | – | Haushalt | – | nur wenn Grill an Bord |

## Hygiene

### Hygiene und Pflege

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Toilettenpapier (bordtauglich, schnell auflösend) | 8 Rollen | 2 Rollen pro Person und Woche (anteilig bei anderen Törnlängen) | unbegrenzt | ja | Drogerie | keep_dry | Bordtoiletten verstopfen leicht; Hinweis der Basis beachten |
| Handseife | 0,3 l | 1 Flasche einmal pro Törn | unbegrenzt | ja | Drogerie | – |  |
| Duschgel (biologisch abbaubar) | 0,25 l | 0,25 Flasche pro Person und Woche (anteilig bei anderen Törnlängen) | unbegrenzt | ja | Drogerie | – |  |
| Shampoo | 0,25 l | 1 Flasche einmal pro Törn | unbegrenzt | – | Drogerie | – |  |
| Feuchttücher | 60 Stück | 1 Packung einmal pro Törn | unbegrenzt | ja | Drogerie | – |  |

### Sonne und Insekten

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sonnencreme | 200 ml | 100 ml pro Person und Woche (anteilig bei anderen Törnlängen) | 730 Tage | ja | Drogerie | – |  |
| After-Sun | 200 ml | 1 Flasche einmal pro Törn | 730 Tage | – | Drogerie | – |  |
| Mückenschutz | 100 ml | 1 Flasche einmal pro Törn | 730 Tage | ja | Drogerie | – |  |

### Bordapotheke prüfen

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Prüfliste · Quelle: estimate · nur Prüfliste; Inhalt der Bordapotheke mit der Basis abgleichen

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pflaster und Wundversorgung | 1 Set | 1 Set Checkliste, keine Mengenberechnung | unbegrenzt | ja | Apotheke / Drogerie | – |  |
| Schmerzmittel | 1 Packung | 1 Packung Checkliste, keine Mengenberechnung | unbegrenzt | ja | Apotheke / Drogerie | – |  |
| Mittel gegen Seekrankheit | 1 Packung | 1 Packung Checkliste, keine Mengenberechnung | unbegrenzt | ja | Apotheke / Drogerie | – |  |

## Bord und Technik

### Alltag an Bord

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: immer · Modus: Menge · Quelle: estimate · auch beim Charter sichtbar

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Batterien AA | 8 Stück | 8 Stück einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | keep_dry | Stirnlampen, Handfunkgerät |
| Batterien AAA | 8 Stück | 8 Stück einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | keep_dry |  |
| Stirnlampe | 1 Stück | 1 Stück einmal pro Person und Törn | unbegrenzt | ja | Technik / Bootszubehör | – | prüfen, ob jeder eine hat |
| Powerbank | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| 12-V-USB-Adapter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – | für Handys am Bordnetz |
| Gewebeband | 1 Rolle | 1 Rolle einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Kabelbinder | 1 Packung | 1 Packung einmal pro Törn | unbegrenzt | ja | Technik / Bootszubehör | – |  |

### Motor

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate · beim Charter Sache der Basis

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Motoröl | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Ölfilter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Dieselfilter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Impeller | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Keilriemen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Kühlmittel | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Fett | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |

### Elektrik

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ersatzsicherungen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Ersatzlampen / LED | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Kabelschuhe | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Isolierband | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Multimeter | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |

### Rigg und Deck

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Schäkel | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Takelgarn | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Ersatzleinen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Segelreparaturband | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |

### Reparatur allgemein

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Kriechöl (z. B. WD-40) | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Dichtmasse | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Schlauchschellen | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Epoxid-Knetmasse | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |

### Wasser und Sanitär

Bedarf: **je Variante** · Profil: none · gilt für: alle · Aufteilung: each · Sichtbarkeit: nur eigenes Boot · Modus: Prüfliste · Quelle: estimate

| Variante | Packung | Bedarf/Portion | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ersatzdichtungen Pumpe / Toilette | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Bordtauglicher Toilettenreiniger | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |
| Tankreiniger | 1 Stück | 1 Stück Checkliste, keine Mengenberechnung | unbegrenzt | ja | Technik / Bootszubehör | – |  |

## Offene Punkte

- [ ] Katalog durchsehen: fehlende Varianten, Packungsgrößen, Haltbarkeiten
- [ ] Baseline der Bedarfsmengen kalibrieren
