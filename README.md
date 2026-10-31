# Proviantplaner (Arbeitstitel) – powered by HullQ

Mobile App (Flutter, iOS und Android) für die Proviant- und Bordkassenplanung auf Segeltörns. Eigenständige App ohne Bootsinhalte; die Mitglied-Version wird über ein HullQ-Konto freigeschaltet.

## Engineering- und Review-Prozess (Owner-Entscheidung 30.10.2026)

Für **jede neue Provy-Sitzung** gelten AGENTS.md, GEMINI.md und docs/ENGINEERING_STANDARD_v1.0.md. Bei High-Risk-Slices (Persistenz/Backup/Restore, Auth/Backend, Offline-Synchronisierung, Nebenläufigkeit, Finanzen, Migration) ist die zweistufige Arbeitsweise verbindlich: **Phase A Architektur- und Failure-Review ohne Code → unabhängiges Architecture Gate → Phase B Implementierung mit negativen und konkurrierenden Tests → unabhängiger Code-Review am exakten HEAD → Owner Acceptance**. Vorlagen: docs/templates/ARCHITECTURE_GATE_TEMPLATE.md und docs/templates/IMPLEMENTATION_BRIEF_TEMPLATE.md. Nach zwei verwandten Amendments Architektur neu bewerten statt blind weiterpatchen.

Dies ist eine Prozessentscheidung, **keine automatische Freigabe** eines Feature-Slices oder Merges. Der aktuelle Gate-Status ist weiterhin anhand der offenen PRs und Owner-Entscheidungen zu verifizieren.

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `docs/PRD_v0.21.md` | Produkt-Baseline; neuere ausdrücklich owner-accepted Product-/UX-Specs superseden widersprechende ältere Abschnitte |
| `docs/SLICES_v0.19.md` | Umsetzungsplan in Slices mit Abnahmekriterien |
| `docs/KATALOG_v0.10.md` | Vorratskatalog, lesbar |
| `data/catalog_v0.11.json` | Aktueller Vorratskatalog, maschinenlesbar; DATA1 AssistType kanonisch |
| `data/quantities_v0.6.json` | Mengen, Konsumprofile, Faktoren |
| `docs/design/DESIGN_BRIEF_v0.5.md` | Stilrichtung, Stitch-Prompts, Animationshinweise |
| `docs/design/mockups/` | Mockups der Kernbildschirme |
| `docs/PROMPT_SESSION_START_v0.9.md` | Archivierter Startprompt für den abgeschlossenen DATA1 Review Amendment |
| `docs/PROMPT_SESSION_START_v0.10.md` | Archivierter WATER1-Startprompt der supersedierten 3-Tage-Reserve |
| `docs/PROMPT_SESSION_START_v0.11.md` | Archivierter Startprompt für den abgeschlossenen WATER1 Simplification Amendment |
| `docs/PROMPT_SESSION_START_v0.12.md` | Aktueller Session-Startprompt für PIVOT2 Provisioning Review |
| `docs/design/UX_KONZEPT_v0.6.md` | UX-Konzept: Ablauf, fünf Hauptbildschirme, Bedienmuster (in Abstimmung) |
| `docs/design/PROVY_UX_DIRECTION_v0.5.md` | Owner-accepted UX-Grundsätze inkl. Home-Launchpad, 4er-Command-Grid, Guest Shopping, Color/Motion/Haptics und psychologischer Klarheit |
| `docs/design/PROVY_UX_DECISIONS_2026-10-05.md` | Owner-accepted 40-Punkte-Entscheidungssatz; Verhalten/Hierarchie/Interaktion verbindlich |
| `docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md` | Owner-accepted UX-Benchmarkstrategie: Instacart für Shopping/Catalog/Provider, Airbnb für Trip/Context, Material 3 als technische Basis; Pflicht-Benchmark-Pass vor UX-D |
| `docs/design/PROVY_UX_WIREFRAMES_v0.2.md` | Owner-accepted Kern-Wireframes für Home, Command Center, Vorräte, Einkaufen/Guest, Crew & Boot und Bordkasse; UX-D Design frozen |
| `docs/research/WETTBEWERB_v0.4.md` | Wettbewerbsanalyse |
| `docs/BACKEND_KONZEPT_v0.2.md` | Planer-Backend (Cloudflare, Auth0) |
| `backend/`, `portal/` | Backend-Code (Worker) und Webseiten (Pages), ab B0; `web/` ist Flutter-Web |
| `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md` | Verbindlicher Produkt-Pivot: Skipper baut die Liste, Provy assistiert und prüft |
| `docs/impl/PIVOT3_reconciliation_2026-10-06.md` | Owner-accepted Rebase der Implementierungsreihenfolge: PIVOT3-A → PIVOT3-B → PIVOT2 |
| `docs/impl/PIVOT3A_plan.md` | Freigegebener Foundation-Slice für Bootsprofile, Trip-Snapshots, Migration und Backup/Restore |
| `docs/impl/PIVOT3B_plan.md` | Freigegebener Slice für Setup-/Bootsprofil-Integration, Crew-Bug und Watermaker-Logik |
| `docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md` | Verbindliche Release-Reconciliation: Crew-Minimum 1, boolesche Watermaker-Semantik, Reservewasser-Formel, Gate |
| `docs/impl/PIVOT2_release_reconciliation_2026-10-06.md` | Verbindliche PIVOT2-Reconciliation: read-only Provisioning Review, Missing Basics, Needs-based Unterdeckung, Frische/Kühlung, Readiness |
| `docs/impl/PIVOT2_plan.md` | PIVOT2-Plan; aktuell ON HOLD |
| `docs/impl/FIXB_release_reconciliation_2026-10-06.md` | Verbindliche Settlement-Reconciliation: eine Accounting Truth für Shared/Individual |
| `docs/impl/FIXB_plan.md` | Freigegebener Implementierungsplan für FIX-B |
| `docs/PRODUCT_GUEST_SHOPPING_v0.3.md` | Owner-accepted Guest Shopping: QR/Link ohne Account/App plus echter Offline-Fallback |
| `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md` | Owner-accepted Belege & Endabrechnung: Belegfotos an Expenses, Abrechnung.pdf + Belege.pdf per Mail/Share |
| `docs/PRODUCT_CHARTER_PROVIDER_ASSORTMENT_v0.1.md` | Owner-accepted B2B-Entscheidung: provider-/basis-spezifische Sortimente als Overlay auf dem globalen Provy-Katalog; Pflichtgrundlage vor B4/B5/Charter-Provisioning |
| `docs/impl/` | Pläne und Berichte von Gemini je Slice |
| `GEMINI.md` | Arbeitsanleitung für die Umsetzung mit Gemini |
| `CHANGELOG.md` | Fortschritt pro Slice |

### Vorrang neuer Owner-Entscheidungen

`PRD_v0.21.md` bleibt die historische Produkt-Baseline, ist aber noch nicht vollständig auf die Entscheidungen vom 05.10.2026 rebased. Bei Widerspruch gelten die neueren ausdrücklich **OWNER-ACCEPTED** Dokumente, insbesondere:
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/impl/PIVOT3_reconciliation_2026-10-06.md` (supersediert die ältere PIVOT2→PIVOT3-Implementierungsreihenfolge; Scope des Produkt-Pivots bleibt bestehen)
- `docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT2_release_reconciliation_2026-10-06.md` (aktuelle Provisioning-Review-Entscheidung)
- `docs/PRODUCT_GUEST_SHOPPING_v0.3.md`
- `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`
- `docs/PRODUCT_CHARTER_PROVIDER_ASSORTMENT_v0.1.md`
- `docs/design/PROVY_UX_DIRECTION_v0.5.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`

Implementierungsslices müssen diese neueren Entscheidungen vor älteren widersprechenden PRD-/UX-Passagen anwenden.

## Versionierung der Dokumente

Jede neue Fassung eines Dokuments wird als neue Datei mit Versionsnummer im Namen abgelegt (z. B. `PRD_v0.8.md`). Ältere Fassungen bleiben im Repo. Das Arbeitsdokument für das Konzept liegt als Claude-Doc "Proviantplaner_PRD".

## Status

**Aktuelles Release-Gate (31.10.2026, vor jeder Sitzung neu prüfen):** RECEIPT1 ist akzeptiert und via PR #34 gemergt, Engineering Standard PR #35 gemergt. BACKEND-CORE Phase A ist am 31.10.2026 vom Owner als Architektur mit verbindlichen P01–P05 Implementierungs-/Stage-Prüfungen akzeptiert. Test-only Spike-PR #38 ist nach GitHub Actions 41213360372 (37 Backend-, 482 Flutter-Tests) gemergt; tatsächlicher geprüfter Test-HEAD `858238286671730308716aa374d7ae71852748eb`, Merge `7adf9349ccd2bb47a23c3237280c2f5260064332`. **BC-1A Phase B ist am 31.10.2026 eng begrenzt zur Implementierung freigegeben; vor nativer SDK-/iOS-Anpassung besteht ein separater Plattformkompatibilitäts-Stopp (aktuelles iOS-Deployment-Target 12, Auth0 2.x ab iOS 14).** Kein Code-Merge, kein Deployment und kein BC-1B-Go ohne neue Owner Acceptance. Verbindlich: `docs/impl/BACKEND_CORE_BC1A_phase_B_owner_release_2026-10-31.md`, Issue #40. GUEST1, UX-D, B3–B5 und Store-Release bleiben gesonderte Gates.



Konzeptphase läuft (PRD v0.21). Es gilt jeweils die höchste Versionsnummer.
Umgesetzt: S0, S1, S2, S2a, S-UI, S3, S4, S5, S5a, S6, S7, S8, S8a, FB1-A, FB1-B, FB1-C, FB1-D, UX-A, UX-B, UX-C, FB2-A, FB2-B, B0, B1, B2, S9, S10-T, FIX-A (inkl. Review-Amendment), PIVOT1, PIVOT3-A, PIVOT3-B, FIX-B, DATA1, WATER1, PIVOT2 (OWNER-ACCEPTED / COMPLETE; finaler Review: docs/impl/PIVOT2_acceptance_review_2026-10-17.md; Owner Acceptance: docs/impl/PIVOT2_owner_acceptance_2026-10-17.md; PR #33 merged in 3c75f0e; Issues #26, #7, #8 abgeschlossen).

**FIX-A ist owner-accepted.** Verifizierter Implementierungs-HEAD: `357d340841188654e2af680b48f41af2966429d0`; unabhängige Abnahme: `docs/impl/FIX-A_acceptance_review_2026-10-05.md`. **PIVOT1 – Assisted List Core ist OWNER-ACCEPTED / COMPLETE.** Verifizierter Implementierungs-HEAD: `86eab66336e6fa231acac44c90b2eed4a6a3f429`; unabhängige Abnahme: `docs/impl/PIVOT1_acceptance_review_2026-10-06.md`; Owner Acceptance: `docs/impl/PIVOT1_owner_acceptance_2026-10-06.md`. Issue #10 ist abgeschlossen. **Owner-accepted Reconciliation vom 06.10.2026: PIVOT3 wird vor PIVOT2 umgesetzt und in PIVOT3-A/PIVOT3-B geteilt. PIVOT3-A – Boat/Profile Foundation ist OWNER-ACCEPTED / COMPLETE. Verifizierter Implementierungsstand: `7cb1eca06ad12617e091adcd62fdfb212acf0293`; finaler unabhängiger Review: `docs/impl/PIVOT3A_acceptance_review_2026-10-06.md`; Owner Acceptance: `docs/impl/PIVOT3A_owner_acceptance_2026-10-06.md`; Issue #24 abgeschlossen. **PIVOT3-B – Setup Integration & Water Logic ist OWNER-ACCEPTED / COMPLETE. Verifizierter Implementierungs-/Amendment-HEAD: `b19e1736a2d5c7fa26836bb35d014ff46a6706e1`; finaler unabhängiger Review: `docs/impl/PIVOT3B_acceptance_review_2026-10-06.md`; Owner Acceptance: `docs/impl/PIVOT3B_owner_acceptance_2026-10-06.md`. Issues #25, #4, #5 und #6 sind abgeschlossen. **PIVOT2 – Provisioning Review (Issue #26) ist OWNER-ACCEPTED / COMPLETE.** Canonical release: `docs/impl/PIVOT2_release_reconciliation_2026-10-17.md`; Plan: `docs/impl/PIVOT2_plan_v0.2.md`; Review: `docs/impl/PIVOT2_acceptance_review_2026-10-17.md`; Owner Acceptance: `docs/impl/PIVOT2_owner_acceptance_2026-10-17.md`. PR #33 gemergt in `3c75f0e6012ba8a80011504dce471cc97b71ed94`. Issues #26, #7 und #8 sind abgeschlossen. Kein Folgeslice ist automatisch freigegeben. **FIX-B – Unified Settlement Ledger (Issue #27) ist OWNER-ACCEPTED / COMPLETE.** Verifizierter Implementierungs-HEAD: `af8ee33ad206e04d22b1097a1a11675a45863314`; finaler unabhängiger Review: `docs/impl/FIXB_acceptance_review_2026-10-07.md`; Owner Acceptance: `docs/impl/FIXB_owner_acceptance_2026-10-07.md`. Issue #27 ist abgeschlossen. **DATA1 – Catalog-driven Assist Classification (Issue #28) ist OWNER-ACCEPTED / COMPLETE.** Core-HEAD: `73cfdecefe16721e11fa33878a18a751f092c330`; final reviewed amendment HEAD: `84240ee67600f0955df79fba4f091a853ea950d0`; PR #29 merged; merge commit: `75c1290822e9301aed4e610065be58995e3d3a2e`; finaler Review: `docs/impl/DATA1_acceptance_review_2026-10-16.md`; Owner Acceptance: `docs/impl/DATA1_owner_acceptance_2026-10-16.md`. Issue #28 ist abgeschlossen. **WATER1 – Minimum Drinking Water Simplification (Issue #30) ist OWNER-ACCEPTED / COMPLETE.** Final reviewed PR HEAD: `788f9fb608a523eaaa0163a3e743077c04b53af4`; PR #31 merged; Merge-Commit: `6b206ee7cbf6ea276a642e0a4b5dc75788c68fc5`; finaler Review: `docs/impl/WATER1_acceptance_review_2026-10-17.md`; Owner Acceptance: `docs/impl/WATER1_owner_acceptance_2026-10-17.md`.** **UX Benchmark Strategy ist OWNER-ACCEPTED und verbindlich für UX-D.** `docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md`: Instacart ist Shopping-/Catalog-/Provider-North-Star, Airbnb Trip-/Context-North-Star, Material 3 technische Basis. Vor UX-D ist ein dokumentierter Benchmark-Pass Pflicht; die eingefrorene IA bleibt unverändert, außer der Owner entscheidet ausdrücklich neu. **B2B Provider Assortment (Issue #32) ist als Produkt-/Architekturentscheidung OWNER-ACCEPTED, aber NICHT zur Implementierung freigegeben.** Verbindlich: `docs/PRODUCT_CHARTER_PROVIDER_ASSORTMENT_v0.1.md`. Vor B4, B5, supplier-aware `Liefern lassen` oder Charter-Provisioning ist eine neue Decision/Implementation Reconciliation gegen den dann aktuellen `origin/main` Pflicht; das Provider-Assortment darf dabei nicht ignoriert werden. **GUEST1 – Shared Shopping, QR & Offline ist owner-accepted und verpflichtend vor Store-v1, aber noch nicht zur Implementierung freigegeben; Grundlage: `docs/PRODUCT_GUEST_SHOPPING_v0.3.md` und `docs/impl/GUEST1_plan.md`. RECEIPT1 – Expense Receipts & Settlement Package ist am 30.10.2026 technisch Owner-accepted und via PR #34 gemergt; echte Kamera-/Galerie-/Share-Gerätetests bleiben Store-v1-Gates; Grundlage: `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md` und `docs/impl/RECEIPT1_plan.md`.** B3, B4, B5 bleiben NICHT freigegeben. S10 Store-Publikation bleibt ausgesetzt.


