# Phase B – Implementation Brief: [SLICE] / [VERSION]

**Status:** DRAFT – Code nur nach Gate A und Slice-Release  
**Aktueller main-SHA:** [SHA]  
**Review-Branch / PR:** [Branch / PR]  
**Owner-Release:** [Datum / Quelle]  
**Akzeptierter Phase-A-Entwurf:** [Pfad, Version, HEAD, Review-Status]

## 1. Präziser Scope und Einschränkungen
**Zu implementieren:**

**Nicht implementieren / keine stillen Produktänderungen:**

**Zulässige Dateien / Datenmigrationen / Paketänderungen:**

## 2. Bindende Architektur & Invarianten
| ID | Invariante | Implementierungsort | Test |
| --- | --- | --- | --- |
| I-01 | | | |

**Commit-/Recovery-/Retry-/Concurrency-Vertrag gemäß Gate A:**

## 3. Implementierungsfolge
1. Baseline lesen, Branch und exakten HEAD dokumentieren.
2. Datenvertrag / Migration / Kernlogik mit passenden Tests.
3. Integration und UI / API / L10n.
4. Negativpfade, deterministische Crash- und Race-Tests.
5. Adversarial Self-Review; Architektur-Änderungen ggf. zurück zu Gate A.
6. Dokumentation und PR aktualisieren; Full-QA am finalen HEAD.

## 4. Pflicht-Testmatrix
| Test | Typ (Unit/Integration/Failure/Race/Migration) | tatsächlich erwartete Assertion | Status |
| --- | --- | --- | --- |
| | | | |

**Bestehende Regressionen, die nicht verändert/abgeschwächt werden dürfen:**

**Manuelle Tests auf echtem Gerät / Live-Backend (OFFEN bis bestätigt):**

## 5. Self-Review – Gegenbeispiele
- Falsche Erfolgsmeldung bei Teilfehler?
- Crash exakt vor/nach Commit und vor/nach Cleanup?
- Gleichzeitig laufender Restore, Delete und Reader/Writer?
- Fehlende/veraltete Daten, Alte-Version-Backup, unbekannter Enum-Wert?
- Sicherheit/Datenschutz, Ressourcenbudget und Eingabevalidierung?
- Bestehende Tests messen Endzustand oder nur Aufruf?
- Kleinere oder robustere Option übersehen?

**Befunde und Tests:**

## 6. Abschlussbericht / Review-Gate
- Exakter PR-HEAD:
- Dateiliste und nachvollziehbare Deltas:
- Invarianten-Testnachweise:
- GitHub Actions Run (exakter HEAD) + Jobs:
- Offene Risiken und echte Gerätetests:
- Architekturableichungen, Owner-Entscheidungen:
- Independent Review: [PENDING]
- Owner Acceptance: [PENDING]

**STOP:** PR nicht mergen, Issue nicht schließen, keinen Folgeslice starten.