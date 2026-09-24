Slice: S2a – Korrektur Mengen-Engine nach Review
Umgesetzt:
- Befund 1 (applies_to & Vegetarier): Exakte Unterstützung der Werte `all`, `non_vegetarian`, `vegetarian`, `adults` als typisiertes Enum `AppliesTo`. Unbekannte Werte werfen beim Parsen sofort eine `FormatException` mit Dateiname, ID und Feld. Vegetarier schließen Fleisch/Fisch aus (`meat_fish`), Fleischesser schließen vegetarische Hauptkomponenten aus (`veg_protein`), Kinder werden bei `adults` ausgeschlossen.
- Befund 2 (Einheiten-Abgleich & Packungszahlen): Strenge `UnitConverter`-Validierung (nur g<->kg und ml<->l; `Portion` nur bei vorhandener `variant.portion`; `Packung` bedeutet direkte Packungszahl ohne Einheitenmischung; alle anderen Kombinationen werfen `FormatException`). Korrekte Packungsberechnung für Spülmittel (1 Flasche statt 2), Duschgel (2 Flaschen bei 5 Personen statt 5), Konserven, Spaghetti/Reis über Portionen, Bier und Wein.
- Befund 3 (Gruppenausgleich): `_applyGroupBalancing` nach `quantities_v0.4.json` -> `rounding.group_balancing` in einheitlicher Basis implementiert: Unterdeckung gleicht die Variante mit kleinstem Packmaß aus; Überdeckung (> 1 volle Packung Überschuss) wird abgebaut.
- Befund 4 (Keine automatische Aufteilung von Frischem): Automatische Unterwegs-Aufteilung entfernt; Gesamtbedarf wird vollständig berechnet; beim Abrunden frischer Artikel mit Überschuss > 25 % wird ein klarer `remainderNotice` im Berechnungsergebnis bereitgestellt.
- Befund 5 (Urlaubszuschlag): Dynamischer Zuschlag (`holidaySnackDrinkUplift = 1.2`) aus `quantities_v0.4.json` wird datengetrieben ausschließlich auf die in `appliesToGroups` hinterlegten Gruppen (`sweets`, `savory_snacks`, `soft`, `juice`, `beer`, `wine`) angewendet.
- Befund 6 (Generische Wasserberechnung nach Revier): Wasserbedarf wird generisch über die Rechenbasis `CalculationBasis.perPersonDayRegion` aufgelöst. Gruppen-Need wird beim Parsen von `water` synthetisiert, sodass die Rechenlogik ohne Stringvergleiche rein auf Basis-Enums rechnet.
- Befund 7 (Kühlschrank-Schätzung): Als Näherung dokumentiert; nutzt Packungsmaße und `UnitConverter`.
- Programmierregeln 1–7 (GEMINI.md v0.4): Feste Enums (`CalculationBasis`, `GroupSplit`, `GroupMode`, `GroupVisibility`, `GroupProfile`, `AppliesTo`, `CatalogDepartment`, `CrewAppetite`, `CrewDrinking`, `EatProfileLevel`, `DrinkProfileLevel`); `QuantityCalculationInput` als Eingabeobjekt (Regel 6, <=4 Parameter); Epsilon-Toleranz (`1e-9`) für Fließkomma-Vergleiche und Runden; Funktionen <= 40 Zeilen; keine unvollständigen Stubs; umfassende Tests mit ausgerechneten Erwartungswerten.

Geänderte/neue Dateien:
- `pubspec.yaml`: Assets auf `catalog_v0.7.json` und `quantities_v0.4.json` aktualisiert
- `lib/features/shopping_list/domain/models/catalog_models.dart`: Typisierte Enums, striktes Fehlerwerfen, synthetisierter GroupNeed für water
- `lib/features/shopping_list/domain/models/quantities_models.dart`: Typisierte Enums und Mengenfaktoren inkl. `holidaySnackDrinkUplift`
- `lib/features/shopping_list/domain/calculation/calculation_result.dart`: `remainderNotice`, bereinigte Ergebniskonstruktion
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`: Vollständiges Refactoring der Engine gemäß Befunden 1–6 und Regeln 1–7
- `lib/features/shopping_list/data/catalog_repository.dart`: Asset-Pfade auf `v0.7` und `v0.4` aktualisiert
- `lib/features/trip/data/trip_service.dart`: Übergabe von `QuantityCalculationInput` und `rawValue` bei Drift-Persistenz
- `lib/features/trip/ui/widgets/crew_member_dialog.dart`: Typisierte Dropdown-Felder mit `EatProfileLevel` und `DrinkProfileLevel`
- `test/features/shopping_list/domain/catalog_validation_test.dart`: Neuer Katalog-Validierungstest über alle Einträge der JSON-Dateien
- `test/features/shopping_list/domain/quantity_engine_test.dart`: Aktualisierte und erweiterte Unit-Tests mit expliziten Rechenwegen und Randfällen
- `test/features/trip/trip_ui_test.dart`: Aktualisierung auf Katalog v0.7 und Quantities v0.4
- `test/features/trip/trip_wizard_and_timeline_test.dart`: Aktualisierung auf Katalog v0.7 und Quantities v0.4
- `docs/impl/S2a_plan.md`: Umsetzungsplan für S2a
- `docs/impl/S2a_bericht.md`: Dieser Abschlussbericht

flutter analyze:
No issues found! (0 Fehler, 0 Warnungen, 0 Lints)

flutter test:
00:47 +45: All tests passed! (45 Tests in der gesamten Testsuite erfolgreich)

Abnahmekriterien:
- Katalog-Validierungstest über alle Varianten grün: erfüllt (`Slice S2a: Katalog-Validierungstest über alle Einträge (Programmierregel 7) Einheiten-Kompatibilität für ALLE Varianten im Katalog (Befund 2 & Regel 4)`)
- Tests für Vegetarier: erfüllt (`Slice S2a: Befund 1 – applies_to & Vegetarier Fleischgruppe schließt Vegetarier aus, vegetarische Gruppe schließt Fleischesser aus`)
- Packungszahlen Bier: erfüllt (`Slice S2a: Festes Referenzbeispiel (PRD v0.16) 5 Erwachsene (1 veg, 1 kein Alk), 7 Tage, Mittelmeer, 4 Bordabende`)
- Packungszahlen Wein: erfüllt (`Slice S2a: Randfälle gemäß Programmierregel 7 Keine Trinker (noAlcohol: true auf Alkohol = 0)`)
- Packungszahlen Spülmittel: erfüllt (`Slice S2a: Befund 2 – Packungszahlen für konkrete Produktgruppen Spülmittel: Bedarf 1 Packung pro Crew/Woche ergibt 1 Flasche`)
- Packungszahlen Duschgel: erfüllt (`Slice S2a: Befund 2 – Packungszahlen für konkrete Produktgruppen Duschgel: per_person_week, 0.25 Packungen pro Person/Woche ergibt 2 Flaschen bei 5 Personen`)
- Packungszahlen Konserven: erfüllt (`Slice S2a: Katalog-Validierungstest über alle Einträge (Programmierregel 7) Einheiten-Kompatibilität für ALLE Varianten im Katalog (Befund 2 & Regel 4)`)
- Packungszahlen Brot: erfüllt (`Slice S2a: Befund 3 – Gruppenausgleich (group_balancing) Brot-Gruppe deckt Gesamtbedarf und baut Überschuss > 1 volle Packung ab`)
- Packungszahlen Spaghetti/Reis über Portionen: erfüllt (`Slice S2a: Befund 2 – Packungszahlen für konkrete Produktgruppen Spaghetti über Portionen: 130 g je Portion in 500 g Packungen`)
- Gruppenausgleich: erfüllt (`Slice S2a: Befund 3 – Gruppenausgleich (group_balancing) Brot-Gruppe deckt Gesamtbedarf und baut Überschuss > 1 volle Packung ab`)
- Urlaubszuschlag: erfüllt (`Slice S2a: Befund 5 – Urlaubszuschlag (holiday_snack_drink_uplift) Wird nur auf vorgesehene Gruppen angewendet`)

Offen / Risiken:
- S4 (Vorratsliste): Noch nicht umgesetzt (wird im nächsten Slice S4 direkt ohne veraltete "unterwegs"-Verteilung gebaut).

Annahmen / Abweichungen vom PRD:
- keine

Selbstprüfung Programmierregeln 1–7:
- Regel 1 (Feste Typen): Eingehalten. Sämtliche Modus-, Basis-, Profil-, Aufteilungs-, Sichtbarkeits- und Crew-Werte sind strenge Enums (`CalculationBasis`, `GroupSplit`, `AppliesTo`, etc.). Unbekannte Werte werfen sofort `FormatException`. Keine Stringvergleiche in der Rechenlogik.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine leeren Methoden, keine Stubs, keine TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien sind mit konkreten Testnamen belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Alle Faktoren, Uplifts und Gruppenlisten stammen aus `catalog_v0.7.json` und `quantities_v0.4.json`. Einheitenkonvertierung ausschließlich g<->kg und ml<->l; `Packung` bedeutet reine Packungsanzahl.
- Regel 5 (Kommazahlen mit Toleranz): Eingehalten. Vergleiche und Runden nutzen `epsilon = 1e-9`.
- Regel 6 (Struktur): Eingehalten. Methoden <= 40 Zeilen; `QuantityCalculationInput` fasst Aufrufparameter zusammen; gemeinsame Hilfsmethoden für Berechnungs- und Ergebnisobjekte.
- Regel 7 (Tests): Eingehalten. Tests prüfen sichtbare Packungszahlen; Rechnungen stehen als Kommentar in den Tests; `catalog_validation_test.dart` prüft alle Katalogeinträge; Randfälle (1 Person, 14 Tage, 0 Bordabende, nur Kinder, alle Vegetarier, keine Trinker, überschriebene Packungen) sind abgedeckt. Anpassungen früherer Tests betrafen ausschließlich die Korrektur des fehlerhaften Vorverhaltens (z. B. 0.25 l Packungsdivisor bei Duschgel, alte Gruppen-IDs aus v0.6).

Prüfung vorheriger Slices (S0, S1, S3) gegen Regeln 1–7:
- S0: Vollständig konform.
- S1: Drift-Tabellen in `tables.dart` speichern Enums als `TextColumn`. Beim Laden/Schreiben in Repositories/Services sollte in künftigen Slices eine typisierte Konvertierung erfolgen.
- S3: `CrewMemberDialog` wurde in S2a bereits auf feste Enums (`EatProfileLevel`, `DrinkProfileLevel`) umgestellt. In `TripWizardScreen` werden aktuell noch String-Literale ('normal', etc.) bei den Crew-Buttons übergeben; dies sollte in S4/S5 an `CrewAppetite.rawValue` / `CrewDrinking.rawValue` angepasst werden.

Vorschläge für das PRD:
- In `data/catalog_v0.7.json` besitzt die Gruppe `water` das Feld `"need": null` (mit Note "Menge je Revier aus quantities"). Damit die Engine und der Katalog vollständig synchron über die Rechenbasis `per_person_day_region` laufen können, sollte `data/catalog_vX.Y.json` für `water` direkt `"need": { "amount": 0, "unit": "l", "basis": "per_person_day_region" }` definieren (aktuell beim Parsen in `CatalogGroup.fromJson` synthetisiert).

Commit: S2a: Korrektur Mengen-Engine nach Review (gepusht: ja)
