# Vorratskatalog v0.1

Stand: 23.09.2026 · Grundlage für die Vorratsliste des Proviantplaners · maschinenlesbar in `data/catalog_v0.1.json`

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 10 Kategorien, 71 Positionen, Rechenbasen, Ernährungs-Tags, Charter-Modus |

## Prinzip

Die Vorratsliste ist der Kern der App: Aus Crew, Törnlänge, Revier und Bordabenden entsteht eine fertige Einkaufsliste, ohne dass gekocht geplant werden muss. Der Menüplan ist optional. Jede Position hat eine Rechenbasis; die Crew kann jede Position abwählen, Mengen ändern und eigene ergänzen.

**Quelle:** `research` = aus den im PRD zitierten Charter- und Portionsquellen; `estimate` = Startwert ohne belastbare Quelle, nach den ersten Törns zu kalibrieren.

## Rechenbasen

| Basis | Bedeutung |
| --- | --- |
| `per_person_day` | pro Person und Tag |
| `per_person_day_region` | pro Person und Tag, je nach Revier |
| `per_person_week` | pro Person und Woche (anteilig bei anderen Törnlängen) |
| `per_person_board_evening` | pro Person und Bordabend |
| `per_adult_evening` | pro erwachsener Person und Abend |
| `per_crew_week` | pro Crew und Woche (angefangene Woche zählt voll) |
| `per_trip` | einmal pro Törn |
| `per_person_trip` | einmal pro Person und Törn |
| `check` | Checkliste, keine Mengenberechnung |

## Regeln

- Kinder zählen mit Faktor 0,6 (Startwert)
- Appetit-Faktor und Urlaubszuschlag aus `quantities_v0.1.json`
- Mengen pro Woche werden anteilig auf die Törnlänge umgerechnet und auf sinnvolle Packungsgrößen aufgerundet
- Positionen für nicht vegetarische bzw. vegetarische Crewmitglieder werden nur für diese gezählt
- Alkohol nur für Erwachsene, Startwerte von der Crew einstellbar
- **Charter-Modus:** Technik-Positionen mit Kennzeichen *Charter ausgeblendet* sind beim Charter eingeklappt und beim eigenen Boot sichtbar
- Ernährungs-Tags dienen nur zum Filtern (z. B. glutenfrei, vegan) und sind kein Allergie-Schutz; die App weist darauf hin, dass Zutaten auf der Packung geprüft werden müssen

## Frühstück

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Brot | 0,5 | Laib | per_person_week | alle | Backwaren | research | plus taeglich frisches Brot vor Ort; Tags: gluten |
| Butter | 125 | g | per_person_week | alle | Molkerei und Kühlregal | research | Tags: dairy |
| Marmelade | 100 | g | per_person_week | alle | Trockenware | estimate |  |
| Honig | 50 | g | per_person_week | alle | Trockenware | estimate |  |
| Müsli / Cornflakes | 250 | g | per_person_week | alle | Trockenware | estimate | Tags: gluten |
| Eier | 12 | Stück | per_person_week | alle | Molkerei und Kühlregal | research | Tags: egg |
| Käse gemischt | 250 | g | per_person_week | alle | Molkerei und Kühlregal | research | Tags: dairy |
| Aufschnitt, Schinken, Salami | 200 | g | per_person_week | nicht vegetarische Crewmitglieder | Fleisch und Fisch | research | Tags: meat |
| Joghurt | 250 | g | per_person_week | alle | Molkerei und Kühlregal | research | Tags: dairy |
| Milch | 0,5 | l | per_person_week | alle | Molkerei und Kühlregal | research | Tags: dairy |

## Grundnahrung

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pasta | 130 | g | per_person_board_evening | alle | Trockenware | research | Hauptgericht; als Beilage 50–80 g; Tags: gluten |
| Reis | 70 | g | per_person_board_evening | alle | Trockenware | research |  |
| Kartoffeln | 225 | g | per_person_board_evening | alle | Obst und Gemüse | research |  |
| Tomatensauce / gehackte Tomaten | 4 | Dose | per_crew_week | alle | Konserven | research |  |
| Konserven (Thunfisch, Mais, Bohnen) | 2 | Dose | per_person_week | alle | Konserven | estimate |  |
| Brühe / Suppenwürfel | 1 | Packung | per_crew_week | alle | Trockenware | estimate |  |

## Saucen und Würzen

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Olivenöl | 1 | l | per_crew_week | alle | Trockenware | research |  |
| Essig | 1 | Flasche | per_trip | alle | Trockenware | estimate |  |
| Salz | 1 | Packung | per_trip | alle | Trockenware | estimate | kann von zu Hause mitgebracht werden |
| Pfeffer | 1 | Packung | per_trip | alle | Trockenware | estimate |  |
| Zucker | 500 | g | per_crew_week | alle | Trockenware | estimate |  |
| Gewürzmischung (Oregano, Paprika, Curry …) | 1 | Set | per_trip | alle | Trockenware | estimate | am besten von zu Hause mitbringen |
| Sojasauce | 1 | Flasche | per_trip | alle | Trockenware | estimate | Tags: gluten |
| Ketchup | 1 | Flasche | per_crew_week | alle | Trockenware | estimate |  |
| Senf | 1 | Tube | per_trip | alle | Trockenware | estimate |  |
| Mayonnaise | 1 | Tube | per_crew_week | alle | Trockenware | estimate | Tags: egg |
| Pesto | 1 | Glas | per_crew_week | alle | Trockenware | estimate | Tags: nuts, dairy |

## Frisches

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Obst gemischt | 1,5 | kg | per_person_week | alle | Obst und Gemüse | research | frisch zuerst, unterwegs nachkaufen |
| Gemüse und Salat für Mittagessen | 1 | kg | per_person_week | alle | Obst und Gemüse | research | frisch nachkaufen |
| Gemüse für Bordabende | 175 | g | per_person_board_evening | alle | Obst und Gemüse | research | als Hauptgericht ca. 400 g |
| Zwiebeln | 0,5 | Stück | per_person_board_evening | alle | Obst und Gemüse | estimate |  |
| Knoblauch | 1 | Knolle | per_crew_week | alle | Obst und Gemüse | estimate |  |
| Zitronen | 0,5 | Stück | per_person_week | alle | Obst und Gemüse | estimate |  |
| Fleisch oder Fisch für Bordabende | 175 | g | per_person_board_evening | nicht vegetarische Crewmitglieder | Fleisch und Fisch | research | Fleisch ohne Knochen 150–200 g, Fischfilet 150–180 g; Tags: meat, fish |
| Vegetarische Alternative (Halloumi, Tofu, Hülsenfrüchte) | 150 | g | per_person_board_evening | vegetarische Crewmitglieder | Molkerei und Kühlregal | estimate |  |

## Süßes und Snacks

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Schokolade | 200 | g | per_person_week | alle | Süßwaren | estimate | Urlaubszuschlag beachten; Tags: dairy, nuts |
| Kekse | 200 | g | per_person_week | alle | Süßwaren | estimate | Tags: gluten |
| Gummibärchen / Süßigkeiten | 100 | g | per_person_week | alle | Süßwaren | estimate |  |
| Nüsse | 150 | g | per_person_week | alle | Süßwaren | estimate | Tags: nuts |
| Chips | 150 | g | per_person_week | alle | Süßwaren | estimate |  |

## Getränke ohne Alkohol

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Trinkwasser | je Revier | l | per_person_day_region | alle | Getränke | research | Menge je Revier aus quantities_v0.1.json; Kochwasser aus dem Bordtank |
| Softdrinks | 0,5 | l | per_person_day | alle | Getränke | estimate |  |
| Saft | 1 | l | per_person_week | alle | Getränke | estimate |  |
| Kaffee | 15 | g | per_person_day | alle | Trockenware | estimate | ca. 2 Tassen |
| Tee | 2 | Beutel | per_person_day | alle | Trockenware | estimate |  |
| Kaffeemilch / H-Milch | 0,5 | l | per_person_week | alle | Molkerei und Kühlregal | estimate | Tags: dairy |

## Getränke mit Alkohol

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Bier | 1 | Dose/Flasche 0,5 l | per_adult_evening | Erwachsene | Getränke | estimate | Startwert, von der Crew einstellbar; Tags: alcohol, gluten |
| Wein | 0,25 | l | per_adult_evening | Erwachsene | Getränke | estimate | Startwert; Praxisberichte liegen teils deutlich höher; Tags: alcohol |
| Spirituosen für den Sundowner | 1 | Flasche 0,7 l | per_trip | Erwachsene | Getränke | estimate | standardmäßig abgewählt; Tags: alcohol |

## Haushalt

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Spülmittel | 1 | Flasche | per_crew_week | alle | Haushalt | research | wird laut Charter-Leitfäden oft vergessen |
| Schwämme | 2 | Stück | per_crew_week | alle | Haushalt | estimate |  |
| Geschirrtücher | 2 | Stück | per_trip | alle | Haushalt | estimate | oft von zu Hause mitgebracht |
| Küchenrolle | 0,5 | Rolle | per_person_week | alle | Haushalt | estimate |  |
| Müllsäcke | 1 | Rolle | per_trip | alle | Haushalt | research |  |
| Alufolie | 1 | Rolle | per_trip | alle | Haushalt | estimate |  |
| Frischhaltebeutel | 1 | Packung | per_trip | alle | Haushalt | estimate |  |
| Streichhölzer / Gasfeuerzeug | 1 | Stück | per_trip | alle | Haushalt | research | für den Gasherd |
| Grillkohle | 1 | Sack | per_trip | alle | Haushalt | research | nur wenn Grill an Bord; standardmäßig abgewählt |

## Hygiene

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Toilettenpapier (bordtauglich, schnell auflösend) | 2 | Rolle | per_person_week | alle | Drogerie | estimate | Bordtoiletten verstopfen leicht; Hinweis der Basis beachten |
| Handseife | 1 | Flasche | per_trip | alle | Drogerie | estimate |  |
| Duschgel (biologisch abbaubar) | 0,25 | Flasche | per_person_week | alle | Drogerie | estimate |  |
| Sonnencreme | 100 | ml | per_person_week | alle | Drogerie | estimate |  |

## Bord und Technik

| Position | Menge | Einheit | Basis | Gilt für | Abteilung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Batterien AA | 8 | Stück | per_trip | alle | Technik / Bootszubehör | estimate | Stirnlampen, Handfunkgerät |
| Batterien AAA | 8 | Stück | per_trip | alle | Technik / Bootszubehör | estimate |  |
| Stirnlampe | 1 | Stück | per_person_trip | alle | Technik / Bootszubehör | estimate | prüfen, ob vorhanden |
| Wäscheklammern | 20 | Stück | per_trip | alle | Haushalt | estimate |  |
| Kabelbinder | 1 | Packung | per_trip | alle | Technik / Bootszubehör | estimate | Charter ausgeblendet |
| Gewebeband | 1 | Rolle | per_trip | alle | Technik / Bootszubehör | estimate | Charter ausgeblendet |
| Kriechöl (z. B. WD-40) | 1 | Dose | per_trip | alle | Technik / Bootszubehör | estimate | Charter ausgeblendet |
| Motoröl | 1 | l | check | alle | Technik / Bootszubehör | estimate | Stand prüfen; beim Charter Sache der Basis; Charter ausgeblendet |
| Ersatzsicherungen | 1 | Set | check | alle | Technik / Bootszubehör | estimate | Charter ausgeblendet |

## Offene Punkte

- [ ] Startwerte mit `estimate` nach dem ersten echten Törn prüfen
- [ ] Packungsgrößen pro Land für das Aufrunden festlegen
- [ ] Übersetzung der Positionsnamen in FR, ES, PT, HR, EN
