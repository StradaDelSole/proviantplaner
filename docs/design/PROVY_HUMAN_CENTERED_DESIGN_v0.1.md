# PROVY – Human-Centered Design (HCD) als verbindliches Produktprinzip v0.1

**Owner-Entscheidung:** 05.11.2026 – Human-Centered Design wird ausdrücklich als formales PROVY-Produktprinzip akzeptiert.  
**Dokumentstatus:** Owner-Entscheidung festgehalten; Integration in `main` erst durch separaten Dokumentations-PR und ausdrückliche Owner-Acceptance.  
**Geltung:** Neue und wesentlich geänderte Consumer-Flows, UX-D / Issue #21, entscheidende Store-v1-Nutzerreisen und wesentliche UX-Korrekturen.

## 1. Verbindlicher Grundsatz

> **Wir gestalten PROVY für Menschen, ihre realen Aufgaben und die Bedingungen an Bord – nicht rund um die Möglichkeiten der Software. Eine Interaktion ist dann gelungen, wenn Nutzer ihre Aufgabe ohne unnötiges Denken, Suchen, Irrtümer oder unbegründete Unsicherheit zuverlässig erledigen können.**

Dies ist eine **Produktqualitätsregel**, keine neue Bibliothek, kein Style-Trend, keine eigenständige Freigabe zum Coding und kein Ersatz für Engineering-Sicherheit. Ein visuell attraktives Design allein ist kein HCD-Nachweis. Grünes CI allein ist kein Usability-Nachweis.

Leitfrage vor jeder bedeutsamen UX-Entscheidung: **Wem hilft diese Änderung bei welcher realen Aufgabe, in welchem Kontext – und woran erkennen wir, dass sie tatsächlich hilft?**

## 2. Menschen, Tätigkeiten und Nutzungskontexte

Wir unterscheiden tatsächliche Aufgaben und Situationen statt eine generische Persona für alle Screens anzunehmen:

| Kontext | Aufgabe | Zu berücksichtigen |
| --- | --- | --- |
| Skipper bei der Planung | Törn anlegen, Crew/Boot erfassen, Proviant auswählen | Überblick, erklärbare Assistenz, bestätigte statt erfundene Defaults |
| Einkaufen vor der Abfahrt | Produkte finden, Packungen/Mengen ändern, abhaken | Zeitdruck, einhändige Bedienung, volle Hände, Unterbrechungen, große Touch-Ziele, schnelle Wiederaufnahme |
| Crewmitglied als Einkaufshelfer | Nur das zugewiesene Paket abarbeiten | Kein App-/Account-Zwang, minimaler Kontext, schlechte Verbindung, verständliche Status-/Offline-Semantik |
| Bordkasse unterwegs | Einzahlung, Ausgabe, Währung und Zahler erfassen | Kurz und fehlervermeidend, Offline-Fähigkeit, korrigierbare Eingaben, keine stillen Annahmen |
| Törnabschluss | Kosten verstehen, Ausgleichszahlungen prüfen, Belege teilen | Vertrauen, verständliche Nettosalden, Nachvollziehbarkeit, richtige Beträge/Empfänger |

Gerät und Umgebung gehören zur Aufgabe: 320-dp-Displays, Pixel/Android und iOS, Sonnenlicht, Dunkel-/Nachtwache, größere Schrift, Reduced Motion, schlechte/fehlende Verbindung und Unterbrechungen. Wir prüfen diese Fälle risikobasiert, nicht pauschal alle Kombinationen bei jeder Farbkorrektur.

## 3. Verbindliche Gestaltungsprinzipien

1. **Aufgabenzentriert statt featurezentriert.** Jeder Screen hat eine eindeutige primäre Aufgabe und eine erkennbare nächste Handlung; keine neuen Dashboard-Flächen allein für vorhandene Features.
2. **Recognition before recall.** Optionen, Status, aktuelle Mengen und Wege sichtbar machen. Versteckte Swipes/Long-Press dürfen nie der einzige Zugang zu einer Kernfunktion sein.
3. **Cognitive load reduzieren.** Nur jetzt relevante Informationen zeigen; progressive disclosure, klare Begriffe in der Sprache des Nutzers, konsistente Positionen. Weniger Klicks sind kein Selbstzweck, wenn Unsicherheit oder Fehler steigen.
4. **Sofortiges, wahrheitsgetreues Feedback.** Eingabe angenommen, Speichern läuft, bestätigt, fehlgeschlagen, offline/vorgemerkt – diese Zustände dürfen nicht verwechselt werden. Keine Erfolgsgeste vor tatsächlicher Persistenz.
5. **Fehler verhindern und korrigierbar halten.** Undo, Mengen-Untergrenzen, explizite Löschaktionen, verständlicher Retry; finanzielle Berechnungen und Stopp-Zuordnungen niemals still überschreiben.
6. **Nutzerkontrolle.** Der Skipper erstellt die Liste und trifft fachliche Entscheidungen; Provy empfiehlt, überprüft, erklärt. Annahmen wie Restaurantbesuche nie ungefragt konkreten Tagen zuordnen.
7. **Bedienung unter realen Bedingungen.** Eine Hand, große Touch-Ziele, Fokus-/Screenreader-Pfade, ausreichender Kontrast in Light/Dark/Nightwatch, sinnvolle Alternativen zu Gesten, Rücksicht auf Reduced Motion und offline-first.
8. **Motion ist funktional.** Animation zeigt Beziehung, Status oder Ortswechsel; sie darf Kernaufgaben nicht verzögern, Systemzustände vortäuschen oder Performance/Lesbarkeit verschlechtern.
9. **Bekannte Muster vor Eigenkonstruktionen.** Instacart für Catalog/Shopping, Airbnb für Trip/Context, Material 3 als Component-Basis; keine Marken- oder Pixelkopie.
10. **Evidenz vor Geschmack.** Beobachtete Aufgabenerfüllung, Fehler und Verständnis sind aussagekräftiger als die Antwort auf „Gefällt dir der Screen?“.

## 4. Lightweight-HCD-Ablauf für UX-Slices

Für **neue oder wesentlich veränderte Kernabläufe** ist ein kleiner, dokumentierter HCD-Pass verpflichtend; bei rein technischer Fehlerbehebung oder Mikro-Kosmetik genügt eine risikobasierte Kurzbegründung im Review:

1. **Aufgabe und Kontext formulieren:** Wer erledigt was, wo, mit welchen Unterbrechungen/Einschränkungen? Bekannten Zustand und Nutzerziel notieren.
2. **Lösungsannahme formulieren:** Welcher konkrete Reibungspunkt wird reduziert? In welchen Zuständen könnte die neue UX schaden?
3. **Kritische Pfade prüfen:** Happy Path, Irrtum/Undo, Persistenz-/Offline-Fehler, Zurücknavigation, Entitlement/Login, Accessibility, Nightwatch.
4. **Verhalten beobachten:** Mindestens ein passendes realistisches Szenario mit einem *nicht am Design beteiligten* Menschen für formative Prüfung anstreben; für wesentliche Launch-Flows nach Möglichkeit mehrere voneinander unabhängige Nutzer aus relevanten Gruppen. Anzahl/Methodik begründen und Evidenzgrenzen offenlegen. Kein fester „5 Nutzer = bewiesen“-Mythos.
5. **Erkenntnisse priorisieren:** BLOCKER / HIGH / MEDIUM / LOW nach gescheiterter Aufgabe, finanzieller/Datenschutz-Folge, Fehlbedienung, Verzögerung oder rein optischem Detail. Iterieren und erneut prüfen, wenn die relevante Nutzeraufgabe betroffen ist.
6. **Konsolidierten HCD-Nachweis** im UX-Review oder Slice-Bericht ablegen; Technikreview und echte Nutzerbeobachtung explizit trennen.

**Für jede beobachtete Aufgabe** möglichst erfassen: konnte sie ohne Hilfestellung abgeschlossen werden (ja/nein/teilweise), Fehler/Rückwege, Zeit oder unnötige Schritte als Kontext, Stellen des Zögerns, Verständlichkeit des Status, Abbrüche und Nutzerkommentar. Keine künstlichen universellen Erfolgsraten vorgeben; akzeptable Ziele werden je Aufgabe vor dem Test vereinbart.

### Minimales HCD-Review-Template

- Flow / Zielaufgabe / Zielgruppe / Nutzungskontext:
- Aktuelles Problem / Hypothese / erwartete Verbesserung:
- Designoption / bekannte Muster / Abweichungen:
- Kritische Zustände: Erfolg, Fehler, Offline, Undo, Unterbrechung, Accessibility:
- Evidenzklasse: **Heuristik/Code geprüft** | **Widget-/CI-Test** | **Owner-Gerätetest** | **unabhängiger Nutzertest**; niemals vermischen:
- Nutzeraufgabe, Testgerät/-modus und Beobachtungen (Erfolg, Irrtum, Zögern, Rückfragen, Hilfe):
- Findings und Schweregrad / konkrete Korrektur:
- Entscheidung: **READY** oder **HCD-OPEN**; verbleibende Risiken und Owner-Entscheidungen:

## 5. Drei verbindliche Ende-zu-Ende-Nutzerreisen für Store-v1

Diese **drei Kernreisen** müssen vor der öffentlichen Store-v1-Produktabnahme durch echte, dokumentierte Aufgabentests betrachtet werden, nicht allein durch Screenshots und automatisierte Tests:

1. **Törn erstellen und Proviant planen:** Boots-/Crewkontext, Produkt finden, Gebinde/Menge, in Liste übernehmen, Review-Hinweis verstehen; falsche Restauranttag-Annahme darf keine erfundene Tagesplanung erzeugen.
2. **Einkaufen und mit Crew teilen:** einkaufen/abhaken/Undo, stoppspezifische Mengen, Guest-Paket per QR/Link, kein Internet und nachfolgendes Owner-Reconcile. Guest Shopping ist derzeit **noch nicht implementiert**; Testpfad bleibt bis Implementierung OPEN.
3. **Bordkasse und Törnabschluss:** Ausgabe/Einzahlung mit richtigen Zahlern und Währungen, Beleg, nachvollziehbare Nettosalden, Abrechnung/Share; auch Korrektur einer falschen Eingabe testen.

Repräsentative Aufgaben **ohne Vorführung** ausführen lassen. Beobachtung, Hilfestellung und technische Fehler getrennt protokollieren. Relevante personenbezogene/finanzielle Daten durch synthetische Beispieldaten ersetzen, Einwilligung beachten; keine unnötige Aufnahme von Nutzeridentitäten.

Die **öffentliche v1-HCD-Abnahme dieser Kernreisen bleibt OPEN**, bis belastbare echte Beobachtungen vorliegen oder der Owner ein konkretes, dokumentiertes Restrisiko ausdrücklich akzeptiert. Ein interner Owner-Smoketest ist wertvoll, aber **kein Ersatz für unabhängige Unfamiliar-User-Tests**.

## 6. Zusammenhang mit bestehenden verbindlichen Entscheidungen

Dieses Prinzip **ergänzt**, aber ersetzt nicht:

- `docs/design/PROVY_UX_DIRECTION_v0.5.md` – mentale Modelle, Low Friction, Offline, vierstufige Informationsarchitektur und ruhige Motion;
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md` und `docs/design/PROVY_UX_WIREFRAMES_v0.2.md` – **eingefrorene Owner-IA/Interaktionsentscheidungen**;
- `docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md` – verpflichtender Benchmark-Pass vor UX-D;
- `docs/ENGINEERING_STANDARD_v1.0.md`, `AGENTS.md`, `GEMINI.md` – Architektur-, CI-, Security-/Daten- und Owner-Acceptance-Gates;
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md` – der Skipper baut die Liste.

**Konfliktregel:** Ergibt HCD-Evidenz, dass eine eingefrorene IA/Interaktion verändert werden sollte, wird die Abweichung mit Szenario und Beobachtung als **Owner-Entscheidungsvorschlag** vorgelegt. Niemand ändert die eingefrorene IA, fachliche Invarianten, Backend-Gates oder Feature-Scope stillschweigend. HCD gibt keinen neuen Implementierungs-Slice frei und erlaubt keinen automatischen Merge.

## 7. Konkreter aktueller Einstieg

- **Flight Strip #56 / Pixel QA #61:** Zwei Fragen getrennt nachweisen: (a) technisch korrekte und persistente Basket-Mutation; (b) für Nutzer verständliche, flackerfreie Rückmeldung, auch bei fehlerhaftem Swipe, doppeltem Tap und Undo. Kein reales UX-PASS allein aus grünem CI.
- **PROVY Welcome #62:** Kann ein Erstnutzer anschließend ohne Erklärung einen Törn anlegen? Hat das Intro klare Marken-/Produktinformation, keinen zusätzlichen Zwang bei Routine-Starts und eine nutzbare Reduced-Motion-Alternative?
- **UX-D #21:** Vor Implementierung für jede wichtige Surface Benchmark- plus HCD-Pass dokumentieren.
- **Backend/Guest/Bordkasse:** Verständnis von Auth-/Offline-/Backup-Status, Freigabeumfang, tatsächlichem Speichererfolg und finalen Kosten ist genauso HCD wie Layout und Motion.

## 8. Referenzen (Methoden, keine unkritische Normübernahme)

- Nielsen Norman Group – [10 Usability Heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) (letzte Prüfung 2024): Statussichtbarkeit, Nutzerkontrolle, Fehlervermeidung, Recognition statt Recall.
- Nielsen Norman Group – [When to Use Which UX Research Methods](https://www.nngroup.com/articles/which-ux-research-methods/): formative und summative Tests, Verhalten vs. Einstellungen.
- Nielsen Norman Group – [UX Research Cheat Sheet](https://www.nngroup.com/articles/ux-research-cheat-sheet/): reale qualitative Aufgabenbeobachtung.
- ISO 9241-210:2019 – Human-centred design for interactive systems (normative Bezugsidee; Normtext nicht übernommen).

**Kernaussage:** Für PROVY zählen nicht allein Features, Schönheit oder grüne Tests. Entscheidend ist, ob Menschen unter realen Bedingungen ihre Bordaufgaben verständlich, schnell, verlässlich und ohne unnötige Anstrengung erledigen.
