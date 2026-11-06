# PROVY – HCD Shopping Journey Reconciliation und Implementierungsplan

**Version:** 1.0-plan · **Owner-Entscheidung:** 05.11.2026 „allen Punkten zugestimmt, im Projekt und Repo verbindlich festhalten“  
**Status:** **PRODUCT DIRECTION APPROVED, IMPLEMENTATION GATED** – keine erteilte Erlaubnis zu beliebigem Coding/DB-Migration/Merge.  
**Quellen:** Owner Pixel-7-Pro-Beobachtungen; `main e00c01d` Code; Claude `PROVIANTPLANER_ANALYSE_v0.1.md` (älterer main-Stand); unabhängige Repo-Reconciliation; #64/#66–#68.  
**Konflikt:** bisherige Owner-accepted UX-D-Informationsarchitektur bleibt erhalten; größere Abweichungen bedürfen expliziten Owner-Entscheidungsnachtrags.

## 0. Rationale und verbindlicher Outcome

Nicht nur einzelne Bugs reparieren. Die Reihenfolge der *Tätigkeiten* muss natürlich werden: **Törn planen → Provisionen bestimmen/ändern → Einkaufstag und Stopp planen → Artikel/Mengen dem Stopp zuordnen → Einkauf → Fehlendes behandeln → Einlagern jetzt/später → Bordkasse/Abrechnung**. Die App führt ohne Sackgassen und zeigt immer nur den nächsten fachlich sinnvollen Schritt. Keine ungefragte Bestellung, automatische Mengenübernahme, Kostenbuchung oder Datenlöschung.

Ein echter Pixel-Test des Owners ist **maßgebliche HCD-Evidenz**, aber ersetzt nicht unabhängige Nutzerbeobachtung. PR #60 ist technisch grün, **produktseitig HOLD**, bis der kritische Einkaufspfad erneut auf dem Pixel überzeugt.

## 1. Zustandsmodell und Sprache

Unterschiedliche Entitäten dürfen nicht in einen einzigen `TripPhase`-Wert zusammengedrückt werden:

| Entität | Zustände / Fragen | Nicht verwechseln mit |
| --- | --- | --- |
| Törn | Planen, Einkaufen, Einlagern, Unterwegs, Abschluss (bestehende Phase) | Abschluss einzelner Einkaufsstopps |
| Einkaufsstopp | Liste leer/unzugeordnet, vorbereitet, Einkauf begonnen, (teilweise) gekauft, abgeschlossen, Wiederaufnahme | Anzahl abgehakter Produkte |
| Artikel im Stopp | Geplant, gekauft, nicht gekauft/verschoben, rückgängig gemacht | Globaler Artikel `isAdopted` und Lagerung |
| Einlagern | Noch offen, in Arbeit, abgeschlossen | Checkout erfolgreich, nächster Einkauf |
| Bordkasse | Ausgabe noch nicht erfasst, bestätigt, berichtigt | Einkaufsstopp abgeschlossen |

**Wichtig für Datenbank:** Vor Designentscheidung untersuchen, ob ein Stoppstatus zuverlässig aus bestehenden `ListItemAllocations.isBought`, Stopps und `TripPhase` abgeleitet werden kann. Bei explizitem Abschluss auch bei 0 Artikeln oder späterer Wiederaufnahme kann Persistenz notwendig sein. **Nicht** still ein neues Boolean `isComplete` einfügen oder bei erstem Häkchen den gesamten Törn auf `storage` setzen. High-Risk Gate A mit Alternativen, Migrations-/Restorekompatibilität, Datenintegrität.

## 2. Screen-by-Screen – Sollablauf

### A – Törnübersicht / Command Center

- Karten „Vorräte“, „Einkauf“, „Crew & Boot“, „Bordkasse“ bleiben.
- In „Einkauf“ zeigen **pro Stopp** Tag, Namen, Status, offene Positionen, gekaufte Positionen und genau eine hervorgehobene kontextuelle Handlung:
  - *Noch keine Artikel zugewiesen*: **Liste vorbereiten**.
  - *Liste vorbereitet, Einkauf nicht begonnen*: **Einkauf starten**.
  - *Teilweise gekauft / unterbrochen*: **Einkauf fortsetzen**.
  - *Abgeschlossen*: **Einkauf ansehen** / sekundär „Erneut öffnen“ (nicht automatisch Start).
  - *Einlagern aufgeschoben*: sichtbar über der Folgeaktion **Einlagern fortsetzen**; Stoppgeschichte bleibt zugänglich.
- Kein großer globaler „Einkauf starten“-Button, der immer zum ersten Stopp springt und seinen Abschluss ignoriert.
- Bei mehreren Stopps: klare chronologische Tagesliste, keine stille Neuverteilung. Ein abgeschlossener Einkauf kann angesehen werden; späterer Einkauf für weitere Tage darf weiterhin planbar sein.

### B – Neuen Einkaufsstopp anlegen / bearbeiten

- Formularreihenfolge **Tag → Name**.
- Name startet als `Einkauf Tag N` (aus lokalisiertem Generator).
- Ändert Nutzer den Tag, folgt der **automatisch erzeugte** Name; sobald Nutzer den Namen selbst ändert, bleibt er auf weiteren Tageswechseln erhalten; optional „Standardname wiederherstellen“.
- Dasselbe Verhalten **im Törn-Übersichtsformular, Timeline-Dialog und Follow-up nach aufgeschobenen Artikeln**. Ein Edit bestehender Namen darf absichtlich andere Werte nicht überschreiben.
- Nach „Speichern“ sichtbar **„Liste für diesen Einkauf vorbereiten“** und ggf. automatisch Fokus auf diesen neuen Stopp; **nicht** ohne Hinweis in die Törnübersicht zurück.
- Akzeptanz: Tag 14 → 6 führt zu `Einkauf Tag 6`, manuell `Markteinkauf Cres` bleibt auch bei Wechsel auf Tag 7 erhalten, sofern ausdrücklich vom Nutzer geändert.

### C – Einkaufsliste vorbereiten / Zuordnung

- Es gibt eine **globale Proviantliste** und **Stopp-Zuordnungen**. Ein neuer Stopp erhält nicht ungefragt Kopien sämtlicher Produkte.
- Sichtbare `Artikel zuordnen`-Aktion und Stopp-Banner („Für Tag 6: 0 zugeordnet“). Bestehende `StopAllocationSheet` und Mengen-/Paketregeln verwenden, zuerst zuverlässig discoverable machen.
- Start shopping ohne zugeordnete Positionen darf nicht zu verwirrender leerer Shop-Ansicht führen. Klarer Empty State + Action `Artikel zuordnen` / `Zur Vorratsliste`.
- Hauptaktion `Packungsgröße bearbeiten`: beim Artikel explizites Stift-Symbol/„Bearbeiten“ statt ausschließlich unsichtbarem Tap auf Namen. Stepper bleiben als schnelle Mengenänderung; 44–48dp Targets, Screenreader-label.
- Bei Spannungsfall Bedarf vs manuelle Menge ist **manuelle Wahl authoritative**; kein ungefragtes Überschreiben durch Recalculation.

### D – Shopping Mode (Top P0)

- Start bei **Offen (N)**, nicht bei ständig wachsender gekaufter Liste.
- Beim Klick „gekauft“: sofort erkennbare, wahrheitsgetreue Rückmeldung; nach bestätigter Persistenz wechselt Position zur **eingeklappten** Sektion **Erledigt (N)** am *Ende*, ohne Scrollposition des nächsten offenen Artikels zu verschieben oder nach oben zu springen.
- Für Undo/versehentliches Abhaken: Aktion `Rückgängig` und jederzeit erweiterbare Erledigt-Sektion. Daten bleiben erhalten, keine Duplikate, keine Soft-Delete-Fälschung.
- Abteilungsstruktur respektieren und wichtige Abteilungsüberschriften während des Einkaufs nicht verlieren; wenn „Offen“ nach Abteilungen, „Erledigt“ global ist, explizit testen, ob der Shopper Abteilungswechsel nachvollziehen kann.
- Kein kompletter `Scaffold`/Listen-Unmount beim `tripShoppingListProvider` Reload: alten guten Stand anzeigen während Refresh, echte Fehler/Retry getrennt behandeln. Nur einen Datenänderungspfad statt doppelter `ref.invalidate`.
- **Scroll-Anker / visuelle Kontinuität:** bei 30+ Items und mittiger Scrollposition bleibt der nächste offene Artikel im Blick. Nicht „erst ins Bild springen, dann weg animieren“. Verwende stabile Keys/semantische Item-Identitäten, passende Sliver/List- und Anker-Strategie; Entscheidung durch Widget- und Pixel-Tests, nicht allein `ScrollController.offset` blind speichern.
- Optimistic UI nur mit klarer in-flight-State/Failure-Rollback-Strategie und keinen falschen Erfolgsmeldungen. Eindeutige Sperre gegen Doppel-Taps, Undo auch bei schnellem Wiederöffnen.
- `Fertig eingekauft` prüft noch offene Positionen und bietet **nicht gekauft: späteren Stopp zuordnen / bewusst verwerfen**, mit klarer Mengenbilanz.

### E – Einkauf abschließen → Einlagern

- Bei „Später einlagern“ **bleibt** die Aufgabe persistent auffindbar: in Törnübersicht **Einlagern fortsetzen**, bei Bedarf auch im Einkaufsabschnitt; **kein** Markieren der Lagerung als abgeschlossen.
- Bei „Jetzt einlagern“ öffnet sich die bestehende Storage-Checkliste; nach erfolgreicher Bearbeitung bleibt ein verständlicher Weg zurück zur Törnübersicht.
- Nach App-Kill/Neustart und mehreren Einkaufsstopps kein Dead End; bereits abgehakte Lager-Hinweise bleiben wahrheitsgetreu.
- Offene Frage für Gate A: ist Lagerung global oder stoppbezogen? Bestehende globale Hints dürfen nicht ohne Datenmodellentscheidung in separate Lagerzustände aufgespalten werden.

### F – Welcome / erster Eindruck

- `PROVY / Provision smarter. Sail lighter. / Plan provisions. Share crew costs. Settle with ease.` ist **Owner-approved Copy**; moderne minimalistische ~1.2-s Animation bleibt.
- One-time first-run Welcome kann auf installierter Test-App mit bestehenden Törns logisch **übersprungen** werden; deshalb neue Action **„Welcome erneut ansehen“** im Hilfe-/Mehr-Bereich, non-destructive und ohne Änderung des persistenten `seen`-Status, kein Logout/Neuinstallation.
- Routine-App-Start niemals künstlich auf 1.2s verlängern; Bootstrap-Branding nur während echter Initialisierung. Crash/Recovery/Keystore-Bypass semantisch sicher.

## 3. Fachliche Daten und Menge

- `catalog_v0.11`: (canned_fruit → fruit → frisches), (sauerkraut → veg_salad → frisches), (dried_fruit → fruit → frisches), obwohl passende Departments konserviert/trocken sind. Das ist eine **Hierarchie-/Taxonomiefrage**, nicht blind verschobene Department-ID. Audit mit allen **232 Varianten** und vorhandenen sechs Lokalisierungen.
- **Produktart ≠ Einkaufsabteilung ≠ Haltbarkeit ≠ Lagerung**. Gemeinsame IDs und Backups dürfen nicht durch unüberlegte Kategorieverschiebung ungültig werden.
- `butter_salted` standardmäßig nicht ausgewählt, daher Engine-VariantNeed=0, aber manuell hinzugefügt z. B. 1 × 250 g: UI darf nicht `Bedarf 0 g` ausweisen. Trenne bewusst **gekaufte/geplante Menge** von **optionalem Richtwert**; lieber Hinweis weglassen als unwahre Genauigkeit.
- **Owner-Diskussion offen:** A = keine Vorschläge; B = nur gezielte optionale Richtwerte in Proviant-Review; C = umfassende Variante-für-Variante-Vorschläge. B ist **vorgeschlagene Richtung, nicht final akzeptierte Engine-Policy**. Bis Owner entscheidet: keine globalen Engine-Änderungen. Bedarf 0 als falsche Display-Logik kann nach genehmigtem Einzelbrief korrigiert werden.
- Katalogquellen: **31/47 `estimate`**, 16/47 `research`; beides keine Garantie für individualisierten Bedarf. Pilot mit echten Törns und Rückmeldung (zu wenig/zu viel/Nachkauf), ohne Trackingzwang; Fachübersetzungen mit Muttersprachlern prüfen.

## 4. Umsetzungssequenz mit Stop-Regeln

| Schritt | GitHub | Eingriff | Pflicht-Evidence / Gate |
| --- | --- | --- | --- |
| 0 – Produkt-/Statusdoku | PR #63 / #64 | nur Docs | independent Docs-Review + Owner acceptance, kein Code |
| 1 – Scroll & Erledigt | #66 | begrenztes Flutter Shopping UI, Provider-Sicht | exakt geprüftes HEAD, Widget-Scrollregression, Pixel 7 Pro, HCD Outcome |
| 2 – Stopp-Lifecycle & Einlagern | #67 | Navigation + evtl. Drift/Backup | **High Risk Gate A**, Persistenz-Entscheidung, Crash/Restore, dann eigener Phase B |
| 3 – Katalog/Artikelbearbeitung | #68 | Daten, UI, evtl. Quantity Engine | Daten-/Migration-Impact; Richtwertpolicy bleibt Owner-Gate |
| 4 – Welcome & bestehende PR | #62/#60 | Preview / Nachbesserungen nur begründet | Anfang/replay/restart, Nightwatch, kein blindes Auto-Merge |
| 5 – Kernjourney E2E | #71 | nur Test-/Eval-Protokoll | Real Pixel/anderen Nutzer, Offline- und Neustartnachweis |
| 6 – parallele Production Gates | #69/#70 | Android/iOS, P05/BC-1B | getrennte Phase A/Phase B, kein Produkt-Deploy |

### Slice-01 Mindest-Auftrag (nächster möglicher Code-Release)

**HCD-SHOP-01 / #66**: Erstelle zunächst einen kleinen, präzisen Implementation Brief. **Nicht direkt aus diesem Plan automatisch implementieren.** Inputs: aktueller HEAD/PR #60, genaue per-stop `toggleBought`-Persistenz, Domain-Modelle, geladene AsyncProvider, reale 30+-Artikel-Liste. Umfang: Scroll-Anker beim Abhaken, Status-/Fehlerfeedback, Erledigt (N) standardmäßig eingeklappt, Undo und keine Double-Invalidierung. Out of Scope: neue Trip-/Stop-Migration, Welcome-Design, Katalogschema, Mengenengine, Backend. CI + Device Gate. **Riskklassifizierung begründen**: falls Nebenläufigkeit/Persistenz betroffen, Gate A; bei reinem View-State mit bestehenden Services Low-Risk nur nach Nachweis.

### Slice-02 Architekturfragen (Phase A, KEIN CODE)

**HCD-SHOP-02 / #67**: dokumentiere Lebenszyklusdiagramm mit **mehreren** Stops über Tage, erste/manuell verteilte Mengen, abgebrochener/teilweiser Einkauf, `später einlagern`, Unterwegs-Phase und Wiedereröffnung. Mindestens zwei persistenzkompatible Alternativen (abgeleitet vs expliziter Stopstatus). Crash-/Datenmigrations-/Restore-Matrix und nicht-destructive Übergänge. Nach unabhängigem Gate A und Owner-Wahl separate Freigabe zu Phase B.

## 5. Menschzentrierte QA-Abnahmematrix

| Szenario (ohne UI-Vorführung) | Muss beobachtbar funktionieren |
| --- | --- |
| 6 Crew, 14 Tage, Tag-6-Stopp | Tag 6 → automatisch `Einkauf Tag 6`; eigener Name bleibt |
| Stopp ohne Artikel | klare Aktion `Liste vorbereiten`; kein sinnloser Einkauf |
| Basisstopp + zweiter Stopp | Mengen korrekt verteilt, keine Duplikate, kein ungewolltes Mitnehmen |
| 40 Artikel, Mitte der Liste | 5× nacheinander kaufen, **nächstes offenes bleibt sichtbar**, kein Sprung |
| 3 gekauft, Undo | alle Count-/Persistenzzustände stimmen, keine Doppelzeilen |
| Einkauf unvollständig | Nachkauf-/Verschiebe-/Verwerfen-Dialog, keine stillen Verluste |
| „Später einlagern“ + App-Kill | Wiederstart zeigt **Einlagern fortsetzen** |
| Einkauf abgeschlossen | „Einkauf ansehen“ statt „Einkauf starten“ |
| Gesalzene Butter als manuelle 1×250 g | sichtbarer Pack-Edit, **kein „Bedarf 0“** |
| Obstkonserve/Sauerkraut | nicht als „Frisches“ missverständlich, Shop Department bleibt Konserven |
| Welcome für bestehenden Testtörn | Preview erreichbar ohne Datenlöschung; Normalstart nicht blockiert |
| Kein Netz / Handy unterbrochen / Font 1.5x | alle Kernhandlungen sicher, verständlich, bedienbar |

Testklassen **separat** dokumentieren: Unit/Widget/CI ≠ Owner Pixel QA ≠ unabhängiger Nutzer ≠ realer Törn. Neue UI-Pakete **vor** finalem Review mindestens einmal früh physisch testen, damit grüne CI keine bedienungsfeindliche Oberfläche kaschiert.

## 6. Abnahme, STOP und bestehende Entscheidungen

- Änderungen an eingefrorener IA, Produktcopy/Bedarfspolicy oder Backend/Finance-Invarianten benötigen **eigene Owner-Entscheidung**. Dieses Dokument autorisiert keine generische Neuimplementierung.
- Offen = nicht done: PR #60 Owner UX HOLD. Release-Gates #69/#70 unabhängig.
- Keine direkte Hauptbranch-Änderung, kein Mergen/Schließen ohne explizites Owner Acceptance.
- HCD umfasst auch Timeouts, Fehlertexte, sichere Wiederaufnahme, Daten- und Geldvertrauen. Eine visuelle Anpassung allein ist kein HCD-PASS.
