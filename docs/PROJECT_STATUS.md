# PROVY – aktueller Projektstatus und Owner-Gates

**Stand:** 05.11.2026 (Repository Live-Abgleich vor Anlage dieses Dokuments)  
**Status:** Owner-freigegebene Planung, **KEIN** automatischer Code-/Merge-/Cloud-/Store-Release.  
**Scope:** kompakter Einstiegspunkt für neue ChatGPT-, Gemini- und Review-Sitzungen.

> Diese Datei ist ein **datierter Status-Snapshot**, kein Ersatz für aktuellen Live-GitHub-HEAD, CI oder Owner-Entscheidungen. Vor jedem neuen Slice PRs, Issues, `main` und den exakten aktiven HEAD live erneut prüfen. Historische Docs bleiben als Quelle für bereits akzeptierte Anforderungen erhalten, überschreiben aber keine jüngere Owner-Entscheidung.

## 1. Das Produkt und sein verbindliches Prinzip

PROVY (Arbeitstitel) ist ein **offline-first, skippergeführter Proviantplaner mit Bordkasse und Crew-Abrechnung**. Der Skipper entscheidet, PROVY unterstützt: kein automatisches Durchgenerieren persönlicher Vorräte. Anwendung von **Human-Centered Design** auf reale Aufgaben bei Planung, Einkauf, Einlagern und Abrechnung; die drei wichtigsten Nutzerreisen müssen auch durch **echte beobachtete Aufgaben** validiert werden. Quellen:
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/design/PROVY_HUMAN_CENTERED_DESIGN_v0.1.md` (PR #63)
- `docs/design/PROVY_HCD_SHOPPING_JOURNEY_PLAN_2026-11-05.md` (dieser PR)
- `docs/ENGINEERING_STANDARD_v1.0.md`

## 2. Stand der Umsetzung – geprüftes Repository

| Gegenstand | Quelle/Status 05.11.2026 | Nächster Gate |
| --- | --- | --- |
| `main` | `e00c01d35763790fe430a8c331436e120478f2dd` | HEAD jedes Mal erneut prüfen |
| PR #60 Flight Strip + Pixel flicker + Welcome | `af34fd9a88c3c7a4cf0e281ec187da2e5a39b855`; Code-/CI PASS, **Owner real-device HCD FAIL/HOLD** | #64/#66–#68 korrigieren, neue Exact-HEAD Review + Pixel-Test, Owner Acceptance; **nicht merge** |
| PR #63 HCD-Prinzip + handlungsfähige Planungsunterlagen | bereits offen; Dokumentations-PR, nicht in main | unabhängiger Docs-Review + Owner Acceptance vor Merge |
| P05 Auth0 real EU Tenant | #45/#50/#51 OPEN; Native-Code BC-1A gemergt | Android + iOS Stage, tatsächliche Token-/Restarts |
| BACKEND-CORE | B0–B2 Worker-/D1-/R2-**Grundgerüst**, Cloud-Deployment/BC-1B gesperrt; Phase-A Spikes S1/S2/S3 durchgeführt und Architekturauflagen P01–P05 bestehen | #70: Gate A / P05 → explizite Phase-B-Freigabe |
| Android/iOS Release | #69: Plattform-Konfiguration unvollständig verifiziert | finale release APK/AAB/iOS Artifacts, permissions, Toolchain, signing |
| Guest Shopping | #22 OFFEN, v1-relevant | erst nach stabiler Basisplanung und eigenem High-Risk Gate |
| UX-D / Command Center | #21 OFFEN; eingefrorene Owner-IA gilt | neue HCD-Evidenz / Owner-Reconciliation |
| Restauranttag-Bug | #54 OPEN | getrenntes fachliches Fix-/Device-Gate |
| Rechtliche Links | #49 OPEN | echte Zielseiten und Privacy/Store-Gate |
| Grab Bag / Törnkosten-Erweiterung | #2/#1 OPEN | nach v1-Kernproblemen, kein Scope-Drift |

**Wichtig:** Code-PASS/CI-Green bedeutet NICHT automatisch, dass der Nutzer seine Aufgabe auf realem Gerät erfolgreich ausführen kann. Owner hat PR #60 nach Pixel-Test wegen Shopping-Journey-Mängeln **nicht** produktseitig akzeptiert. Cloud-Produktionsreife darf nicht aus bestandenen Emulator-Spikes abgeleitet werden.

**HCD-SHOP-01 Gate A Stand (06.11.2026):** Codebasierte Ursachenanalyse, Architekturvarianten, Failure-/Concurrency-Matrix und Invariant-to-Test-Nachweise sind in `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md` als **CANDIDATE / REVIEW OPEN** dokumentiert. Empfohlen: eine einzige offene, nach Abteilungen gruppierte Scroll-Liste mit angehefteter Sicht auf den nächsten Artikel, getrennt eingeklapptes „Erledigt (N)“, persistenzwahrhaftem Abhaken/Undo und ohne doppeltes Provider-Invalidieren. Noch **keine unabhängige Gate-A-Abnahme, keine Gemini-Implementierung, keine Pixel-Bestätigung**. Erst nach Gate A + Owner-Phase-B-Freigabe coden.

## 3. Priorisierte Umsetzung und Zuständigkeiten

| Reihenfolge | Paket / Issue | Rolle | Freigabe- und Abschlussbedingung |
| --- | --- | --- | --- |
| **Jetzt** | #64 HCD Shopping-Journey Master + #66 HCD-SHOP-01 | ChatGPT Spezifikation/Review, Gemini Code | kein Scrollsprung/visuell stabil, Android Pixel + unabhängiger Exact-HEAD-Review |
| **Danach** | #67 HCD-SHOP-02 – Stopps, Zuordnung, Abschluss, Einlagern | zuerst Phase A; Gemini erst nach Gate A | echte mehrtägige Stopps, Restart-/Offline-/Failure-Semantik, Owner-genehmigte Persistenzwahl |
| **Danach** | #68 DATA-HCD-01 – Kategorien, Bedarf 0, Bearbeiten | Produktentscheidung für Mengenpolicy offen | sichtbares Bearbeiten, keine irreführenden Nullwerte, korrekte Datentaxonomie, Migrationsrisiko geprüft |
| Parallel planbar | #62 Welcome Preview, #61 Flicker, #59 Gerätetest | ohne automatischen Scope-Zuwachs | One-time Welcome + sichere Preview, Slip/Undo visual bestätigt |
| Parallel **Gate A** | #69 Android-/iOS-Release | gezielter Release-Slice | API-/Xcode-/Permissions-/Signierung/Gerätebelege |
| Parallel **Gate A** | #70 Backend BC-1B | P05 first; P01–P05/ADR-Reconciliation | Streaming+CAS+Account-Fencing+Restore, keine Cloud-Freigabe vorher |
| Vor Store v1 | #71 unabhängige HCD-Tests, #22 Guest Shopping, #49 Legal, PDF i18n | je eigener Slice | drei E2E-Tasks mit echten Nicht-Entwicklern, Release-Evidenz |
| Nach Kernstabilisierung | #21 Command Center, #1/#2 + B2B, weitere Komfortfeatures | Owner priorisiert | nicht vor Kernnutzbarkeit freigeben |

**Nächster Schritt nach 06.11.2026:** Unabhängiger Gate-A-Review des bereits dokumentierten Architekturvorschlags `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md`. Die ursprüngliche Gemini-Phase-A-Anweisung ist durch den vorliegenden Entwurf überholt. Erst nach Gate-A-Acceptance und separater Owner-Phase-B-Freigabe darf Gemini Produktionscode ändern.

**Prozessregel:** Ein Paket wird nur als `DONE` markiert, wenn Owner Acceptance, exakter PR-HEAD/CI, negative/regressive Tests, nötiger physischer oder Stage-Nachweis und Merge/Issue-Closure dokumentiert sind. Sonst `OPEN`, auch wenn Code lokal grün ist. Priorität ist **keine** automatische Coding-Freigabe.

## 4. Explizite noch offene Produktentscheidungen

- **Mengen-/Bedarfshinweise:** Vorschlagsmodelle A (keine), B (gezielte optionale Richtwerte), C (breite produktgenaue Werte). Owner hält B für vielversprechend, möchte Grundsatz ausdrücklich diskutieren. **Bis dahin keine globale Engine-/Copy-Policy-Änderung**, nur sachlich falsche Nullanzeige nach gesondertem Auftrag korrigieren.
- **Einkaufsstopp-Abschluss:** Abgeleitet aus bestehenden Daten oder eigenständig persistiert? Phase A mit Optionen und Invarianten vor jeder DB-Migration.
- **Cloud-Backup-Verschlüsselung:** Privacy/Support/Geräteverlust/Schlüsselwiederherstellung vor Entscheidung.
- **PROVY finaler Name, Branding/Store:** Arbeitsname und genehmigte Welcome-Copy, Marken-/Store-Verfügbarkeit noch zu prüfen.
- **Version 1/Store Scope** inkl. Gastshopping, Rechtliches, Pricing; verbindliche Releasebedingungen nicht durch Scope-Wünsche ersetzen.

## 5. Repository-/Agentenregeln

`AGENTS.md`, `GEMINI.md` und `docs/ENGINEERING_STANDARD_v1.0.md` bleiben bindend:
- Architektur-/Review-Assistent plant, schreibt Dokumente und prüft unabhängig; Gemini implementiert nur explizit freigegebenen Coding-Scope.
- High-Risk = **Phase A (kein Code) → unabhängiges Gate A → Phase B**.
- Kein direkte main-Push, kein Auto-Merge, keine Issue-Closure, kein Folge-Slice ohne Owner Acceptance.
- **Nach 2 verwandten Amendments Ursachen-/Architekturprüfung**.
- **Neue HCD-Erkenntnisse** werden in Akzeptanzkriterien und Gerätetests überführt, nicht bloß in Screenshots.
- Jede neue Session rekonstruiert zuerst Live-GitHub und liest diesen Status und die für ihren Scope geltenden Planungsdokumente.

## 6. Referenzen / laufende Register

- #64: https://github.com/StradaDelSole/proviantplaner/issues/64 – Owner Pixel QA Shopping-/HCD-Register
- #65: https://github.com/StradaDelSole/proviantplaner/issues/65 – Claude Backend-/Release-Audit mit Verifikationsgrenzen
- #66–#71: implementierbare, aber **noch nicht automatisch freigegebene** Umsetzungspakete
- PR #60: https://github.com/StradaDelSole/proviantplaner/pull/60
- PR #63: https://github.com/StradaDelSole/proviantplaner/pull/63

**Pflege:** Nur nach verifizierter Statusänderung aktualisieren; Versions-/SHA-Zahlen nie ohne erneuten Live-Abgleich fortschreiben. Veraltete Oktober-Übergaben und Legacy-Master-Kontexte bleiben ausdrücklich **historisch**.
