# Startprompt für eine Gemini-Sitzung v0.4

Stand: 06.10.2026 · Vor jeder Sitzung: `git pull --rebase`. Pro review-gegattetem Slice eine neue Sitzung.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Historischer Durchlauf-Modus |
| v0.3 | 06.10.2026 | Post-Pivot Review-Gating / PIVOT3-A |
| v0.4 | 06.10.2026 | PIVOT3-B – Setup Integration & Water Logic freigegeben |

## Startprompt – PIVOT3-B

```
Lies zuerst GEMINI.md vollständig.

Dann:
1. git status
2. git pull --rebase
3. README.md vollständig lesen
4. docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md vollständig lesen
5. docs/impl/PIVOT3B_plan.md vollständig lesen
6. docs/impl/PIVOT3A_owner_acceptance_2026-10-06.md lesen
7. relevante owner-accepted UX-Dokumente und die tatsächliche Production-Implementierung/Tests gegen den Plan reconciliieren

Implementiere ausschließlich:
PIVOT3-B – Setup Integration & Water Logic
Issue #25

Mit enthalten:
- Issue #4 Crewgröße
- Issue #5 Watermaker
- verbleibende sichtbare UX-/Setup-Abnahme aus Issue #6

Verbindliche Reconciliation:
docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md

Wichtige festgelegte Punkte:
- Crew-Minimum = 1
- kein neues crewCount-DB-Feld / kein Schema v8 nur für den Crew-Fix
- bestehendes CrewMember-Modell beibehalten
- New Trip startet nicht mehr mit 5 festen Platzhaltern
- Boot im Setup vor Crew
- gespeichertes Boot auswählen / neu anlegen / bearbeiten
- einmalige Trip-Bootsdaten ohne gespeichertes Profil möglich
- Profilwerte sind nur Vorschlag; sichtbare Trip-Overrides gelten nur für den Trip
- keine automatische Retroaktivität
- Resync nur explizit
- hasWatermaker wird an QuantityCalculationInput durchgereicht
- kein Watermaker-l/Tag-Feld erfinden
- Watermaker=true bedeutet im v1-Scope: Nutzer bestätigt eine betriebsbereite laufende Trinkwasserquelle
- Watermaker darf Flaschenwasser niemals auf 0 reduzieren
- bei Watermaker=true: Bottle-Water-Bedarf = vorhandene datengetriebene Notreserve (aktuell 1,5 l × Crewanzahl)
- ohne Watermaker bleibt die bestehende Trinkwassertank-Logik unverändert
- data/quantities_v0.6.json nicht ändern
- alle neuen sichtbaren Texte in DE/EN/ES/FR/HR/PT

Nicht beginnen:
- PIVOT2
- UX-D Command-Center-Rebuild
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store-Publikation

Nach Umsetzung:
- dedizierte PIVOT3-B Tests
- PIVOT3-A Migration/Backup-Regressionen
- flutter analyze
- vollständige flutter test Suite
- CHANGELOG aktualisieren
- docs/impl/PIVOT3B_bericht.md mit realen Testnamen/Nachweisen
- nur bei vollständig grünem Stand git pull --rebase, commit und push auf main
- danach STOP für unabhängigen Review / Owner Acceptance

Wenn ein echter Widerspruch oder ein notwendiger neuer Produkt-/Domainentscheid auftaucht, Stoppregel aus GEMINI.md anwenden. Nicht PIVOT2 oder UX-D vorziehen.
```
