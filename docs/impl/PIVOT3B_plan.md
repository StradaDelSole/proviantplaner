# PIVOT3-B – Setup Integration & Water Logic – Implementierungsplan

Stand: 06.10.2026  
Status: **OWNER-ACCEPTED SCOPE / NOT RELEASED**

Grundlagen:
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/design/PROVY_UX_DIRECTION_v0.5.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`
- `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT3A_plan.md`
- Issues #4, #5, #6

## Ziel

Nach akzeptierter PIVOT3-A-Foundation die Bootsprofil-Semantik in den sichtbaren Törn-Setup- und Crew-&-Boot-Flow integrieren, den Crewgrößen-Bug beheben und Watermaker fachlich korrekt in die Wasserlogik einführen.

## Start-Gate

PIVOT3-B darf erst beginnen, wenn:
1. PIVOT3-A vollständig implementiert ist.
2. unabhängiger Review PIVOT3-A akzeptabel bewertet.
3. PIVOT3-A ausdrücklich owner-accepted ist.
4. README PIVOT3-B ausdrücklich freigibt.

## Geplanter Pflicht-Scope

### A. Boot auswählen / anlegen / bearbeiten

Im gefrorenen UX-Modell unter Törn-Setup bzw. Crew & Boot:
- gespeichertes Boot auswählen
- neues Boot anlegen
- Bootsprofil bearbeiten
- einmalige Trip-Angaben ohne gespeichertes Profil weiterhin möglich
- technische Profilwerte beim Törn als Snapshot übernehmen
- Overrides gelten nur für diesen Törn
- bestehende Törns niemals automatisch durch Profiländerung verändern
- explizites Resync nur als bewusste Aktion

Keine neue permanente Hauptnavigation.

### B. Crewgröße / Issue #4

- künstlichen Start bei fünf festen Crew-Platzhaltern beseitigen
- zulässige kleinere Crews müssen möglich sein
- +/- und direkte Eingabe bzw. die im finalen UI verwendete mechanische Bedienung konsistent
- Persistenz und Quantity-Recalculation korrekt
- keine harte Clamp auf 5
- bestehende namentliche Crewverwaltung nicht unnötig ersetzen

Die genaue minimale zulässige Crewgröße vor Implementierung aus dem dann aktuellen owner-accepted Produkt-/UX-Stand reconciliieren. Keine neue Crew-Identity-Architektur nur zur Behebung dieses Bugs erfinden.

### C. Watermaker / Issue #5

Im Bootsprofil und Trip-Snapshot sichtbar nutzbar:
- Watermaker vorhanden ja/nein
- klare Beschriftung
- persistierter Zustand
- beim Profil-Snapshot übernommen
- Trip-Override möglich

Keine zusätzliche Watermaker-Leistungsangabe einführen, solange die fachliche Wasserlogik ohne sie robust lösbar ist. Falls sie zwingend benötigt wird: STOP und Decision erforderlich.

### D. Wasserlogik

Watermaker darf niemals bedeuten: Flaschen-/Reservewasser = 0.

Mindestens folgende Fälle müssen fachlich nachvollziehbar behandelt werden:
1. kein Tank, kein Watermaker
2. trinkbarer Tank, kein Watermaker
3. nicht trinkbarer Tank + Watermaker
4. trinkbarer Tank + Watermaker

Verbindlich:
- vorhandene Mindestreserve pro Person bleibt Schutzuntergrenze
- Watermaker reduziert laufend benötigten mitgeführten Wasserbedarf plausibel, aber nicht unter Reserve
- Tankkapazität und Trinkbarkeit bleiben eigenständige Faktoren
- keine versteckte Sicherheitsbehauptung
- keine unrealistischen Nullmengen

Die konkrete Formel ist vor Implementierung gegen `data/quantities_v0.6.json` und die dann aktuelle Quantity Engine zu reconciliieren und im Implementierungsbericht transparent zu dokumentieren.

### E. UX / Localization

- gefrorene UX-Hierarchie beachten
- Crew & Boot bleibt einer der vier stabilen Command-Center-Bereiche
- mechanische numerische Controls gemäß UX-Entscheidungen
- alle neuen sichtbaren Strings in allen 6 Sprachen: DE, EN, ES, FR, HR, PT
- Light/Dark/Nightwatch nicht regressieren

### F. Tests / Acceptance

Mindestens:
- Crewgrößen-Regression für kleinere Crews, einschließlich 2 und 4 Personen sowie bestehender größerer Crew
- Bootsprofil-Auswahl im realen Wizard-/Setup-Flow
- Trip-Snapshot nach Auswahl
- Trip-Override ohne Profilmutation
- Profiländerung ändert alten Trip nicht
- explizites Resync funktioniert
- Watermaker-Persistenz
- die vier Wasserfälle oben als Quantity-Tests
- Reservewasser nie 0 durch Watermaker allein
- echte UI-Journey für neues Boot → neuer Törn
- echte UI-Journey für vorhandenes Boot → neuer Törn
- Backup/Restore-Regressionen aus PIVOT3-A bleiben grün
- vollständige Flutter-Test-Suite grün
- `flutter analyze` clean

## Nicht in PIVOT3-B

- PIVOT2 Provisioning Review / Readiness
- generische Bootsverwaltung über Provy-relevante Daten hinaus
- Watermaker-Wartung/Produktionshistorie
- Wetterrouting
- Rezept-/Menüplanung
- UX-D Command-Center-Neubau
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store-Publikation

## Abschluss

Nach Implementierung:
- Implementierungsbericht
- STOP für unabhängigen Review
- keine automatische Freigabe von PIVOT2
