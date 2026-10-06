# Proviantplaner (Arbeitstitel) – powered by HullQ

Mobile App (Flutter, iOS und Android) für die Proviant- und Bordkassenplanung auf Segeltörns. Eigenständige App ohne Bootsinhalte; die Mitglied-Version wird über ein HullQ-Konto freigeschaltet.

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `docs/PRD_v0.21.md` | Produkt-Baseline; neuere ausdrücklich owner-accepted Product-/UX-Specs superseden widersprechende ältere Abschnitte |
| `docs/SLICES_v0.19.md` | Umsetzungsplan in Slices mit Abnahmekriterien |
| `docs/KATALOG_v0.10.md` | Vorratskatalog, lesbar |
| `data/catalog_v0.10.json` | Vorratskatalog, maschinenlesbar |
| `data/quantities_v0.6.json` | Mengen, Konsumprofile, Faktoren |
| `docs/design/DESIGN_BRIEF_v0.5.md` | Stilrichtung, Stitch-Prompts, Animationshinweise |
| `docs/design/mockups/` | Mockups der Kernbildschirme |
| `docs/PROMPT_SESSION_START_v0.2.md` | Startprompt und Folgeprompts für jede Gemini-Sitzung |
| `docs/design/UX_KONZEPT_v0.6.md` | UX-Konzept: Ablauf, fünf Hauptbildschirme, Bedienmuster (in Abstimmung) |
| `docs/design/PROVY_UX_DIRECTION_v0.5.md` | Owner-accepted UX-Grundsätze inkl. Home-Launchpad, 4er-Command-Grid, Guest Shopping, Color/Motion/Haptics und psychologischer Klarheit |
| `docs/design/PROVY_UX_DECISIONS_2026-10-05.md` | Owner-accepted 40-Punkte-Entscheidungssatz; Verhalten/Hierarchie/Interaktion verbindlich |
| `docs/design/PROVY_UX_WIREFRAMES_v0.2.md` | Owner-accepted Kern-Wireframes für Home, Command Center, Vorräte, Einkaufen/Guest, Crew & Boot und Bordkasse; UX-D Design frozen |
| `docs/research/WETTBEWERB_v0.4.md` | Wettbewerbsanalyse |
| `docs/BACKEND_KONZEPT_v0.2.md` | Planer-Backend (Cloudflare, Auth0) |
| `backend/`, `portal/` | Backend-Code (Worker) und Webseiten (Pages), ab B0; `web/` ist Flutter-Web |
| `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md` | Verbindlicher Produkt-Pivot: Skipper baut die Liste, Provy assistiert und prüft |
| `docs/PRODUCT_GUEST_SHOPPING_v0.3.md` | Owner-accepted Guest Shopping: QR/Link ohne Account/App plus echter Offline-Fallback |
| `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md` | Owner-accepted Belege & Endabrechnung: Belegfotos an Expenses, Abrechnung.pdf + Belege.pdf per Mail/Share |
| `docs/impl/` | Pläne und Berichte von Gemini je Slice |
| `GEMINI.md` | Arbeitsanleitung für die Umsetzung mit Gemini |
| `CHANGELOG.md` | Fortschritt pro Slice |

### Vorrang neuer Owner-Entscheidungen

`PRD_v0.21.md` bleibt die historische Produkt-Baseline, ist aber noch nicht vollständig auf die Entscheidungen vom 05.10.2026 rebased. Bei Widerspruch gelten die neueren ausdrücklich **OWNER-ACCEPTED** Dokumente, insbesondere:
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/PRODUCT_GUEST_SHOPPING_v0.3.md`
- `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`
- `docs/design/PROVY_UX_DIRECTION_v0.5.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`

Implementierungsslices müssen diese neueren Entscheidungen vor älteren widersprechenden PRD-/UX-Passagen anwenden.

## Versionierung der Dokumente

Jede neue Fassung eines Dokuments wird als neue Datei mit Versionsnummer im Namen abgelegt (z. B. `PRD_v0.8.md`). Ältere Fassungen bleiben im Repo. Das Arbeitsdokument für das Konzept liegt als Claude-Doc "Proviantplaner_PRD".

## Status

Konzeptphase läuft (PRD v0.21). Es gilt jeweils die höchste Versionsnummer.
Umgesetzt: S0, S1, S2, S2a, S-UI, S3, S4, S5, S5a, S6, S7, S8, S8a, FB1-A, FB1-B, FB1-C, FB1-D, UX-A, UX-B, UX-C, FB2-A, FB2-B, B0, B1, B2, S9, S10-T, FIX-A (inkl. Review-Amendment), PIVOT1.

**FIX-A ist owner-accepted.** Verifizierter Implementierungs-HEAD: `357d340841188654e2af680b48f41af2966429d0`; unabhängige Abnahme: `docs/impl/FIX-A_acceptance_review_2026-10-05.md`. **PIVOT1 – Assisted List Core Review-Amendment ist umgesetzt und wartet auf unabhängige Abnahme / Owner Acceptance (Issue #10, Findings A–E geschlossen). Keine Folgeslices freigegeben.** UX-D wird über Issue #21 vorbereitet, ist aber nicht freigegeben. **GUEST1 – Shared Shopping, QR & Offline ist owner-accepted und verpflichtend vor Store-v1, aber noch nicht zur Implementierung freigegeben; Grundlage: `docs/PRODUCT_GUEST_SHOPPING_v0.3.md` und `docs/impl/GUEST1_plan.md`. RECEIPT1 – Expense Receipts & Settlement Package ist ebenfalls owner-accepted und verpflichtend vor Store-v1, aber noch nicht zur Implementierung freigegeben; Grundlage: `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md` und `docs/impl/RECEIPT1_plan.md`.** B3, B4, B5 bleiben NICHT freigegeben. S10 Store-Publikation bleibt ausgesetzt.
