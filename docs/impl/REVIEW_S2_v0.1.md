# Review S2 – Mengen-Engine v0.1

Stand: 24.09.2026 · Reviewer: Claude · Grundlage: Commit `5439a1c`, PRD v0.14/v0.15, Katalog v0.6

## Gesamteindruck

Solide Struktur: reine Dart-Engine, Katalog und Mengen werden aus JSON gelesen, Crew-Fragen, Reserve, Split `equal`/`each`, Portionen und Überschreibungen sind umgesetzt, 14 Tests. Es gibt aber mehrere inhaltliche Fehler, die grüne Tests nicht aufdecken, weil die Tests nur Rohbedarfe und nicht die resultierenden Packungen prüfen. Einige Ursachen liegen in unseren Dokumenten (Katalog-Einheiten), diese sind mit Katalog v0.7 und Quantities v0.4 behoben.

## Befunde

| Nr | Schwere | Befund | Ursache | Behebung |
| --- | --- | --- | --- | --- |
| 1 | kritisch | `applies_to` prüft auf `meat_eaters`/`non_vegetarians`, der Katalog nutzt `non_vegetarian` und `vegetarian`. Folge: Vegetarier bekommen Fleisch mitgerechnet, die vegetarische Hauptkomponente wird für alle berechnet | Code | Exakt die Werte `all`, `non_vegetarian`, `vegetarian`, `adults` unterstützen; unbekannter Wert = Fehler |
| 2 | kritisch | Bedarfseinheit und Packungseinheit werden nicht abgeglichen. Beispiele: Spülmittel "1 Flasche" / 0,5 l ergibt 2 Flaschen, Duschgel 1,25 / 0,25 l ergibt 5 Flaschen, Konserven "10 Dosen" / 160 g ergibt 1 Packung, Bier in Portionen / 0,5 l ergibt doppelte Menge | Katalog + Code | Katalog v0.7: Einheiten vereinheitlicht, `Packung` = Anzahl Packungen. Engine: g/kg und ml/l umrechnen, `Packung` direkt als Packungszahl, sonst Fehler |
| 3 | hoch | Gruppenausgleich (`_applyGroupBalancing`) ist leer, die Regel aus dem PRD ist nicht umgesetzt; zudem würde er Einheiten mischen | Code | Nach `quantities_v0.4.json` → `rounding.group_balancing` umsetzen, in gemeinsamer Einheit |
| 4 | hoch | Frisches wird automatisch nach Haltbarkeit auf "unterwegs" aufgeteilt. Das widerspricht PRD v0.14 (Einkaufsstopps und Zuordnung legt der Nutzer fest) | unsere Doku war widersprüchlich | Keine automatische Aufteilung mehr. Engine liefert Gesamtbedarf; beim Abrunden von Frischem nur einen Rest-Hinweis |
| 5 | mittel | Urlaubszuschlag wird geladen, aber nie angewendet | Code | Auf die Gruppen aus `factors.holiday_snack_drink_uplift.applies_to_groups` anwenden |
| 6 | niedrig | Wasser wird über die Gruppen-ID `water` erkannt statt über die Basis `per_person_day_region` | Code | Generisch über die Basis lösen |
| 7 | niedrig | Kühlschrank-Schätzung rechnet Stückzahlen pauschal mit 60 ml | Code | Vorerst akzeptabel, als Näherung dokumentieren |

**Klarstellung (kein Fehler):** `per_adult_evening` zählt alle Abende, auch Restaurantabende (Sundowner an Bord). So umgesetzt, jetzt in `quantities_v0.4.json` dokumentiert.

## Fehlende Tests

- Katalog-Validierungstest über ALLE Varianten: Einheiten kompatibel, `applies_to` gültig, IDs eindeutig, `Portion` nur mit `portion`
- Vegetarier: Fleischgruppe ohne Vegetarier, vegetarische Hauptkomponente nur für Vegetarier
- Packungszahlen (nicht nur Rohbedarf) für: Bier, Wein, Spülmittel, Duschgel, Konserven, Brot mit mehreren Varianten, Spaghetti/Reis über Portionen
- Gruppenausgleich: Summe deckt Bedarf, kein Überschuss über eine volle Packung hinaus
- Urlaubszuschlag nur auf die vorgesehenen Gruppen

## Auftrag

Umsetzung als Slice **S2a – Korrektur Mengen-Engine** (siehe Slice-Plan v0.9), vor S4 bzw. vor dem nächsten Slice.
