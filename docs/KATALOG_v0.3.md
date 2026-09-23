# Vorratskatalog v0.3 (in Arbeit)

Stand: 23.09.2026 · maschinenlesbar in `data/catalog_v0.3.json`

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 10 Kategorien, 71 Positionen |
| v0.2 | 23.09.2026 | Konsumprofile und Einlagerungs-Hinweise |
| v0.3 | 23.09.2026 | Neues Schema Kategorie → Bedarfsgruppe → Variante; Kategorie Frühstück vollständig umgestellt (10 Gruppen, 42 Varianten) |

## Status

| Kategorie | Status |
| --- | --- |
| Frühstück | im neuen Schema, zur Durchsicht |
| Grundnahrung | folgt |
| Saucen und Würzen | folgt |
| Frisches | folgt |
| Süßes und Snacks | folgt |
| Getränke ohne Alkohol | folgt |
| Getränke mit Alkohol | folgt |
| Haushalt | folgt |
| Hygiene | folgt |
| Bord und Technik | folgt |

## Schema

- **Kategorie:** Gliederung für die App, z. B. Frühstück
- **Bedarfsgruppe:** hier wird der Bedarf berechnet, z. B. Brot und Backwaren 120 g pro Person und Tag; mit Konsumprofil, Kinderfaktor und Zielgruppe
- **Variante:** konkretes Produkt mit Packungsgröße und Haltbarkeit, z. B. Baguette 250 g, 1 Tag. Die Crew wählt Varianten, die App verteilt den Gruppenbedarf gleichmäßig oder nach Anteilen und rundet auf Packungen auf
- **Frisch nachkaufen:** Varianten mit höchstens 2 Tagen Haltbarkeit werden nur für die ersten Tage gekauft und als "unterwegs frisch nachkaufen" pro Hafentag ausgewiesen; haltbare Varianten decken Ankertage ab
- Mengen sind je Gruppe und je Variante überschreibbar, auch als Gesamtzahl

### Brot und Backwaren

Bedarf: **120 g pro Person und Tag** · Profil: eat · gilt für: alle · Quelle: estimate · Recherche nennt ca. einen halben Laib pro Person und Woche plus täglich frisches Brot; als Tagesbedarf zusammengefasst

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Vollkornbrot | 750 g | 5 Tage | ja | Backwaren | – | Tags: gluten |
| Weißbrot / Bauernbrot | 750 g | 3 Tage | – | Backwaren | – | Tags: gluten |
| Baguette | 250 g | 1 Tage | ja | Backwaren | – | frisch in jedem Hafen nachkaufen; Tags: gluten |
| Brötchen | 60 g | 1 Tage | ja | Backwaren | – | frisch nachkaufen; Tags: gluten |
| Vollkornbrötchen | 70 g | 1 Tage | – | Backwaren | – | frisch nachkaufen; Tags: gluten |
| Aufbackbrötchen | 300 g | 21 Tage | – | Backwaren | – | nur mit Backofen an Bord; Tags: gluten |
| Toastbrot | 500 g | 7 Tage | – | Backwaren | keep_dry | Tags: gluten |
| Knäckebrot | 250 g | 90 Tage | ja | Backwaren | keep_dry | Reserve für Ankertage; Tags: gluten |
| Wraps / Tortillas | 320 g | 14 Tage | – | Backwaren | – | Tags: gluten |

### Butter und Streichfett

Bedarf: **125 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: research

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Butter | 250 g | 21 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Gesalzene Butter | 250 g | 30 Tage | – | Molkerei und Kühlregal | – | hält ungekühlt länger; Tags: dairy |
| Margarine / veganes Streichfett | 250 g | 30 Tage | – | Molkerei und Kühlregal | – |  |

### Süße Aufstriche

Bedarf: **150 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: estimate

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Marmelade Erdbeere | 340 g | 60 Tage | ja | Trockenware | – |  |
| Marmelade Aprikose | 340 g | 60 Tage | – | Trockenware | – |  |
| Honig | 500 g | 365 Tage | ja | Trockenware | – |  |
| Nuss-Nougat-Creme | 400 g | 180 Tage | ja | Trockenware | – | Tags: nuts, dairy |
| Erdnussbutter | 350 g | 180 Tage | – | Trockenware | – | Tags: nuts |

### Herzhafte Aufstriche

Bedarf: **100 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: estimate

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Frischkäse | 200 g | 14 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Hummus | 200 g | 7 Tage | – | Molkerei und Kühlregal | cool_first |  |
| Streichwurst / Leberwurst | 125 g | 14 Tage | – | Fleisch und Fisch | cool_first | nur nicht vegetarisch; Tags: meat |

### Käse

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: research

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Gouda / Butterkäse in Scheiben | 200 g | 14 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Emmentaler / Bergkäse | 200 g | 21 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Brie / Camembert | 200 g | 10 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Feta | 200 g | 21 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Mozzarella | 125 g | 7 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Parmesan / Hartkäse am Stück | 200 g | 60 Tage | ja | Molkerei und Kühlregal | – | hält auch ungekühlt lange; Tags: dairy |

### Wurst und Aufschnitt

Bedarf: **200 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: nicht vegetarische Crewmitglieder · Quelle: research

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Salami | 200 g | 30 Tage | ja | Fleisch und Fisch | – | luftgetrocknet, gut haltbar; Tags: meat |
| Kochschinken | 150 g | 7 Tage | ja | Fleisch und Fisch | cool_first | Tags: meat |
| Rohschinken | 100 g | 21 Tage | – | Fleisch und Fisch | cool_first | Tags: meat |
| Putenbrust | 150 g | 7 Tage | – | Fleisch und Fisch | cool_first | Tags: meat |

### Eier

Bedarf: **12 Stück pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: research

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Eier (10er) | 10 Stück | 21 Tage | ja | Molkerei und Kühlregal | eggs, remove_cardboard | Tags: egg |

### Milch und Alternativen

Bedarf: **0,5 l pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: research · ohne Kaffeemilch (Getränke)

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Frischmilch | 1 l | 5 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| H-Milch | 1 l | 90 Tage | ja | Molkerei und Kühlregal | – | an Bord meist die bessere Wahl; Tags: dairy |
| Haferdrink | 1 l | 90 Tage | – | Molkerei und Kühlregal | – | Tags: gluten |
| Sojadrink | 1 l | 90 Tage | – | Molkerei und Kühlregal | – |  |

### Joghurt und Quark

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: research

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Naturjoghurt | 500 g | 14 Tage | ja | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Fruchtjoghurt | 150 g | 14 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |
| Skyr / Quark | 500 g | 14 Tage | – | Molkerei und Kühlregal | cool_first | Tags: dairy |

### Müsli und Cerealien

Bedarf: **250 g pro Person und Woche (anteilig bei anderen Törnlängen)** · Profil: eat · gilt für: alle · Quelle: estimate

| Variante | Packung | Haltbarkeit | Standard | Abteilung | Einlagerung | Hinweis |
| --- | --- | --- | --- | --- | --- | --- |
| Müsli | 750 g | 180 Tage | ja | Trockenware | remove_cardboard, keep_dry | Tags: gluten, nuts |
| Haferflocken | 500 g | 180 Tage | – | Trockenware | remove_cardboard, keep_dry | Tags: gluten |
| Cornflakes | 375 g | 180 Tage | – | Trockenware | remove_cardboard, keep_dry |  |
| Granola / Knuspermüsli | 500 g | 180 Tage | – | Trockenware | remove_cardboard, keep_dry | Tags: gluten, nuts |

## Offene Punkte

- [ ] Frühstück durchsehen: fehlende Varianten, Packungsgrößen, Haltbarkeiten, Bedarfsmengen
- [ ] Übrige Kategorien ins neue Schema überführen
- [ ] Baseline der Bedarfsmengen kalibrieren
