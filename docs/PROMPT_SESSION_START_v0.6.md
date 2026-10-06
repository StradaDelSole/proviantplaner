# Startprompt für eine Gemini-Sitzung v0.6

Stand: 06.10.2026 · Review-gated Post-Pivot-Workflow.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Historischer Durchlauf-Modus |
| v0.3 | 06.10.2026 | PIVOT3-A |
| v0.4 | 06.10.2026 | PIVOT3-B |
| v0.5 | 06.10.2026 | Gate nach PIVOT3-B |
| v0.6 | 06.10.2026 | PIVOT2 – Provisioning Review freigegeben |

## Startprompt – PIVOT2

```
Lies zuerst GEMINI.md vollständig.

Dann:
1. git status
2. git pull --rebase
3. README.md vollständig lesen
4. docs/impl/PIVOT2_release_reconciliation_2026-10-06.md vollständig lesen
5. docs/impl/PIVOT2_plan.md vollständig lesen
6. docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md lesen
7. relevante owner-accepted UX-Dokumente und die aktuelle Production-Implementierung/Tests reconciliieren

Implementiere ausschließlich:
PIVOT2 – Provisioning Review
Issue #26

Verbindliche Entscheidungen:
- Review ist read-only gegenüber Nutzerentscheidungen
- keine automatische Adoption
- keine automatische Mengenänderung
- keine automatische Stop-Reallocation
- needsBased darf objektiv Unterdeckung prüfen
- guided bekommt in PIVOT2 v1 keinen generischen globalen Unterversorgungsalarm
- preferenceBased bekommt keine Mengenbewertung
- Missing Basics datengetrieben über data/provisioning_review_v0.1.json
- Frische/MHD als Review-Hinweis, nicht als Zwang
- Kühlung/TK nur auf tatsächlicher Liste und nur mit belastbaren Größen
- Readiness: Bereit / Noch prüfen / Aktion nötig
- kein Score
- Gewicht/Volumen nur Info ohne allgemeine Storage-Kapazitätsbehauptung

Related issues:
- #7 PIVOT2 Regression/Closure target
- #8 PIVOT2 freshness closure target
- #9 bereits durch PIVOT1 erledigt; NICHT wieder eine Meal-Frequency-Engine bauen

Nicht beginnen:
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store-Publikation

Nach Umsetzung:
- docs/impl/PIVOT2_bericht.md
- CHANGELOG aktualisieren
- dedizierte PIVOT2 Tests
- PIVOT1 Regressionen
- PIVOT3-A/B Regressionen
- flutter analyze
- vollständige flutter test Suite
- nur grün committen und pushen
- danach STOP für unabhängigen Review / Owner Acceptance
```
