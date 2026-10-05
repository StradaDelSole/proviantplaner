# FIX-A – Navigation & Lifecycle Regression Repair

Stand: 05.10.2026  
Status: **OWNER-FREIGEGEBEN – vor PIVOT1 umzusetzen**

Grundlage:
- `docs/impl/REGRESSION_AUDIT_2026-10-05.md`
- Issues #11–#19
- `docs/design/UX_KONZEPT_v0.6.md`

## Ziel

Den aktuellen realen Törnflow wieder vollständig nutzbar und deterministisch machen, bevor PIVOT1 die Listenlogik umbaut.

## Pflicht-Reconciliation vor Code

1. `origin/main` aktualisieren.
2. Router, TripOverview, ShoppingList, ShoppingMode, StorageChecklist, KittyScreen, SettlementScreen, TripTimeline, TripService und relevante Tests lesen.
3. Für jedes Issue #11–#19 klassifizieren:
   - reproduzierbar
   - bereits indirekt gelöst
   - superseded
4. Keine Domainfunktion entfernen, nur weil sie aktuell verwaist ist.

## Scope

### A. Routingvertrag
Törn-Übersicht bleibt Hub.

Für jeden Task-Screen explizit:
- wie wird er geöffnet?
- wohin führt „fertig“?
- wohin führt Back/System-Back?

Keine Mischung `go()` rein / `pop()` raus ohne definierten Stack.

### B. Bordkasse wieder vollständig erreichbar
Die Funktionen aus `KittyScreen` müssen über sichtbare UI erreichbar sein oder sauber in den Overview integriert werden.

Keine doppelte/inkonsistente Bordkassenlogik.

### C. Einkaufsstopps wieder erreichbar
Anlegen, Bearbeiten, Löschen direkt aus dem neuen Hub-/Listenflow.

Die alte Timeline darf nicht die einzige versteckte Zugangsstelle bleiben.

### D. Lifecycle
Eine einzige Workflow-Wahrheit etablieren.

`TripPhase` bevorzugt als persistierter Status nutzen, soweit fachlich passend.

Nicht `_items.isNotEmpty` als Beweis verwenden, dass eine Nutzerliste fertig ist.

### E. Einkaufsabschluss
- „streichen“ führt echte Datenoperation aus
- „später“ verschiebt Rest auf einen späteren Stopp
- Einlagerung hat deterministischen Abschluss
- danach Overview / sinnvoller nächster Schritt

### F. Törn bearbeiten
Mindestens alle weiterhin aktuellen Setup-Daten erreichbar/editierbar.

Mit #6 Bootsprofilen kompatibel halten; PIVOT3 nicht vorwegnehmen.

### G. Journey Tests
Neue Router-/Journey-Testdatei, die reale Nutzerpfade ausführt.

## Optional im selben Slice, falls ohne Scope-Risiko
- #16 Lokalisierungs-Hardcodes
- #17 No-op-Settings

Wenn nicht: separater FIX-B unmittelbar nach FIX-A und vor Store-Arbeiten.

## Nicht in FIX-A
- PIVOT1 Listenmodell
- PIVOT2 Review Engine
- Bootsprofile selbst
- Watermaker selbst
- CAT1
- B3/B4/B5
- Store-Publikation

## Abnahme
Siehe Regression Audit Definition of Done.

Zusätzlich:
- `flutter analyze` sauber
- vollständige Flutter-Test-Suite grün
- bestehende Tests nicht einfach löschen, sondern falsche Annahmen korrigieren
- Bericht `docs/impl/FIX-A_bericht.md`
- Commit + Push
- STOP für Review vor PIVOT1
