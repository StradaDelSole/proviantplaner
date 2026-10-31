# ADR-BC-001 – Provy-only-Kontolöschung bei geteilter Auth0-Identität

**Status:** ACCEPTED – Owner-Produktentscheidung vom 31.10.2026.  
**Kontext:** BACKEND-CORE Phase A · Issue #36 · PR #37 · Hauptrepo `StradaDelSole/proviantplaner`.  
**Gilt für:** Provy-App, Provy-Backend (Cloudflare D1/R2), Provy-Webportal; nicht für HullQ-Fachdaten.

## Entscheidung O-01 (verbindlich)

Die Aktion **„Provy-Konto und Provy-Clouddaten löschen“** löscht alle Provy-spezifischen Cloud-Nutzerdaten und beendet die Provy-Zugangsberechtigung. **Die gemeinsam genutzte Auth0-Identität bleibt bestehen**, ebenso sämtliche HullQ-Daten und andere Produkte, für die dieselbe Identität verwendet wird.

Eine Provy-UI darf weder „Das gesamte HullQ-Konto wird gelöscht“ behaupten noch ohne eine gesonderte, autorisierte HullQ-Kontoentscheidung eine Auth0-Management-API-Löschung auslösen. Die Provy-Webseite zur Kontolöschung muss auch ohne installierte App tatsächlich funktionieren und den Umfang vor der Bestätigung verständlich darstellen.

## Verbindliche fachliche Garantien

1. Gelöscht werden Provy-D1-Daten, Provy-R2-Backups, Provy-Zustimmungen und andere **tatsächlich dem Provy-Konto zugeordnete** personenbezogene Datensätze; das vollständige Inventar ist vor Implementierung gegen Schema, D1/R2 und künftige Quellen zu prüfen.
2. Provy-Anmeldesitzungen und Provy-Berechtigungen werden ungültig/gesperrt; ein altes gültiges JWT darf keine neuen Cloud-Daten anlegen, während die Löschung läuft oder abgeschlossen ist.
3. `GET /v1/me` und andere normale Lese-/Schreibendpunkte dürfen kein gelöschtes oder fehlendes Provy-Konto **automatisch neu erzeugen**. Eine spätere Nutzung erfordert eine **explizite, bewusste Neuregistrierung**. Keine stille Rekonstruktion durch einen Hintergrundrequest.
4. Die Löschung ist auch bei D1-/R2-Teilfehlern idempotent und wiederaufnehmbar; vor vollständiger Durchführung keine irreführende Erfolgsmeldung. Nutzer erhalten bei Fehlern nachvollziehbare Information und Retry-Möglichkeit.
5. Die Löschbestätigung benennt verbleibende HullQ/Auth0-Identität ausdrücklich. Eine spätere Neuregistrierung stellt **keine alten Provy-Backups** wieder her.
6. Lokale Törn-/Bordkassendaten auf dem aktuellen Gerät sind eine gesonderte Datenkategorie. Ob und wann sie bei der Kontolöschung ebenfalls entfernt werden, muss vor Produkt-UI-Abnahme eindeutig und mit separater Warnung/Bestätigung dokumentiert werden. **Keine stillschweigende Löschung lokaler Daten.**
7. `deleted_at`/Tombstone ist ein **technischer Vorschlag**, keine pauschale Erlaubnis, `auth0_sub` unbegrenzt zu speichern. Aufbewahrung, Datenminimierung, Re-Registrierung, Logs und datenschutzrechtliche Pflichtinformationen bedürfen eines klaren Data-Lifecycle-Vertrags. Keine pauschale DSGVO-Compliancebehauptung.

## Abgelehnte Alternative

Provy löscht über die Auth0 Management API die gesamte geteilte Identität und damit möglicherweise den Zugang zu HullQ. **Nicht freigegeben.**

## Technische Designanforderung für Gate A

Vorgesehen ist `active → deleting → deleted → ausdrücklich neu registriert` oder eine einfachere, nachweislich gleichwertige Lösung. Account-Statuswechsel und Rechteprüfung müssen auf der Backend-Seite erfolgen. D1-Kinddaten müssen explizit gelöscht werden, wenn kein Parent-DELETE ausgeführt wird (`ON DELETE CASCADE` greift nicht bei einem bloßen `UPDATE status`). Der R2-/D1-Löschlauf braucht dauerhafte Arbeitsschritte, Retry und Audit ohne sensible Inhalte. Parallele Uploads/Downloads und alte Tokens dürfen keine Daten nach Abschluss wieder erzeugen.

**Gate:** Owner-Produktfrage O-01 ist entschieden. Implementierungsdetail, rechtliche Aufbewahrung und alle Failure-/Race-Tests bleiben Teil von Gate A/Phase B. Keine Freigabe zur Implementierung durch diesen ADR allein.

## Evidenz

Owner-Zustimmung am 31.10.2026 im Provy-Projektchat zu O-01 und O-02; unabhängige Reviewdokumente `BACKEND_CORE_phase_A_independent_review_2026-10-31.md` und `BACKEND_CORE_phase_A_v2_independent_review_2026-10-31.md`.