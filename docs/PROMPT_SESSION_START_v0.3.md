# Startprompt für eine Gemini-Sitzung v0.3

Stand: 06.10.2026 · Vor jeder Sitzung: `git pull --rebase`. Pro review-gegattetem Slice eine neue Sitzung.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Historischer Durchlauf-Modus |
| v0.3 | 06.10.2026 | Post-Pivot Review-Gating: nur explizit freigegebenen Slice umsetzen, danach STOP |

## Startprompt – Review-gated Slice

```
Lies zuerst GEMINI.md vollständig.

Dann:
1. git status
2. git pull --rebase
3. README.md vollständig lesen
4. die neueste owner-accepted Reconciliation/Acceptance für den aktuellen Slice lesen
5. den explizit freigegebenen Slice-Plan in docs/impl/ vollständig lesen
6. relevante Production-Implementierung, Datenmodell, Migrationen und Tests gegen den Plan reconciliieren

Implementiere ausschließlich den Slice, den README aktuell ausdrücklich als IMPLEMENTATION RELEASED ausweist.

Für den aktuellen Stand ist das PIVOT3-A – Boat/Profile Foundation:
- Issue #24
- docs/impl/PIVOT3_reconciliation_2026-10-06.md
- docs/impl/PIVOT3A_plan.md

PIVOT3-B, PIVOT2, UX-D, GUEST1, RECEIPT1, CAT1, B3/B4/B5 und Store-Publikation dürfen nicht begonnen werden.

Nach Umsetzung:
- flutter analyze
- vollständige Flutter-Test-Suite
- CHANGELOG aktualisieren
- docs/impl/<Slice>_bericht.md mit ehrlichem Nachweis je Akzeptanzkriterium
- nur bei grünem Stand: git pull --rebase, commit, push auf main
- danach STOP für unabhängigen Review / Owner Acceptance

Wenn eine Stoppregel aus GEMINI.md greift, nicht raten und den Scope nicht erweitern.
```

## Folgeprompts

- **Scope halten:** `Bleib ausschließlich in PIVOT3-A gemäß docs/impl/PIVOT3A_plan.md. PIVOT3-B und PIVOT2 sind nicht freigegeben.`
- **Fehler beheben:** `Behebe die gemeldeten Fehler innerhalb des freigegebenen Slice-Scopes, ohne Tests abzuschwächen. Danach analyze/test erneut und berichte ehrlich.`
- **Abweichung stoppen:** `Das gehört nicht zu PIVOT3-A. Mach die nicht benötigte Änderung rückgängig und bleib im freigegebenen Scope.`
