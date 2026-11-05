# PROVY – Real Device & Human-Centered Acceptance Matrix

**v1.0 – 05.11.2026** · owner-approved approach, protocol ready; observations not yet fabricated.  
**Applies to:** #66–#71, PR #60 and all essential Store-v1 journeys.  
**HCD evidence:** `docs/design/PROVY_HUMAN_CENTERED_DESIGN_v0.1.md`, #64.

## 1. Evidence classes and gates

- **C1 Static source / architecture:** implementation behavior inferred from exact commit. No real-screen proof.
- **C2 CI Unit/Widget:** assertions passed on exact PR-HEAD; cannot prove visual animation or real-device scroll.
- **C3 Owner physical device:** named actual device/OS/build mode (Pixel 7 Pro; date), task, observed success/failure, screenshots/short recordings if owner approves. Not an unfamiliar independent-user test.
- **C4 Independent task test:** relevant person not involved with design, given task without demonstration. Record observed behavior, assistance, errors, hesitation; avoid raw PII.
- **C5 Production-like Stage:** exact release artifact, real Auth0 EU tenant, D1/R2 staged backup and restore, permissions/signing/phone restart evidence.

**Do not collapse** C2 into C3/C4/C5. Minimum C3 before closing any UI P0; minimum C4 for the three core Store-v1 tasks. Risk-based manual tests are required for high-risk persistence/finance even if UI unchanged.

## 2. Test fixtures: synthetic, reproducible and safe

Trip A: 14 days, 6 fictional crew, 2 shopping stops (Day 1, Day 6), 40+ adopted list items including 10 preserved goods, optional butter_salted, 2 intentionally unassigned quantities, varied pack sizes, 2 fake expenses/receipts. Never share real banking data or personal receipts; no wiping Owner's actual app DB.

Trip B: first-run fresh **disposable test profile** with no trips, for Welcome/onboarding; **never delete existing actual trip data** just for preview. Use welcome preview for existing installed app.

Trip C: large backup with synthetic receipt binaries (10–50 MiB); separate staging environment, Restore into isolated disposable device/profile.

Devices: Pixel 7 Pro Android, secondary smaller Android phone (ideally 320dp), one real iPhone model after hosted macOS build available. Light/Dark/Nightwatch, accessibility font 1.5×, Reduced Motion, portrait, one-handed shopping where safe, airplane mode.

## 3. Human task journeys – no scripted UI demonstration

### Journey J1: Plan a trip and provisions

**Task:** „Plane für 6 Personen und 14 Tage eine Einkaufsliste. Nimm Salzbutter in 250-g-Packungen auf und stelle fest, welche Artikel für Tag 6 gebraucht werden.“
- Can create/edit trip, find product and visible **Bearbeiten** action, change package sizes.
- Manual pack count shown truthfully, **not 'Bedarf 0 g'** when no valid computation; optional guidelines labelled as rough estimates, if Owner policy later accepted.
- Canned fruit, sauerkraut and dried fruit do not misleadingly appear as fresh-only items, department sort consistent.
- No accidental auto-filled Restaurant Day 1–N; user chooses actual days (#54).
- No unwanted automatic adoption of taste/preferences; existing persisted trip/list survives relaunch.

### Journey J2: Buy and store

**Task:** „Erstelle Einkaufstag 6, nenne den Stopp später 'Cres Supermarkt', ordne 15 Pakete zu. Kaufe 40 Positionen, korrigiere zwei Fehler, lass 3 Positionen offen, schließe ab, lagere später ein.“
- Default stop name follows day until customized; after custom name day change does not overwrite.
- Newly created stop offers **Liste vorbereiten / Artikel zuordnen**; zero selected => clear empty state, no meaningless Shop button.
- Stop allocations sum to authoritative user pack count; no duplicate/reassigned loss.
- At mid-viewport, check 5 rows and verify **next open item remains visible** after each persistence (no scroll reset). Erledigt section collapsed by default yet can undo/reopen.
- Pause/app background/relaunch: progress persists; can continue same stop with correct counts.
- Finish handles missing quantities transparently; *Später einlagern* returns to visible persistent **Einlagern fortsetzen** next action.
- Completed shop shows **Ansehen** (and explicit reopen) instead of unconditional **Starten**; multiple future stops remain accessible.
- No misleading success if DB mutation fails; offline work still available.

### Journey J3: Crew costs, settlement, receipts, recovery

**Task:** „Erfasse für 6 Personen eine Ausgabe mit Fake-Beleg, zwei verschiedenen Zahlern und einer Einzahlung; prüfe Nettosalden, teile PDF und stelle das Backup auf einem anderen Gerät wieder her.“
- No mixing currencies silently; remain cent-accurate, errors are actionable, retries safe.
- Actual recorded receipt survives app kill/restart and backup/restoration; stop, list, crew, ledger data stay consistent.
- No IBAN in cloud backup, no Base64 false positives, download/list distinguish auth/network/no-backup; owner authorizes only synthetic upload in stage.
- PDF localization and privacy/account-delete behavior explicitly checked.

## 4. Specific regression matrix for active issues

| Test | Setup | Expected outcome | Evidence |
| --- | --- | --- | --- |
| SHOP-01-01 | 40 items, scroll middle, 5 checkmarks | next open row remains in viewport; no jump | C2 + C3 |
| SHOP-01-02 | 3 finished, undo second | count, order, persist and scroll remain stable | C2 + C3 |
| SHOP-01-03 | delayed DB write / error / two rapid toggles | truthful busy/error/retry, no duplicates | C2 |
| SHOP-02-01 | add stop tag 14 then 6 | auto name `Einkauf Tag 6` | C2 + C3 |
| SHOP-02-02 | custom name + change day | custom stays | C2 |
| SHOP-02-03 | new empty stop | obvious **Liste zuordnen**, no false ready | C2 + C3 |
| SHOP-02-04 | two stops, assign 3/2 packages | balances stable, base stop leftovers correct | C2 + C3 |
| SHOP-02-05 | finish / later storage / restart | obvious **Einlagern fortsetzen** | C2 + C3 |
| DATA-01-01 | canned fruit, sauerkraut, dried fruit | non-fresh category, correct department | data tests + C3 |
| DATA-01-02 | manually adopt salted butter | pack size editable, no false `Bedarf 0` | C2 + C3 |
| WELCOME-01 | first-run empty profile | animated brand page before trip Home, no Home flash | C2 + C3 |
| WELCOME-02 | existing trip + preview | no destructive reset; preview under More/Help, no new onboarding gate | C2 + C3 |
| RELEASE-01 | signed Android release build | resolved INTERNET permission + actual Auth0/API networking | C5 |
| RELEASE-02 | signed iOS archive | camera/photo permissions prompt correctly, no OS crash | C5 |
| BACKEND-01 | synthetic 300KB/50MiB receipt | no false IBAN rejection, bounded streaming, restore reliable | C5 |
| P05 | real Android/iOS native login | refresh/logout/app kill flows and consent error paths pass | C5 |

## 5. Defect/observation template

```text
Date, tester role: Owner / unfamiliar skipper / crew member / independent reviewer
Device/OS/build SHA, theme, viewport/Font scale/offline state:
Scenario, start state and goal:
Observed steps (do not prescribe taps to unfamiliar test participant):
Outcome: success without help / with help / partial / failed
Hesitation, wrong turn, scroll displacement, false success, accessibility issue:
If recording: consent, minimal nonpersonal content, storage/retention:
Severity: BLOCKER / HIGH / MEDIUM / LOW
Reproducibility: reproduced / observed once / code inference / unknown
Issue, next fix, exact HEAD / CI, post-fix independent test:
Owner Acceptance and merge/date: PENDING until actually granted
```

**No manufactured test results or predetermined success percentages.** A successful demonstration by developer is not C4. Critical P0 UX defects must be retested promptly on the Pixel after each narrowly scoped change, not after a giant release batch.
