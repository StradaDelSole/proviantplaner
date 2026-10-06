# PIVOT1 Independent Review 2 – 06.10.2026

Reviewed amendment HEAD: `94ce6f0c6875d6ca97d408097cacd5bf42328825`

Status: **MICRO-AMENDMENT REQUIRED – PIVOT1 noch nicht owner-accepted**

## Ergebnis

Die Findings A–E aus `docs/impl/PIVOT1_review_2026-10-06.md` sind inhaltlich weitgehend geschlossen.

### Verifiziert geschlossen

#### Finding A – AssistClassifier
Verifiziert:
- tote IDs `snacks` / `sauces_special` entfernt
- reale Kataloggruppen `savory_snacks`, `sweets`, `spread_sweet`, `spread_savory`, `spirits` verwendet
- reale Preference-Varianten für Pesto/Tofu/Spezialsaucen/ausgewählte Käse hinterlegt
- konfigurierter Mapping-Bestand wird automatisiert gegen `catalog_v0.10` validiert
- Regressionsbeispiele Chips, BBQ-Sauce, Feta und Rum ergeben 0 automatische Menge
- Bier bleibt dokumentiert `guided`; diese Produktentscheidung ist für PIVOT1 vertretbar, weil der Nutzer Bier zunächst aktiv auswählt und der vorhandene Crew-Drinking-Kontext nur als Richtwert dient

**Status: CLOSED.**

#### Finding B – direkter Adopt-Bypass
Verifiziert:
- sichtbarer Add-Button in `ShoppingListItemRow` ruft nicht mehr direkt `adoptItem()` auf
- Zeilen-Tap und Add-Button öffnen beide `AddOrEditItemSheet(isAdding: true)`
- Test prüft zusätzlich, dass vor Speichern kein DB-Adopt erfolgt

**Status: CLOSED.**

#### Finding C – reale Search/Add-Journey
Verifiziert:
- echter `ShoppingListScreen`
- echter Empty-State-Suchbutton
- echter `CatalogSearchDelegate`
- Texteingabe `pesto`
- echter Treffer-Tap
- echtes modales `AddOrEditItemSheet`
- Mengenänderung
- Speichern
- Rückkehr zur echten Liste
- SQLite-Persistenz mit 2 Packungen

Der neue `parentContext` + `addPostFrameCallback`-Pfad für Treffer-Taps ist im Code vorhanden und durch die Journey abgedeckt.

**Status: CLOSED mit einem verbleibenden Testdetail unter Micro-Finding 1.**

#### Finding D – Recalculation-Stabilität
Verifiziert:
- Daueränderung über `TripService.updateTripDetails(...)` und damit echte Recalculation
- Crew-Erweiterung + explizite `TripService.recalculateTrip()`
- Preference Pesto 2 bleibt 2
- Guided Override Brot 5 bleibt 5
- Custom Item 3 bleibt 3

**Status: CLOSED.**

#### Finding E – ShoppingModeScreen-Isolation
Verifiziert:
- echter `ShoppingModeScreen`
- übernommenes Spaghetti sichtbar
- Custom Item sichtbar
- nicht übernommene Kandidaten Butter/Salz/Vollmilch nicht sichtbar

**Status: CLOSED.**

---

## Micro-Finding 1 – E2E-Journey behauptet Package-Selection, testet sie aber nicht

Severity: **LOW / acceptance-proof gap**

PIVOT1 verlangt den Flow:

`Search → Variant → Package Size → Quantity → Add`

Der neue Test 13 beweist Search → Treffer → Sheet → **Quantity** → Add.

Er wählt jedoch keine andere `ChoiceChip`-Gebindegröße aus und prüft auch keine persistierte `customPackageSize`.

Auch der ältere Test 3 prüft nur, dass `ChoiceChip`-Widgets sichtbar sind. Er tippt keinen Chip an.

Damit ist die Produktimplementierung der Gebindeauswahl im Code vorhanden, aber der behauptete vollständige E2E-Nachweis ist unvollständig.

### Required micro-fix

Erweitere Test 13 oder einen gleichwertigen realen Journey-Test:

1. nach Öffnen des `AddOrEditItemSheet` eine **andere** sichtbare Packungsgröße auswählen
2. Menge verändern
3. speichern
4. nach Reload prüfen:
   - gewünschte Packungszahl
   - gewählte/custom Packungsgröße wurde persistiert

Der Testname/Bericht darf danach weiterhin "Package + Quantity" behaupten.

---

## Micro-Finding 2 – No-result → Custom Item nutzt noch alten Search-Context

Severity: **LOW/MEDIUM – real user path not hardened**

Im normalen Trefferpfad wurde korrekt eingeführt:

- `parentContext`
- `close(...)`
- `addPostFrameCallback`
- `targetContext.mounted`
- danach Sheet öffnen

Dasselbe wurde für den zusätzlichen Custom-Item-ListTile am Ende der Ergebnisliste umgesetzt.

Aber im **matches.isEmpty**-Pfad bleibt aktuell:

`close(context, null);`
`CustomItemSheet.show(context, ...);`

also der alte SearchDelegate-Kontext direkt nach dem Pop.

Das ist genau der Navigationstyp, der im Trefferpfad durch den Amendment gehärtet wurde. Außerdem ist "kein Treffer → eigene Position" ausdrücklich Teil des owner-accepted PIVOT1-Produktflows.

### Required micro-fix

Den No-result-Button auf denselben sicheren Ablauf umstellen:

- `targetContext = parentContext ?? context`
- Search schließen
- Post-frame
- mounted prüfen
- `CustomItemSheet.show(targetContext, ...)`

Dazu einen realen Widget-Test:

1. echten ShoppingListScreen öffnen
2. Suche öffnen
3. Suchbegriff ohne Treffer eingeben
4. `als eigene Position hinzufügen` antippen
5. CustomItemSheet muss sichtbar werden
6. optional minimal speichern und Persistenz prüfen; mindestens Sheet-Öffnung muss bewiesen sein

---

## QA

Gemini meldet:
- `flutter analyze`: No issues found
- `flutter test`: 261/261 grün

Für Commit `94ce6f0...` sind keine GitHub Actions Workflow-Runs oder Commit-Statuses sichtbar. Die relevanten Testimplementierungen wurden unabhängig im Repo geprüft.

## Scope des Micro-Amendments

Nur:
1. Package-Selection im echten Search/Add-Journey tatsächlich ausführen + persistiert prüfen
2. No-result → Custom Item auf den sicheren Parent-Context/Post-Frame-Pfad umstellen + testen
3. Bericht/CHANGELOG bei Bedarf korrigieren
4. `flutter analyze`
5. komplettes `flutter test`
6. Commit/Push
7. STOP

Nicht starten:
- PIVOT2
- PIVOT3
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store

## Decision

Der PIVOT1-Kern und die fünf ursprünglichen Review-Findings sind fachlich geschlossen.

**Vor Owner Acceptance ist nur noch dieses Micro-Amendment erforderlich.**
