# FIX-B – Unified Settlement Ledger – Implementierungsplan

Stand: 06.10.2026  
Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Verbindliche Reconciliation:
`docs/impl/FIXB_release_reconciliation_2026-10-06.md`

## Ziel

Die Bordkassen-/Settlement-Rechnung vereinheitlichen, damit jede bestätigte Gruppenausgabe unabhängig von ihrer Zahlungsquelle korrekt in Kostenanteile, Salden und Ausgleichszahlungen eingeht.

Zwei Bedienmodelle bleiben:
- Gemeinsame Bordkasse
- Einzelabrechnung

Aber es gibt nur noch eine Accounting Truth.

## A. Domainmodell

Refactore `MemberBalance` so, dass reale Beiträge und der Treuhänder-/Kassenbestand getrennt abgebildet werden.

Mindestens fachlich unterscheidbar:
- echte Einzahlungen;
- persönlich bezahlte Gruppenausgaben;
- Bruttobeitrag;
- eigener Kostenanteil;
- beim Kassenwart gehaltener Kassenbestand;
- finaler Netto-Saldo.

Keine synthetischen `paidInCents`-Werte erzeugen, nur um Summe 0 zu erreichen.

## B. Unified Ledger

Eine gemeinsame interne oder öffentliche Ledger-Berechnung erzeugen.

Input:
- Mitglieder
- Einzahlungen
- alle Ausgaben
- Kassenwart

Output mindestens:
- alle Gruppenausgaben
- Kassenausgaben
- persönlich bezahlte Ausgaben
- aktueller Kassenbestand
- einheitliche MemberBalances

Formeln gemäß FIX-B-Reconciliation.

## C. Shared Kitty

`calculateSharedKitty` nutzt den Unified Ledger.

- Kostenanteile über alle Expenses.
- Kassenbestand nur über Deposits minus kitty-paid Expenses.
- persönlich bezahlte Expense wird dem Zahler gutgeschrieben.
- Transfers bleiben Kassenwart-zentriert.
- Summe der Net-Salden = 0.

## D. Individual Settlement

`calculateIndividualSettlement` muss ebenfalls dieselbe Ledger-Wahrheit nutzen.

Falls dafür Signatur erweitert werden muss:
- Deposits
- Treasurer

sauber durch `KittyService` weiterreichen.

Bei rein personengezahltem Individual-Modus ohne Kassenaktivität bleibt das bisherige Verhalten erhalten.

Historische Deposits/Kitty-Expenses nach Modellwechsel müssen wirtschaftlich korrekt bleiben.

## E. Expense Source Invariant

Servicegrenze validiert:

Kasse:
- `isPaidFromKitty=true`
- `paidByMemberId=null`

Person:
- `isPaidFromKitty=false`
- `paidByMemberId!=null`

Ungültige neue Writes ablehnen.

Create und Edit testen.

## F. UI

Kein UX-D-Redesign.

Beibehalten:
- Shared: Zahler Kasse oder Person
- Individual: Person als Zahler
- Shared Kassenstand prominent
- SettlementScreen
- EPC QR / Zahlungslinks

Kleine Klarstellung:
- Shared-Kassenstand basiert ausschließlich auf realem Cashflow der Kasse.
- Gruppenausgaben dürfen separat alle Expenses umfassen.

Falls neue sichtbare Labels nötig sind: DE/EN/ES/FR/HR/PT.

## G. Model Switch

`switchKittyModel` darf Daten nicht umschreiben.

Test:
- gemischte Historie anlegen;
- Net-Salden in shared erfassen;
- auf individual wechseln;
- Net-Salden müssen pro Mitglied identisch bleiben;
- zurückwechseln ebenfalls identisch.

Nur Transfer-Routing/UI darf sich ändern.

## H. Canonical Mixed Case

Automatischer Test exakt:

A/B/C/D je 100 EUR Deposit.
A Kassenwart.
200 EUR aus Kasse.
120 EUR persönlich von B.
Alle 4 gleiche Beteiligung.

Erwartung:
- total expenses 320
- kitty expenses 200
- person expenses 120
- kitty cash 200
- cost share je 80
- A net -180
- B net +140
- C net +20
- D net +20
- Summe 0

Shared Transfers:
- A→B 140
- A→C 20
- A→D 20

## I. Property / Matrix Tests

Deterministische Testmatrix oder seeded random set mit gültigen Inputs.

Für jeden Fall:
- Summe Expense-Splits = Expense amount
- Summe Member cost shares = total expenses
- Summe Member net balances = 0
- Transfer-Summe gleicht Debitoren/Kreditoren korrekt aus

Mindestens Fälle:
- odd cents
- category exclusions
- skipper free
- custom splits
- positive kitty cash
- zero kitty cash
- negative kitty cash
- mixed personal + kitty expenses

## J. Regressionen

Bestehende:
- kitty_engine_test
- kitty_fb1d_test
- kitty_ui_test
- expense edit/delete
- EPC QR

müssen aktualisiert, nicht abgeschwächt werden.

Zusätzlich:
- PIVOT1
- PIVOT3-A
- PIVOT3-B
- Backup
- vollständige Flutter-Suite

## K. Bericht

`docs/impl/FIXB_bericht.md`

Muss enthalten:
- exakter HEAD
- geänderte Dateien
- Unified-Ledger-Modell
- exakte Formeln
- canonical mixed case mit Ergebnissen
- Shared vs Individual Unterschied nur noch UX/Transferdarstellung
- Model-switch invariance
- Source invariant
- reale UI-Tests
- Testzahlen
- analyze
- entdeckte Bugs/Risiken

## Nicht im Scope

Nicht beginnen:
- PIVOT2
- DATA1
- Watermaker-Reserve-Amendment
- RECEIPT1
- GUEST1
- UX-D
- Backend/Auth
- Multi-Currency
- CAT1
- B3/B4/B5
- Store

## Abschluss

Nur bei vollständig grünem Stand:
- CHANGELOG
- Bericht
- git pull --rebase
- commit
- push main
- STOP für unabhängigen Review.
