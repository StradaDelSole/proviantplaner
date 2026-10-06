# Startprompt für eine Gemini-Sitzung v0.7

Stand: 06.10.2026 · Review-gated Workflow.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.5 | 06.10.2026 | Gate nach PIVOT3-B |
| v0.6 | 06.10.2026 | PIVOT2 freigegeben |
| v0.7 | 06.10.2026 | PIVOT2 nach externer Review auf HOLD; FIX-B Settlement freigegeben |

## Startprompt – FIX-B

```
Lies zuerst GEMINI.md vollständig.

Dann:
1. git status
2. git pull --rebase
3. README.md vollständig lesen
4. docs/impl/FIXB_release_reconciliation_2026-10-06.md vollständig lesen
5. docs/impl/FIXB_plan.md vollständig lesen
6. docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md lesen
7. docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md lesen
8. docs/impl/FEEDBACK_R1_v0.1.md lesen
9. aktuelle Kitty-Engine, Service, UI und Tests vollständig gegen diese Entscheidungen reconciliieren

Implementiere ausschließlich:
FIX-B – Unified Settlement Ledger
Issue #27

Verbindlich:
- alle bestätigten Gruppenausgaben gehen in Kostenanteile ein
- Shared/Individual behalten unterschiedliche Bedienmodelle, aber eine Accounting Truth
- persönlich bezahlte Ausgaben werden dem Zahler gutgeschrieben
- kittyCash = deposits − kitty-paid expenses
- restliches Kitty-Cash ist beim Treasurer gehaltenes Gruppenvermögen und wird explizit im Settlement berücksichtigt
- keine synthetischen paidInCents-Werte zur Zero-Sum-Erzwingung
- Summe aller finalen Member-Net-Salden exakt 0
- Model switch darf Member-Net-Salden nicht verändern
- Shared Transfers bleiben treasurer-centered
- Individual nutzt Debt Simplification auf denselben Unified Balances
- Expense source invariant auf Create + Edit erzwingen
- kein DB-Schema-Change erforderlich

Canonical mixed regression:
A/B/C/D je 100 EUR Einzahlung
A Treasurer
200 EUR aus Kasse
120 EUR persönlich von B
Kostenanteil je 80
kittyCash 200
A -180
B +140
C +20
D +20
Summe 0

Nicht beginnen:
- DATA1
- Watermaker-Amendment
- PIVOT2
- RECEIPT1
- GUEST1
- UX-D
- Backend/Auth
- CAT1
- B3/B4/B5
- Store

Nach Umsetzung:
- docs/impl/FIXB_bericht.md
- CHANGELOG
- dedizierte FIX-B Tests
- bestehende Kitty-/QR-/UI Regressionen
- PIVOT1 + PIVOT3 Regressionen
- flutter analyze
- vollständige flutter test Suite
- nur grün committen/pushen
- danach STOP für unabhängigen Review / Owner Acceptance
```
