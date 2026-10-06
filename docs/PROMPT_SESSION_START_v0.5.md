# Startprompt für eine Gemini-Sitzung v0.5

Stand: 06.10.2026 · Review-gated Post-Pivot-Workflow.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Historischer Durchlauf-Modus |
| v0.3 | 06.10.2026 | Post-Pivot Review-Gating / PIVOT3-A |
| v0.4 | 06.10.2026 | PIVOT3-B freigegeben |
| v0.5 | 06.10.2026 | PIVOT3-A/B owner-accepted; aktuell kein Implementierungsslice freigegeben |

## Startprompt – kein Slice freigegeben

```
Lies zuerst GEMINI.md und README.md vollständig.

Dann:
1. git status
2. git pull --rebase
3. README.md erneut prüfen

Aktueller Gate-Status:
- PIVOT3-A: OWNER-ACCEPTED / COMPLETE
- PIVOT3-B: OWNER-ACCEPTED / COMPLETE
- aktuell ist KEIN weiterer Implementierungsslice freigegeben

Nicht implementieren:
- PIVOT2
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store-Publikation

Warte auf eine neue ausdrücklich owner-accepted Reconciliation/Release-Entscheidung im Repo.

Keinen historischen Session-Prompt als Freigabe interpretieren.
Keine Arbeit aus einem früheren Slice fortsetzen.
```
