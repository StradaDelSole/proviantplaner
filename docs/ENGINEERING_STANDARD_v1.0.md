# Provy Engineering Standard v1.0

**Status:** OWNER-ACCEPTED PROCESS DECISION, 30.10.2026. Gilt für neue und noch nicht abgeschlossene technisch relevante Provy-Slices nach Integration dieser Dokumentation in main.  
**Ziel:** Weniger vermeidbare Review-Amendments durch Architekturklärung VOR Implementierung und durch systemweite, evidenzbasierte Abnahme. Keine Garantie auf null Findings.

## 1. Verbindlichkeit und Quellen

- Bei jedem Einstieg, auch in einem neuen Chat, zuerst aktuellen GitHub-HEAD, README.md, GEMINI.md, AGENTS.md, diesen Standard, den aktiven Slice-Plan und die jüngsten Owner-Entscheidungen lesen. Frühere Chat-Zusammenfassungen und ältere Briefings sind kein Beleg des aktuellen Repository-Zustands.
- Dieser Standard definiert **Arbeitsmethodik**, nicht Produktumfang. Release-Gates, Scope und Owner-Entscheidungen stehen weiterhin in README.md, GEMINI.md und den ausdrücklich owner-accepted Spezifikationen. Ein Plan, Review oder grüner Test gibt niemals einen neuen Slice frei.
- Rollen: **Owner** entscheidet Produkt, Scope, Restrisiken und Acceptance; **Architektur-/Review-Assistent** reconciliiert Anforderungen und prüft Architektur sowie exakten PR-HEAD unabhängig; **Coding-Agent (derzeit Gemini)** implementiert ausschließlich freigegebenen Scope. Review und Coding nicht als unabhängige Evidenz derselben Instanz darstellen.
- Kleine, dokumentations- oder rein darstellungsbezogene Änderungen ohne Risiko für persistente Daten, Sicherheitsgrenzen oder Produktinvarianten dürfen nach begründeter Low-Risk-Einstufung einen verkürzten Architektur-Gate nutzen. Keine automatische Ausnahmeregel.

## 2. Risikoeinstufung VOR dem Coding

**High Risk / zwingend zwei Phasen**, wenn mindestens einer dieser Bereiche betroffen ist:

- SQLite/Drift-Migration, Dateisystem, Cloud-Backup/Restore, Import/Export, irreversible Datenoperationen oder ID-Remapping
- Nebenläufigkeit, Offline-/Online-Synchronisierung, Retry, Idempotenz, Queue, Cancellation, Lifecycle/Restart
- Authentifizierung, Token, Berechtigungen, Guest-Links, öffentliche APIs, personenbezogene Daten oder Privacy/Security
- Bordkassen-/Geldberechnung, Abrechnung, Zahlungs- und Abo-Entitlements
- Cloudflare-Worker, D1, R2, Auth0, Astro-Portal oder sonstige Cross-Component-Integrationen
- Änderungen, die fachliche Invarianten, Formatkompatibilität oder den Nutzer-Datenbestand berühren

Bei unklarer Einstufung **High Risk**. Dokumentiere Begründung und betroffene Grenzen im Architekturbrief.

## 3. Phase A – Architektur & Threat/Failure Review (KEIN Produktionscode)

Der Coding-Agent liefert zuerst nur einen überprüfbaren Design- und Testplan. Pflichtinhalte:

1. **Exact-HEAD-Reconciliation:** main/aktiver PR/Branch-SHA; betroffene Dateien, vorhandene Implementierung, Tests, Dependencies, bestehende Datenformate; Konflikte mit Owner-Entscheidungen.
2. **Scope-Contract:** In-Scope, Nicht-Ziele, Nutzerabläufe, Offline-Anforderungen, Rückwärtskompatibilität, verbotene Nebenwirkungen.
3. **Invarianten:** Präzise Aussagen, die in allen erlaubten Zuständen gelten müssen, inklusive Daten-/Finanzintegrität und Datenschutz.
4. **Architekturoptionen:** Mindestens zwei realistische Optionen bei risikoreichen Entscheidungen, darunter nach Möglichkeit die einfachste Lösung; Trade-offs (Komplexität, Betrieb, Speicher, Offline, Kosten, Failure Cases) und begründete Empfehlung.
5. **Datenfluss und Commit-Grenzen:** Verantwortliche Komponenten, SQLite-/Datei-/Netzwerkgrenzen, wo Erfolg verbindlich feststeht und welche Operation niemals teilweise als Erfolg gemeldet werden darf.
6. **Failure-Matrix:** Vor/während/nach jedem irreversiblen Schritt; Exceptions, Disk Full, Korruption, App-Kill, Crash/Restart, Netzwerk-/Timeout, Wiederholung/Retry, Cancel, Dateinamen/Größenlimits. Für jeden Zustand: Datenbestand, Wiederanlauf, Benutzerfeedback.
7. **Concurrency-Matrix:** Mindestens Reader/Writer, Restore/Writer, Delete/Restore, zwei gleichzeitige Aufträge und App-Start/aktive Operation. Lock-/Lease-Ownership, Warteverhalten, Freigabe bei Fehler, Deadlocks und Prozessgrenzen explizit.
8. **Testdesign:** Invariant-to-Test-Matrix mit überprüfbarem erwarteten Ergebnis; fault-injection NACH dem kritischen Schritt, nicht nur Eingabevalidierung davor; deterministische Race- und Restart-Tests. Bestehende Regressionen benennen.
9. **Offene Entscheidungen:** Was benötigt Owner-/Architekturfreigabe? Ohne eindeutige Lösung oder bei Scope-Ausweitung: STOP, keine Implementierung.

**Gate A:** Ein unabhängiger Architektur-/Review-Assistent prüft die gesamte Lösung und die Failure-/Concurrency-Matrix, nicht nur ein Einzelproblem. Bei risikorelevanter Produkt- oder Infrastrukturentscheidung zusätzlich explizite Owner-Entscheidung. Erst nach dokumentierter Architekturfreigabe folgt Phase B; eine bestehende Slice-Freigabe ersetzt Gate A nicht.

## 4. Phase B – Implementierung auf genehmigtem Design

- Verwende den freigegebenen Architekturstand und einen eigenen Review-Branch. Dokumentiere jede notwendige Abweichung; Änderungen an Invarianten, Recovery oder Scope lösen einen erneuten Gate-A-Check aus.
- Implementiere inkrementell mit testspezifischen Fehler-Injektionspunkten an echten Zustandsübergängen. Keine „bequem grünen“ Tests, die nur Mock-Eingaben vor dem riskanten Schritt zurückweisen.
- Ein technisches Happy Path ist nur der Anfang: Datenkorruption, Prozessabbruch, konkurrierende Operationen, Wiederholungsversuche und Migration alter Daten werden dort getestet, wo sie relevant sind.
- Prüfe Abhängigkeiten und Ressourcengrenzen (z. B. Speicher, Datei-/Payloadgröße, API-Limits, Timeout) anhand konkreter Verträge. Keine nicht verifizierten Sicherheits- oder Deploymentbehauptungen.
- Vor Implementierungsabschluss **adversarial self-review**: (a) Welche Invariante kann der eigene Entwurf verletzen? (b) Welcher Crashpunkt fehlt im Test? (c) Was passiert bei gleichzeitigem Zugriff? (d) Kann ein Fehler fälschlich Erfolg melden? (e) Welche Tests prüfen nur die Implementierung, statt das Nutzerergebnis? Funde werden behoben oder als offene Findings gemeldet.
- Bestehende Programmierregeln 1–10 aus GEMINI.md bleiben unverändert. Produktfeatures aus anderen Slices bleiben verboten.

## 5. Abnahme-Matrix und Evidence

Für jede relevante Invariante eine Zeile: **Invariante → Risiko/Crashpunkt → Testname → tatsächliches Ergebnis → offener manueller Nachweis → verbleibendes Risiko**.

Nachweisklassen nicht vermischen:

- **Code gelesen:** Strukturell nachvollziehbar, aber nicht ausgeführt.
- **Automatisiert ausgeführt:** Exakter Testname und Run/HEAD, echte Assertion auf Endzustand.
- **CI:** GitHub Actions auf exakt dem zur Abnahme vorgestellten PR-HEAD; Flutter analyze + vollständige Flutter-Tests + Backend-Checks, sofern betroffen.
- **Mensch/echtes Gerät/Live-Cloud:** Nur „bestätigt“, wenn tatsächlich vom Menschen bzw. unter realen Bedingungen geprüft; ansonsten „OFFEN“.

Keine Behauptungen wie „atomar“, „crash-sicher“, „vollständig“, „produktiv“ oder „sicher“ ohne definierte Grenzen und passenden negativen Nachweis. Tests werden nicht abgeschwächt, um grün zu werden.

## 6. Independent Review – systemisch, nicht Finding für Finding

Der unabhängige Reviewer prüft **einen vollständigen Querschnitt** aus Datenmodell, API, Lifecycle, Restore, Fehlern, Nebenläufigkeit, Security/Privacy und Testrealismus – am exakten HEAD. Er erstellt zuerst eine konsolidierte Findings-Liste nach BLOCKER / HIGH / MEDIUM / LOW und prüft gemeinsame Ursachen, statt isolierte Patches zu erzwingen.

- **BLOCKER:** Datenverlust, falsche finanzielle Abrechnung, Auth-/Privacy-Bypass, inkonsistenter Recovery-Zustand oder fehlender grundlegender Acceptance-Nachweis → keine Freigabe.
- **HIGH:** Relevante Integritäts-/Sicherheitslücke oder nicht kontrollierter Fehlermodus → Korrektur oder dokumentierte Owner-Risikoentscheidung.
- **MEDIUM/LOW:** Schwere und Release-Relevanz begründen; kein unbegrenztes Polishing ohne Nutzerwert.
- **Nach zwei inhaltlich zusammenhängenden Amendments** wird der Patch-Modus gestoppt: Architektur-/Scope-Neubewertung und ggf. kleinerer Slice oder einfacheres Design, bevor weiterimplementiert wird. Ziel ist Ursachenbehebung, nicht endloses Lock-/Journal-Patching.
- Nach jeder Amendment-Runde erneut systemweit prüfen, ob neue gemeinsame Grenzen verschoben wurden.

## 7. Verbindliche Abschlüsse

**Design-Review-Report (Phase A):** HEAD; Abhängigkeiten; Optionen; Entscheidung/Owner-Fragen; Invarianten; vollständige Failure- und Concurrency-Matrix; Testplan; Gate-A-Status READY/HOLD.

**Implementierungs-Report (Phase B):** exakter HEAD, geänderte Dateien, Tracing Invarianten→Tests, CI-Run + Job-Status, noch offene reale Gerätetests, Risiken, Änderungen am Architekturentwurf. Danach **STOP**. Keine automatischen Merges, keine Issue-Closure, keine Freigabe des nächsten Slices ohne ausdrückliche Owner Acceptance.

**Bei neuem Chat:** Zuerst aktuelle GitHub-Quellen lesen, dann Phase/Gate des aktiven Slices rekonstruieren und nur die tatsächlich freigegebene nächste Aktion vorschlagen. Kein automatisches Coding oder Merge aus diesem Standard ableiten.

## 8. Vorlagen

- docs/templates/ARCHITECTURE_GATE_TEMPLATE.md – Phase A, auszufüllen vor High-Risk-Coding
- docs/templates/IMPLEMENTATION_BRIEF_TEMPLATE.md – Phase B, nach akzeptiertem Architekturentwurf

Dieser Prozessstandard ersetzt weder die bestehende Produktentscheidung noch die Regeln über Review-Branches und GitHub Actions.