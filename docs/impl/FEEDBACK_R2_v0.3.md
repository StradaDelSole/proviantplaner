# Feedback-Runde 2 v0.3 – Praxistest auf dem Handy

Stand: 26.09.2026 · Quelle: Test durch den Product Owner auf dem eigenen Android-Handy (nach UX-A bis UX-C) · **Freigegeben (siehe README).** Vorrangig gegenüber PRD, UX-Konzept und Design-Brief.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 26.09.2026 | Entwurf Navigation und sichtbare Hauptaktionen (aufgegangen im UX-Konzept) |
| v0.2 | 26.09.2026 | Haltbarkeitsgrenze für Vorschläge, Gewichtung haltbarer Varianten, Tiefkühlfach, Katalogergänzungen, Layout-Überlauf, Übernahmen aus der Wettbewerbsanalyse |
| v0.3 | 26.09.2026 | Bedienregel Zahleneingabe (Wählrad nur für Törndauer), Bordtank nur bei trinkbarem Tankwasser, Katalog v0.10 und Quantities v0.6 umgesetzt, freigegeben |

## 1. Vorschläge respektieren die Haltbarkeit (kritisch)

Beobachtet: 21 Tage Atlantik, 5 Personen → Vorschlag 41 × 250 g Champignons (hält ca. 4 Tage) und 34 × 250 g Baguette (hält 1 Tag). Ursache: Der Gesamtbedarf über alle Tage wird auf die gewählten Varianten verteilt, ohne Haltbarkeit.

**Regel:**
- Der Vorschlag für eine Variante mit Haltbarkeit H Tagen deckt höchstens den Bedarf bis zum Ende ihrer Haltbarkeit (an Bord, siehe Punkt 3), gerechnet ab dem Einkauf.
- Gibt es Einkaufsstopps, gilt der Vorschlag jeweils bis zum nächsten Stopp (höchstens H Tage). **Keine automatische Verteilung** auf Stopps: Die Liste zeigt je Stopp den Vorschlag, die Crew übernimmt.
- Der nicht gedeckte Rest erscheint als neutraler Hinweis: "Rest ca. X – bei einem späteren Einkauf einplanen".
- Gibt es für die restliche Dauer keinen Stopp, Hinweis auf haltbare Varianten derselben Gruppe bzw. passende Alternativen ("Für 17 Tage ohne Einkauf eignen sich: …").

## 2. Haltbare Varianten tragen bei langen Strecken den Großteil

Bei Aufteilung "gleichmäßig" wird der Bedarf heute gleich auf alle gewählten Varianten verteilt. **Neu:** Übersteigt die Dauer bis zum nächsten Stopp die Haltbarkeit einer Variante, bekommt diese nur ihren Haltbarkeitsanteil; der übrige Bedarf geht an die haltbaren Varianten der Gruppe (z. B. Knäckebrot, Pumpernickel, Toastbrot, Aufbackbrötchen statt Baguette). Anteilsregler des Nutzers haben Vorrang.

## 3. Tiefkühlfach

- Setup "Essen an Bord": Kühlschrank (Liter oder "kein Kühlschrank") und **Tiefkühlfach ja/nein**, optional Liter.
- Haltbarkeit an Bord je Variante: Kühlware nach Kühlschrank-Haltbarkeit; Fleisch/Fisch mit Tiefkühlfach deutlich länger (Katalog: neues Feld `shelf_life_frozen_days`), Hinweis "gleich einfrieren".
- Ohne Tiefkühlfach: Frischfleisch nur für die ersten Tage, danach Hinweis auf haltbare Alternativen (luftgetrocknete Wurst, Chorizo, Dosenfleisch, Thunfisch, Linsen).
- Tiefkühlware (TK-Gemüse, TK-Garnelen, TK-Fleisch) nur vorschlagen, wenn ein Tiefkühlfach vorhanden ist.
- Kapazität: Passt die übernommene Kühl- bzw. Tiefkühlware voraussichtlich nicht ins angegebene Volumen, neutraler Hinweis; nichts wird gestrichen.

## 4. Katalog: lang haltbare Varianten ergänzen

Fehlend für Langfahrt: Weißkohl, Rotkohl, Kürbis, Rote Bete, Sellerie, Gemüsekonserven (Erbsen/Karotten, Bohnen, Mais existiert), Pilzkonserven, getrocknete Pilze, H-Sahne, Trockenobst, Knäckebrot-Varianten, Konservenbrot/Dosenbrot, Tiefkühlvarianten. **Umgesetzt in `data/catalog_v0.10.json`** (20 neue Varianten, Felder `chill` und `shelf_life_frozen_days`). Gemini liest nur.

## 5. Layout-Überlauf in der Vorschlagszeile

In der Produktliste erscheint bei "Vorschlag" das gelb-schwarz gestreifte Warnsymbol (Flutter-Überlauf, ca. 20 Pixel). Zeilen müssen bei langen Namen und großen Zahlen umbrechen bzw. kürzen (Expanded/Flexible, Ellipsis), auch bei Schriftgröße 200 %. **Test:** Widget-Test ohne Overflow-Fehler mit langem Produktnamen, großer Menge und Textskalierung 2.0, in hell, dunkel und Nachtwache.

## 6. Übernahmen aus der Wettbewerbsanalyse (v0.4)

- **Bordtank beim Trinkwasser:** Felder "Wassertank an Bord (l)" und Schalter "Tankwasser ist trinkbar" (Standard aus). Nur wenn trinkbar: Vorschlag Flaschenwasser = Bedarf − Tankinhalt, mindestens 1,5 l pro Person Reserve (`data/quantities_v0.6.json` → `water_tank`)
- **Gesamtgewicht und -volumen** der übernommenen Liste als kleine Info über der Liste
- **WhatsApp-Bestellung** bei "Liefern lassen" als erste Versandoption

## 7. Bedienregel für Zahleneingaben

| Feld | Bedienung |
| --- | --- |
| Personen, Stückzahl in der Liste | Plus/Minus mit großen Tippflächen (≥ 48 dp); Zahl antippen öffnet direkte Eingabe |
| Törndauer (1–180 Tage) | Schnellwahl-Chips (1 Woche, 2 Wochen, 1 Monat, 3 Monate, 6 Monate) plus **Wählrad in einem Sheet** für den genauen Wert |
| Restaurantbesuche, Kühlschrank-/Tiefkühl-/Tank-Liter | Plus/Minus bzw. Zahlenfeld |
| Datum, Uhrzeit | Standard-Auswahl des Systems |

Wählräder nur dort; überall sonst keine Wählräder (Seegang, Barrierefreiheit, Android-Üblichkeit).

## 8. Technische Aufräumarbeit

- Umrechnung alter Revierwerte nur an einer Stelle (Migration); keine freien Texte wie `'mediterranean_summer'`/`'hot_or_remote'` in Engine und Services (Regel 1)

## Offen / wird ergänzt

- Weitere Punkte aus dem laufenden Handytest
