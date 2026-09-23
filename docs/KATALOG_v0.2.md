# Vorratskatalog v0.2

Stand: 23.09.2026 · Grundlage für die Vorratsliste des Proviantplaners · maschinenlesbar in `data/catalog_v0.2.json`

## Changelog

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung: 10 Kategorien, 71 Positionen, Rechenbasen, Ernährungs-Tags, Charter-Modus |
| v0.2 | 23.09.2026 | Konsumprofile (Essen, Trinken) pro Position zugeordnet; Einlagerungs-Hinweise pro Position; Appetit-Faktor ersetzt |

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
- **Konsumprofile** aus `quantities_v0.2.json`: Essen (klein 0,8 · normal 1,0 · groß 1,25) wirkt auf Positionen mit Profil `eat`, Trinken (keiner 0 · wenig 0,5 · normal 1,0 · viel 1,75) auf Positionen mit Profil `drink`; Positionen mit `none` sind profilunabhängig
- Jede berechnete Menge kann überschrieben oder als Gesamtzahl eingegeben werden; überschriebene Mengen bleiben bei Änderungen von Crew oder Tagen stehen
- Urlaubszuschlag aus `quantities_v0.2.json`
- Mengen pro Woche werden anteilig auf die Törnlänge umgerechnet und auf sinnvolle Packungsgrößen aufgerundet
- Positionen für nicht vegetarische bzw. vegetarische Crewmitglieder werden nur für diese gezählt
- Alkohol nur für Erwachsene, Startwerte von der Crew einstellbar
- **Charter-Modus:** Technik-Positionen mit Kennzeichen *Charter ausgeblendet* sind beim Charter eingeklappt und beim eigenen Boot sichtbar
- Ernährungs-Tags dienen nur zum Filtern (z. B. glutenfrei, vegan) und sind kein Allergie-Schutz; die App weist darauf hin, dass Zutaten auf der Packung geprüft werden müssen

## Einlagerungs-Hinweise

Nach dem Einkauf wird die Liste zur Checkliste fürs Verstauen. In warmen Revieren (`hot_or_remote`) standardmäßig aktiv, sonst optional.

| Kennung | Hinweis |
| --- | --- |
| `remove_cardboard` | Kartons an Land auspacken, nicht an Bord nehmen; Inhalt in dichte Dosen oder Beutel umfüllen |
| `wash_produce` | Waschen (z. B. Essigwasser) und gut trocknen, luftig lagern |
| `potatoes_onions` | Trocken und dunkel lagern, Kartoffeln getrennt von Zwiebeln, nicht waschen |
| `remove_labels` | Etiketten entfernen, Inhalt mit wasserfestem Stift auf den Deckel schreiben |
| `eggs` | Kühl und dunkel lagern; ungekühlte Eier regelmäßig wenden |
| `cool_first` | Sofort in den Kühlschrank und zuerst verbrauchen |
| `keep_dry` | Trocken und dicht verpackt lagern |

## Frühstück

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Brot | 0,5 | Laib | per_person_week | alle | eat | Backwaren | – | research | plus taeglich frisches Brot vor Ort; Tags: gluten |
| Butter | 125 | g | per_person_week | alle | eat | Molkerei und Kühlregal | – | research | Tags: dairy |
| Marmelade | 100 | g | per_person_week | alle | eat | Trockenware | – | estimate |  |
| Honig | 50 | g | per_person_week | alle | eat | Trockenware | – | estimate |  |
| Müsli / Cornflakes | 250 | g | per_person_week | alle | eat | Trockenware | remove_cardboard | estimate | Tags: gluten |
| Eier | 12 | Stück | per_person_week | alle | eat | Molkerei und Kühlregal | eggs, remove_cardboard | research | Tags: egg |
| Käse gemischt | 250 | g | per_person_week | alle | eat | Molkerei und Kühlregal | – | research | Tags: dairy |
| Aufschnitt, Schinken, Salami | 200 | g | per_person_week | nicht vegetarische Crewmitglieder | eat | Fleisch und Fisch | cool_first | research | Tags: meat |
| Joghurt | 250 | g | per_person_week | alle | eat | Molkerei und Kühlregal | – | research | Tags: dairy |
| Milch | 0,5 | l | per_person_week | alle | eat | Molkerei und Kühlregal | – | research | Tags: dairy |

## Grundnahrung

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pasta | 130 | g | per_person_board_evening | alle | eat | Trockenware | remove_cardboard | research | Hauptgericht; als Beilage 50–80 g; Tags: gluten |
| Reis | 70 | g | per_person_board_evening | alle | eat | Trockenware | remove_cardboard, keep_dry | research |  |
| Kartoffeln | 225 | g | per_person_board_evening | alle | eat | Obst und Gemüse | potatoes_onions | research |  |
| Tomatensauce / gehackte Tomaten | 4 | Dose | per_crew_week | alle | none | Konserven | remove_labels | research |  |
| Konserven (Thunfisch, Mais, Bohnen) | 2 | Dose | per_person_week | alle | eat | Konserven | remove_labels | estimate |  |
| Brühe / Suppenwürfel | 1 | Packung | per_crew_week | alle | none | Trockenware | – | estimate |  |

## Saucen und Würzen

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Olivenöl | 1 | l | per_crew_week | alle | none | Trockenware | – | research |  |
| Essig | 1 | Flasche | per_trip | alle | none | Trockenware | – | estimate |  |
| Salz | 1 | Packung | per_trip | alle | none | Trockenware | – | estimate | kann von zu Hause mitgebracht werden |
| Pfeffer | 1 | Packung | per_trip | alle | none | Trockenware | – | estimate |  |
| Zucker | 500 | g | per_crew_week | alle | none | Trockenware | – | estimate |  |
| Gewürzmischung (Oregano, Paprika, Curry …) | 1 | Set | per_trip | alle | none | Trockenware | – | estimate | am besten von zu Hause mitbringen |
| Sojasauce | 1 | Flasche | per_trip | alle | none | Trockenware | – | estimate | Tags: gluten |
| Ketchup | 1 | Flasche | per_crew_week | alle | none | Trockenware | – | estimate |  |
| Senf | 1 | Tube | per_trip | alle | none | Trockenware | – | estimate |  |
| Mayonnaise | 1 | Tube | per_crew_week | alle | none | Trockenware | – | estimate | Tags: egg |
| Pesto | 1 | Glas | per_crew_week | alle | none | Trockenware | – | estimate | Tags: nuts, dairy |

## Frisches

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Obst gemischt | 1,5 | kg | per_person_week | alle | eat | Obst und Gemüse | wash_produce | research | frisch zuerst, unterwegs nachkaufen |
| Gemüse und Salat für Mittagessen | 1 | kg | per_person_week | alle | eat | Obst und Gemüse | wash_produce | research | frisch nachkaufen |
| Gemüse für Bordabende | 175 | g | per_person_board_evening | alle | eat | Obst und Gemüse | wash_produce | research | als Hauptgericht ca. 400 g |
| Zwiebeln | 0,5 | Stück | per_person_board_evening | alle | eat | Obst und Gemüse | potatoes_onions | estimate |  |
| Knoblauch | 1 | Knolle | per_crew_week | alle | none | Obst und Gemüse | potatoes_onions | estimate |  |
| Zitronen | 0,5 | Stück | per_person_week | alle | eat | Obst und Gemüse | wash_produce | estimate |  |
| Fleisch oder Fisch für Bordabende | 175 | g | per_person_board_evening | nicht vegetarische Crewmitglieder | eat | Fleisch und Fisch | cool_first | research | Fleisch ohne Knochen 150–200 g, Fischfilet 150–180 g; Tags: meat, fish |
| Vegetarische Alternative (Halloumi, Tofu, Hülsenfrüchte) | 150 | g | per_person_board_evening | vegetarische Crewmitglieder | eat | Molkerei und Kühlregal | cool_first | estimate |  |

## Süßes und Snacks

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Schokolade | 200 | g | per_person_week | alle | eat | Süßwaren | – | estimate | Urlaubszuschlag beachten; Tags: dairy, nuts |
| Kekse | 200 | g | per_person_week | alle | eat | Süßwaren | remove_cardboard | estimate | Tags: gluten |
| Gummibärchen / Süßigkeiten | 100 | g | per_person_week | alle | eat | Süßwaren | – | estimate |  |
| Nüsse | 150 | g | per_person_week | alle | eat | Süßwaren | – | estimate | Tags: nuts |
| Chips | 150 | g | per_person_week | alle | eat | Süßwaren | – | estimate |  |

## Getränke ohne Alkohol

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Trinkwasser | je Revier | l | per_person_day_region | alle | none | Getränke | remove_cardboard | research | Menge je Revier aus quantities_v0.1.json; Kochwasser aus dem Bordtank |
| Softdrinks | 0,5 | l | per_person_day | alle | none | Getränke | remove_cardboard | estimate |  |
| Saft | 1 | l | per_person_week | alle | none | Getränke | – | estimate |  |
| Kaffee | 15 | g | per_person_day | alle | none | Trockenware | – | estimate | ca. 2 Tassen |
| Tee | 2 | Beutel | per_person_day | alle | none | Trockenware | – | estimate |  |
| Kaffeemilch / H-Milch | 0,5 | l | per_person_week | alle | none | Molkerei und Kühlregal | – | estimate | Tags: dairy |

## Getränke mit Alkohol

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Bier | 1 | Dose/Flasche 0,5 l | per_adult_evening | Erwachsene | drink | Getränke | remove_cardboard | estimate | Startwert, von der Crew einstellbar; Tags: alcohol, gluten |
| Wein | 0,25 | l | per_adult_evening | Erwachsene | drink | Getränke | – | estimate | Startwert; Praxisberichte liegen teils deutlich höher; Tags: alcohol |
| Spirituosen für den Sundowner | 1 | Flasche 0,7 l | per_trip | Erwachsene | drink | Getränke | – | estimate | standardmäßig abgewählt; Tags: alcohol |

## Haushalt

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Spülmittel | 1 | Flasche | per_crew_week | alle | none | Haushalt | – | research | wird laut Charter-Leitfäden oft vergessen |
| Schwämme | 2 | Stück | per_crew_week | alle | none | Haushalt | – | estimate |  |
| Geschirrtücher | 2 | Stück | per_trip | alle | none | Haushalt | – | estimate | oft von zu Hause mitgebracht |
| Küchenrolle | 0,5 | Rolle | per_person_week | alle | none | Haushalt | keep_dry | estimate |  |
| Müllsäcke | 1 | Rolle | per_trip | alle | none | Haushalt | – | research |  |
| Alufolie | 1 | Rolle | per_trip | alle | none | Haushalt | – | estimate |  |
| Frischhaltebeutel | 1 | Packung | per_trip | alle | none | Haushalt | – | estimate |  |
| Streichhölzer / Gasfeuerzeug | 1 | Stück | per_trip | alle | none | Haushalt | keep_dry | research | für den Gasherd |
| Grillkohle | 1 | Sack | per_trip | alle | none | Haushalt | – | research | nur wenn Grill an Bord; standardmäßig abgewählt |

## Hygiene

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Toilettenpapier (bordtauglich, schnell auflösend) | 2 | Rolle | per_person_week | alle | none | Drogerie | keep_dry | estimate | Bordtoiletten verstopfen leicht; Hinweis der Basis beachten |
| Handseife | 1 | Flasche | per_trip | alle | none | Drogerie | – | estimate |  |
| Duschgel (biologisch abbaubar) | 0,25 | Flasche | per_person_week | alle | none | Drogerie | – | estimate |  |
| Sonnencreme | 100 | ml | per_person_week | alle | none | Drogerie | – | estimate |  |

## Bord und Technik

| Position | Menge | Einheit | Basis | Gilt für | Profil | Abteilung | Einlagerung | Quelle | Hinweis |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Batterien AA | 8 | Stück | per_trip | alle | none | Technik / Bootszubehör | keep_dry | estimate | Stirnlampen, Handfunkgerät |
| Batterien AAA | 8 | Stück | per_trip | alle | none | Technik / Bootszubehör | keep_dry | estimate |  |
| Stirnlampe | 1 | Stück | per_person_trip | alle | none | Technik / Bootszubehör | – | estimate | prüfen, ob vorhanden |
| Wäscheklammern | 20 | Stück | per_trip | alle | none | Haushalt | – | estimate |  |
| Kabelbinder | 1 | Packung | per_trip | alle | none | Technik / Bootszubehör | – | estimate | Charter ausgeblendet |
| Gewebeband | 1 | Rolle | per_trip | alle | none | Technik / Bootszubehör | – | estimate | Charter ausgeblendet |
| Kriechöl (z. B. WD-40) | 1 | Dose | per_trip | alle | none | Technik / Bootszubehör | – | estimate | Charter ausgeblendet |
| Motoröl | 1 | l | check | alle | none | Technik / Bootszubehör | – | estimate | Stand prüfen; beim Charter Sache der Basis; Charter ausgeblendet |
| Ersatzsicherungen | 1 | Set | check | alle | none | Technik / Bootszubehör | – | estimate | Charter ausgeblendet |

## Offene Punkte

- [ ] Baseline der Mengen klären: Startwerte mit `estimate` und Profilfaktoren kalibrieren
- [ ] Packungsgrößen pro Land für das Aufrunden festlegen
- [ ] Übersetzung der Positionsnamen in FR, ES, PT, HR, EN
