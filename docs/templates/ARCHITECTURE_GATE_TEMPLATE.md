# Phase A – Architektur-Gate: [SLICE] / [VERSION]

**Status:** DRAFT – KEIN PRODUKTIONSCODE  
**Aktueller main-SHA:** [SHA]  
**Aktiver PR-HEAD, falls vorhanden:** [SHA]  
**Quelle der Owner-Freigabe:** [Dokument/Issue/Datum]  
**Reviewer:** [Rolle]  
**Risiko:** [HIGH/LOW mit Begründung]

## 1. Exact-HEAD-Reconciliation
- Dateien, Services, Models und APIs gelesen:
- Persistente Datenformate / Migrationen / Backup-Versionen:
- Vorherige Owner-Entscheidungen und mögliche Widersprüche:
- Bestehende Tests und realitätsnahe Lücken:

## 2. Scope
**In Scope:**

**Out of Scope:**

**Nicht zu verletzende Rückwärtskompatibilität / Offline-Verhalten:**

## 3. Architektur-Entscheidung
| Option | Vorteile | Nachteile / Failure-Risiko | Kosten / Komplexität |
| --- | --- | --- | --- |
| A (einfachste tragfähige) | | | |
| B | | | |

**Empfehlung und Begründung:**  
**Offene Owner-Entscheidungen:**

## 4. Systemgrenzen und Invarianten
| ID | Invariante (präzise, testbar) | Zuständige Komponente | Failure-Konsequenz |
| --- | --- | --- | --- |
| I-01 | | | |

**Datenfluss / Commit-Punkte / Fehler-Semantik:**

## 5. Failure- und Restart-Matrix
| Zeitpunkt / Trigger | Zustand DB | Zustand Dateien / Cloud | Recovery / Retry | erwarteter Nutzerstatus | Test |
| --- | --- | --- | --- | --- | --- |
| Vor erstem Write | | | | | |
| Nach Write, vor Commit | | | | | |
| Nach Commit, vor Cleanup | | | | | |
| Crash und Neustart | | | | | |
| Disk Full / Timeout / Korruption | | | | | |

## 6. Concurrency-Matrix
| Operation A | Operation B | Race/Interleaving | Lock-/Warte-Regel | Deadlock-/Failure-Test |
| --- | --- | --- | --- | --- |
| Reader | Writer | | | |
| Restore | Reader / Writer | | | |
| Delete | Restore | | | |
| Recovery/Start | laufende Operation | | | |

## 7. Teststrategie & Beweiskraft
| Invariante / Risiko | konkreter Testname | injizierter Fehler nach kritischem Schritt | erwartetes Endergebnis | Art des Nachweises |
| --- | --- | --- | --- | --- |
| I-01 | | | | |

**Manuelle Gerätetests / Live-Cloud (offen):**

## 8. Entscheidung / STOP
- [ ] Alle Invarianten und Grenzen geprüft
- [ ] Fehler- und Parallelitätsmatrix vollständig
- [ ] Alternative Architektur bewertet
- [ ] Abweichungen / Owner-Fragen behandelt
- [ ] Independent Architecture Review erhalten

**Gate A:** [READY / HOLD, Datum, Begründung]  
**Bei HOLD:** KEIN PRODUKTIONSCODE.