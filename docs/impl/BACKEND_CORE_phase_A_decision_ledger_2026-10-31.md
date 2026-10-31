# BACKEND-CORE – Phase-A-Entscheidungsstand und Gate-Ledger (31.10.2026)

**Stand:** main `2ec14c66e825078990689b5a753f1566bed13405`. **Docs-PR:** #37 · **Tracking:** Issue #36.  
**Gate A: HOLD** (Owner-Grundsatzentscheidungen geschlossen; technische Architektur-Spezifikation teilweise noch PROPOSED). **Kein Produktionscode, kein Deployment, kein B3/B4/B5/GUEST1-Release.**

## Owner-Accepted Produktentscheidungen

| ID | Entscheidung | Evidenz | Status |
| --- | --- | --- | --- |
| O-01 | Bei Provy-Kontolöschung ausschließlich Provy-Cloud-Daten und Berechtigungen entfernen. Gemeinsame Auth0-/HullQ-Identität und HullQ-Fachdaten bleiben erhalten. | `docs/adr/ADR-BC-001-provy-only-account-deletion.md` | **ACCEPTED 31.10.2026** |
| O-02 | 50 MiB Summe rohe Belegbildbytes bleiben Cloud-Backup-Produktziel, keine willkürliche Kürzung. | `docs/adr/ADR-BC-002-cloud-backup-50mib-receipts.md` | **ACCEPTED 31.10.2026** |
| O-03 | D1/R2-EU-Jurisdiktion bleibt verbindlich. | `docs/BACKEND_KONZEPT_v0.2.md`; `--jurisdiction=eu` | Bestehende Anforderung; echtes Stage/Prod-Resource-Audit **OFFEN** |

Die eigentlichen User-Entscheidungen werden nicht noch einmal an Gemini delegiert.

## Technische Architekturverträge

| Vertrag | Entscheidungsvorschlag | Noch nicht belegt |
| --- | --- | --- |
| Wire / Versionierung | `ADR-BC-003`: additive `/v2/backups` Stream-API; alte `/v1`-JSON-Verträge während Migration nicht überschreiben; Snapshot-Formatversion separat. | Client-File-/Memory-Umsetzung, Durchgängigkeit, 50-MiB-Plus-Daten-Transportlimite, mobile Hardware-/Worker-Messungen |
| D1/R2-Lifecycle | `ADR-BC-004`: pending/active/deleting, stable client idempotency key, account active/deleting/deleted, konditionale Aktivierung, bounded Cron-GC, kein 5-min-Fixed-Lease. | Late-put/GC-Fencing-Mechanismus, Per-Account-Race-Beweis, Leases/Quotas, Fehler-/Retry-/Löschkonzept |
| Account-/Entitlement-Autorität | Auth0 für Authentication, Provy Backend für Provy-Authorisation. Explizites Register, keine `GET /me`-Auto-Projektion. | Entitlement-Quelle/Expiry/Offlinevertrag, Lösch-/Re-Register-Privacy/UX-Fristen |
| Persistenzumfang | Snapshot-v4 mit `checkState`, `isAdopted`, Lieferanten/Bestellungen samt ID-Remapping; Tokens/private Bankverbindungen ausgeschlossen. | Komplettes Quelleninventar, DB-Migration/Kompatibilität, Gerätebackup-/Restore-Drills |

## Nur noch gezielte Gate-A-Arbeit, kein neues allgemeines Amendment

1. **Tech-Spike-Design (ohne Feature-Implementierung):** konkreter, testbarer Fencing-/Lease-/GC-Ablauf und D1-CAS-Algorithmus samt Deadlock-/Races-Nachweis als eine überschaubare Sequenz; wenn nicht plausibel, begrenzte alternative R2-Upload-Architektur vorstellen.
2. **Payload/Device-Proof-Plan:** klar beschreiben, welche Last- und Speicher-Messungen eine technische Gate-A-Annahme stützen, und welche erst in Phase B auf Stage/realem Gerät erbracht werden können. Keine angeblich ausgeführten Tests, keine Garantie für 75 MB ohne Nachweis.
3. **Auth/Entitlements/Deletion-Vertrag:** Provy-only-Löschung mit minimalem Tombstone und ausdrücklichem Re-Register, keine impliziten Rechte; genaue rechtliche/UX-Fragen als Release-Gates statt fingierter Compliance.
4. **Owner-Setup:** echte Auth0-App/Audience/Callback-/Logout-Config, gewählte Stage-/Prod-Domains und EU-D1/R2-IDs erst nach Plan-Abnahme einrichten. Secrets niemals ins Repo kopieren.
5. **Final Independent Architecture Review:** ADR-003/004 erst bei passendem Nachweis ACCEPTED markieren. Danach Phase B in **kleine, jeweils explizit vom Owner freigegebene** Slices schneiden und implementieren lassen.

## Phasenabgrenzung

- **Gate A:** Methode, Invarianten, Zustandsübergänge und testbare Akzeptanzkriterien genehmigt. Umsetzung noch nicht automatisch freigegeben.
- **Phase B:** Implementierung erst nach eigenständigem Owner-Go, mit End-to-End-Worker+Flutter+Portal-Contract-/Failure-Tests am exakten HEAD.
- **Stage/Store:** echte Cloudflare-EU-Bindings, Auth0, Kamera/Share und Backup-/Delete-Drills nachweisen. Keine Simulation als produktiven Test deklarieren.

**Nächster Schritt:** schmaler technischer Gate-A-Review zu ADR-003 und ADR-004, nicht ein dritter umfangreicher Gemini-Bericht.