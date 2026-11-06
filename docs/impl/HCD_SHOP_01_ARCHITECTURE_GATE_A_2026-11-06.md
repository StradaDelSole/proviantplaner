# PROVY – HCD-SHOP-01: Architecture Gate A – Review Amendment v0.2

**Datum:** 06.11.2026 · **Status: CHANGES ADDRESSED IN DOCUMENT / INDEPENDENT RE-REVIEW OPEN; NO CODE / NO MERGE**  
**Owner-genehmigt:** HCD-Produktziel und Reihenfolge, **nicht** diese neuen Detailentscheidungen oder Phase-B-Coding.  
**Issue:** #66 (Parent #64) · **Claude Independent Gate A v0.1:** `PROVY_HCD_SHOP_01_GATE_A_REVIEW_v0.1.md` (06.11.2026), **CHANGES REQUIRED**, Findings F-01 bis F-10.  
**Review-Baseline:** `main e00c01d35763790fe430a8c331436e120478f2dd`; ungemergter PR #60 `af34fd9a88c3c7a4cf0e281ec187da2e5a39b855`. Bei jedem Gate erneut den aktuellen GitHub-HEAD abgleichen. Die vorhandene UX-IA bleibt eingefroren; hier keine App-/DB-/Backend-Änderung.

## 1. Explizite Designentscheidungsvorlage – S1

**Vorgeschlagen, Owner-Entscheidung noch OFFEN:** **S1, natürliches Nachrücken**. Beim Abhaken verschwindet nach bestätigtem Speichern die gekaufte Zeile aus „Offen“. Das nächste offene Produkt rückt **an die Bildschirmposition der eben abgehakten Zeile**, damit einhändiges Einkaufen mit wiederholtem Tap an derselben Stelle möglich ist. Das ist **nicht** S2 („Nachbarartikel behält seinen bisherigen Y-Wert“).

- Keine aktive Scroll-Anker-/Offsetkorrektur, kein `jumpTo`, `animateTo`, `correctBy`, Custom Sliver oder nachträglicher Frame-Hack. Stabile List-Element-Identität und ein **stabiler Scrollable** während Riverpod-Rebuilds.
- Wenn der **letzte offene Artikel einer Abteilung** verschwindet, darf die Abteilungsüberschrift ebenfalls verschwinden. Oberhalb der gekauften Zeile unverändert sichtbare Positionen bleiben, sofern nicht durch ScrollExtent-Klemmung begrenzt.
- **Am Listenende** darf Flutter den Offset an `maxScrollExtent` klemmen und dadurch Inhalte sichtbar verschieben. Das ist keine programmatische Rückkehr nach oben, sondern geometrisch unvermeidbar; ausdrücklich testen, dass kein Sprung zum Screenanfang erfolgt, der Scrollable erhalten bleibt und die nächste erreichbare Handlung sichtbar ist.
- Eine kurze Item-Exit-Animation ist **nicht** Teil dieses Slices; nur als separater, evidenzbasierter Follow-up nach Pixel-Test, mit Reduced-Motion-Alternative.
- Wenn simultane Änderungen oberhalb des Viewports/außerhalb des sichtbaren Bereichs zu einem neuen Problem führen, als **separates beobachtetes Finding** erfassen; kein spekulativer Anker-Mechanismus in diesem PR.

**Gate A:** Owner bestätigt S1 separat vor Phase B. Keine Gleichsetzung der früheren Zustimmung zum allgemeinen HCD-Plan mit dieser spezifischen Auswahl.

## 2. Verifizierte aktuelle Ursachenhypothesen und Testreihenfolge – F-03

`lib/features/shopping_list/ui/shopping_mode_screen.dart`, main und PR #60 Stand:

1. `ref.watch(tripShoppingListProvider(widget.tripId))` und `dataAsync.when(loading: Scaffold(CircularProgressIndicator), error: NotFoundScreen, data: Scaffold)` können auf `tripDataVersionProvider`-Reload den gesamten Einkaufs-Screen ersetzen. `shopping_list_screen.dart` wurde in PR #60 mit `skipLoadingOnReload: true`/ `skipLoadingOnRefresh: true` gehärtet, **ShoppingModeScreen nicht**. Ob die konkrete Riverpod-2.x-Reload-Kette die Liste bei jeder Änderung tatsächlich ausbaut, muss ein **Fails-before-Test** zeigen, nicht vermutet werden.
2. `ListView(children: data.departments.map(...))` mit `deptItems.sort(... isBought ...)` verschiebt gekaufte Elemente innerhalb jeder Abteilung nach unten; erledigte Zeilen bleiben im aktiven Arbeitsbereich sichtbar. Das ist ein unabhängiger HCD-Fehler und potenzieller geometrischer Shift.
3. `Checkbox.onChanged` ruft `service.toggleBought()`, dann `ref.invalidate(tripShoppingListProvider)`. `shoppingListServiceProvider.onTripDataChanged` erhöht bereits `tripDataVersionProvider`; die zweite explizite Invalidierung ist redundant und wird **nur an dieser Checkbox-Callsite** entfernt.
4. `onChanged` ignoriert das `bool`-Resultat und behandelt Exceptions nicht; nach `await` fehlt zudem ein zuverlässiger `mounted`-Guard.

**Schritt 0: Red-first auf unverändertem main.** Deterministische Testfixture mit 40+ unabhängigen Artikeln in drei Supermarktabteilungen (direkt In-Memory-DB, nicht von Mengenberechnung/Katalogvorschlag abhängig) und realistischem 412×915-dp-Screen. Nach Toggle mit absichtlich verzögertem DB/Provider-Reload **Frame für Frame** beobachten: erschien ein Vollbild-Spinner? Wurde die `ListView`/Scrollable-Identität verworfen? Wie verändern sich tatsächlicher Scrolloffset und sichtbare Reihenpositionen? Tests/Behauptungen **nur** als „ROT am main“ berichten, wenn sie wirklich fehlschlagen; wenn der Spinner nicht reproduzierbar ist, Hypothese korrigieren, bevor UI neu gebaut wird. Anschließend derselbe Test „GRÜN nach Fix“. Vorherige sichere Provider-/DAO-Verträge nicht umgestalten, um einen Test künstlich rot zu machen.

## 3. Phase-B-Zuschnitt – zwei intern getrennte Schritte unter #66 (Owner-Freigabe offen)

### Schritt 1 – stabile Darstellung und ehrlicher Kaufstatus

**Produktionsdatei vorzugsweise nur `shopping_mode_screen.dart`:**

- `dataAsync.when(skipLoadingOnReload: true, skipLoadingOnRefresh: true, ...)` mit **drei** getrennten Fehlerfällen:
  1. erstmaliger Load-Fehler ohne valides Data → verständlicher Fehlerzustand, Retry, *nicht* pauschal „Törn nicht gefunden“;
  2. Reload-Fehler **bei vorhandenen validen Daten** → alte nutzbare Liste belassen, sichtbaren Fehler-/Retry-Hinweis; niemals still so tun, als wären aktuelle Daten gespeichert;
  3. erfolgreicher Load, aber `stopId` nicht gefunden → vorhandene `shoppingStopNotFound`-Meldung.
- **Riverpod-`when`-Fallstrick:** `skipLoadingOnReload/Refresh` verhindert nur die Ladeansicht. `skipError` ist standardmäßig `false`; ein `AsyncError` mit `hasValue == true` kann trotzdem den `error`-Branch und damit den kompletten Listenabbau auslösen. Der Coding-Agent soll am **gepinnten Riverpod-2.x-Code** verifizieren, wie `hasValue`, `hasError`, `skipError` und `when` hier interagieren. Alte Daten dürfen bei einem Reload-Fehler nur **mit sichtbarem Warnhinweis und Retry** erhalten bleiben – `skipError: true` allein, ohne Fehleranzeige, reicht nicht. Einen initialen Fehler ohne altes Data separat behandeln.
- Redundantes manuelles `ref.invalidate` **nur** nach `toggleBought` entfernen. Die vorhandene `onTripDataChanged`-Benachrichtigung unverändert lassen.
- Pro Artikel/Stop lokaler Pending-Guard; derselbe Haken und dessen Undo-Pendant während derselben Operation nicht erneut aktiv. Aufeinanderfolgende idempotente `isBought=true/false`-Werte und FIFO des StorageOperationCoordinator respektieren; keine neue Engine-Queue.
- `await toggleBought` bool: `true` ist positive Bestätigung; `false` führt zu sichtbarer Fehlermeldung/Retry, keine „erfolgreich gespeichert“-Behauptung. **Exception** (Recovery-Gate, SQLite, Gerät) als primärer realistischer Fehlerfall ebenfalls auffangen. Bei Fehlern den DB-Wahrheitszustand durch den bestehenden Reload lesen; nicht blind eine optimistische Zeile finalisieren. Fehlermeldungen dürfen berechtigte Recovery-Sperren nicht aushebeln.
- Vor `ref`, `setState`, `ScaffoldMessenger` und Navigation nach `await` den Widget-Lebenszyklus berücksichtigen. Keine UI-Aktion nach `dispose`.

**Kein Service-/DAO-/Provider-Change.** Insbesondere **nicht** die Notification von `toggleBought` auf „nur bei result==true“ umstellen. Sie ist für die Rückkehr zur tatsächlichen DB-Sicht nach einer Fehl-/False-Operation erforderlich. Der vermeintliche Korrekturvorschlag aus der vorigen v0.1-Version wird **zurückgezogen (F-02)**.

**Zwischengate:** rote/grüne Reload-/Offset-Tests + ein kurzer Pixel-Zwischentest. Zeigt Schritt 1 bereits ein vollständig stabiles Abhaken, bleibt Schritt 2 eine gesondert überprüfbare UX-Verbesserung, nicht ein behaupteter technischer Fix derselben Ursache.

### Schritt 2 – eingeklapptes „Erledigt (N)“ und natürliche Reihenfolge

**Vorgeschlagen, nur nach Owner-S1-Freigabe:** reine, seiteneffektfreie Zeilenmodell-Funktion `buildShoppingModeRows(data, stopId, {expandedCompleted})`, die deterministische Zeilentypen ausgibt: `DepartmentHeader | OpenItem | CompletedHeader(N) | CompletedItem`.

- **Eine** `ListView.builder` (keine verschachtelten Scroller, keine selbstgebauten Slivers), mit `ValueKey` für stabile Zeilenidentität und `findChildIndexCallback`, falls für Kinder-Reorder erforderlich; intern nach bestehender Department-/Katalogreihenfolge.
- Gezeigt werden **offene** Items nach Abteilung, nur nichtleere Abteilungsüberschriften; danach **Erledigt (N)** standardmäßig eingeklappt und per Tap expandierbar. Gekaufte Items erscheinen nur im Footer, nicht erneut in den offenen Abteilungen.
- AppBar-Fortschritt und Footer-Zähler verwenden exakt dieselbe per-Stop-Fachmenge: `isOnList`, `packagesAtStop(...) > 0`, `isBoughtAtStop(stopId)`. `Offen + Erledigt = Gesamt` für jeden Stopp. Kein doppeltes Zählen und keine Änderung der Zuweisungen.
- Undo eines gekauften Artikels im Footer geht über denselben existierenden persistierten `toggleBought(false)`-Pfad; nach Erfolg kehrt er an die korrekte Stelle der offenen Gruppe zurück. Selber Pending-/Fehler-Guard.
- S1 heißt: beim Abhaken einer **sichtbaren** offenen Zeile bleibt der Scrolloffset ohne programmatischen Eingriff stabil; das Nachfolgeprodukt rückt nach. Kein Versprechen, dass jedes Nachbarprodukt die alte Y-Position beibehält.
- Bereits offene/gekaufte Items werden nicht still gelöscht; die Darstellung ist eine **View-Transformation**, keine Mutation. Alle sechs Locale-Einträge für „Erledigt (N)“, Speichern, Fehler, Retry und Undo müssen semantisch korrekt sein; keine Bordkassen-Keys recyceln.
- Schutz für 320dp, 1,5× Text, Light/Dark/Nightwatch, Screenreader und Reduced Motion. 44–48dp Touch Targets; keine neue dekorative Motion.

**Keine Drift-Migration, keinerlei Änderungen an `isBought`/Stop-Zuordnungen, App-Router, Backend, Auth0, Mengenengine, `handleUnboughtItems` oder globalem `TripPhase`.**

## 4. Invarianten und Fehler-Matrix

| ID | Unveränderlich / geforderter Effekt | Test |
| --- | --- | --- |
| I1 | Stop A und B bleiben bei gleicher Ware kaufstatus- und mengenmäßig unabhängig | In-Memory-DAO mit zwei Stopps |
| I2 | `packagesAtStop`, Restmenge des ersten Stopps und `effectivePackages` bleiben konstant | Vor/Nach-Zustand prüfen |
| I3 | Häkchen/Erledigt-Zähler sind bei fehlgeschlagener Persistenz nicht als Erfolg markiert | Deferred write + Exception/False/Retry |
| I4 | Nach fünf Checkmarks in Listenmitte kein Full-Scaffold-Reload und kein Scroll-Reset; S1-geometrisches Nachrücken | Frame-by-frame + Position + Pixel |
| I5 | Gekaufte Items einmalig im „Erledigt“-Footer, jederzeit expandierbar/Undo | Zeilenmodell + Widget |
| I6 | Same-item Pending/Undo schützt doppelte Befehle, andere Items können ohne UI-Desync bedient werden | Completer barriers / dispose |
| I7 | Alle Kernmutationen bleiben offline nutzbar; echtes Recovery-/DB-Versagen meldet Fehler | Recovery-blocked fixture |
| I8 | Keine Änderungen an Checkout, storage flow, #60 Flight Strip, Ledger, Backup | unveränderte Regression |
| I9 | Header und große Textgrößen verändern nicht ungewollt programmatisch den Offset; **Scroll-Klemmung am Ende ist zugelassen** | Mid-scroll + near-end Layout |
| I10 | Error with value ≠ initial failure ≠ missing stop | drei Tests / Retry |

**Bestehende Risiken außerhalb #66:** (a) DAO-Fallback `remaining>0 ? remaining : 1` wird über reguläre `ShoppingModeScreen`-Filter nicht erreicht; keine hier veranlasste DAO-Korrektur; (b) keine DB-`UNIQUE(list_item_id, shopping_stop_id)`, derzeit FIFO; später separate Architekturprüfung bei Bedarf; (c) bereits „gekauft“ bei nachträglicher Packungszahlerhöhung bleibt gekauft – in **#67** als Fachproblem aufnehmen; (d) volle FutureProvider-Neuberechnung kann Latenz verursachen; auf Pixel messen, vorerst kein Caching-Umbau.

## 5. Präzise Tests und Abnahme

**Fail-before / pass-after Pflicht.** Falls ein Test auf altem `main` nicht rot läuft, unbewiesene Hypothese in Gate A zurückmelden statt grünen Test als „Regression behoben“ auszugeben.

- **S01-BASE-RED:** deterministische 40+-Fixture direkt in In-Memory-DB, drei Departments, 412×915dp, mittige offene Position, Toggle/Provider-Reload; pro Frame den Bereich und Offset erfassen, vor Fix erwartet tatsächlich beobachtetes Full-Screen-Loading/Viewport-Verlust, danach kein Full-Screen-Replacement.
- **S01-SCROLL-S1:** fünf nacheinander sichtbare Items kaufen; nach jeder Bestätigung bleibt Scrollable als Objekt/Element erhalten, **kein** durch App ausgelöster `jumpTo`/`animateTo`/`correctBy`; das Folgeitem rückt an die Stelle der gekauften Zeile, soweit nicht Header-Removal oder `maxScrollExtent`-Clamping eine begründete Abweichung bewirken. Test nicht nur `findsOneWidget`; mit realen Widget-RenderBox-Positionen, Scrollposition und Frame-by-frame `pump(Duration)` prüfen.
- **S01-END:** nahe Listenende mehrere Items abhaken; unvermeidbare Offset-Klemmung erlaubt, aber keine Rückkehr an den Listenanfang oder ungerechtfertigter automatischer Scrollbefehl. Sichtbare nächste Aktion bleibt zugänglich.
- **S01-HEADER:** letzte offene Zeile einer Abteilung → Header verschwindet, keine zusätzliche programmatische Scrollkorrektur.
- **S01-ERROR:** zunächst valider Zustand, then Reload-Exception => alte Liste bleibt + Retry; initial exception => separate Retry-Seite; loaded stop missing => gezielter NotFound; DB write throws/returns false => truthful error + no purchased count.
- **S01-RIVERPOD-FLAGS:** `AsyncValue.when` im pinned 2.x: `isReloading` mit Data → vorherige Liste; `AsyncError(hasValue:true)` nach fehlgeschlagenem Reload → vorherige Liste **plus** sichtbar Warnung und Retry; `AsyncError(hasValue:false)` → Fehlerseite. Tests müssen prüfen, dass `skipError:true` nicht bloß Fehler unsichtbar macht.
- **S01-CONCURRENCY:** zwei schnelle Taps auf selben Item; parallel verschiedene Items; Undo im Erledigt-Footer; Widget dispose während Future; keine setState/ref-after-dispose.
- **S01-STOP:** gleicher Artikel in zwei Stops, Packungen exakt bilanziert, counts und Einkauf-Status nur im jeweiligen Stop.
- **S01-A11Y:** Pixel-7-Pro 412×915dp + 320dp, 1,5× Text, Reduced Motion, alle drei Themes, sechs Locale; no overflow.
- **S01-RESTART:** Screen unmount/remount mit **demselben DB-Objekt, neuem ProviderContainer**, Status bleibt korrekt. Physischer App-Kill/Relaunch auf Pixel separat.
- **Regression:** `test/features/ux/ux_b_shopping_and_delivery_test.dart`, `shopping_list_persistence_test.dart`, `pivot1_assisted_list_test.dart`, `fix_a_journey_test.dart`, PR #60 F1–F6, Backend CI. Keine Schwächung bestehender Tests.
- **Evidenz getrennt:** Code/Architektur C1 | Unit/Widget C2 | Owner Pixel C3 | unabhängiger Skipper C4 | Stage C5. Keine C3/C4-Claims vor tatsächlichem Test.

**Keine rigide universelle Y-Toleranz** bei Header-Removal, variabler Textskalierung und Listenend-Klemmung: geometrische Annahmen anhand klarer Vorbedingungen und Gegenbeispiele prüfen. Instrumentation für programmeigene Offset-Befehle und tatsächlich gerenderte Geometrie; weder `pumpAndSettle` allein noch „Widget existiert“ als Erfolgstest.

## 6. Branch-/Merge-Strategie und offene Entscheidungen

- **Empfohlener Coding-Branch:** `slice/hcd-shop-01-stable-checkout` von live `main`, damit der ungemergte PR #60 und Docs PR #63 nicht ungeprüft hineingeraten.
- **Merge-Reihenfolge OFFEN**: #60 betrifft dieselben 6 `lib/l10n/app_*.arb`-Dateien. Bevor Phase B startet, Owner-Plan für Sequenz festhalten: voraussichtlich #66 isoliert code-reviewed und physisch getestet, danach bewusst geplante PR-Integration/Rebase von #60; vor jedem Merge einen aktuellen ARB-Key-/Semantik-Diff und komplettes CI. Kein Merge nur zur Konfliktvermeidung.
- **Zwei interne Schritte** werden in #66 separat gemessen; Pixel-Zwischentest nach Schritt 1 (wenn verfügbar). Über die Reihenfolge und den kleinen zusätzlichen Testaufwand entscheidet der Owner im Gate.
- **Noch OFFEN:** Owner bestätigt S1 (statt S2), Schritt-1-/Schritt-2-Teilung + Pixel-Zwischentest, und Merge-Reihenfolge gegenüber PR #60. Frühere allgemeine HCD-Zustimmung ist dafür nicht stillschweigend ausreichend.

## 7. Independent Gate A – Änderungsprotokoll v0.1 → v0.2

| Review-Finding | Amendment |
| --- | --- |
| **F-01 HIGH** | S1 eindeutig spezifiziert; kein aktiver Anchor/Offset-Mechanismus; End-of-list-Clamping und Header-Removal testbar; Owner-Wahl OFFEN |
| **F-02 HIGH** | Service-„notify only if true“-Vorschlag **verworfen**; Service/DAO/Provider unverändert, bool/exception nur in UI ehrlich behandeln |
| **F-03 HIGH** | **Fails-before** auf original main als zwingender Schritt 0, keine implizite Behebung behaupten; zuerst Reload/Spinner-Ursache isolieren |
| **F-04 MEDIUM** | Frame-by-frame + Offset-/Geometry-Instrumentierung, 40+ DB-fixture, 412×915/320dp, false/throw und echter remount |
| **F-05 MEDIUM** | isBought-Werte idempotent und FIFO anerkannt; Exception-/Recovery-Gate-Pfad primär, false nur Vertragstest |
| **F-06 MEDIUM** | Error-with-data, initial error und missing-stop explizit getrennt |
| **F-07 MEDIUM** | Zwei interne Schritte; reine Zeilenmodell-Funktion + `ListView.builder`, kein komplexer Sliver |
| **F-08 LOW** | ARB-Konflikt-Risiko #60 und offene Merge-Reihenfolge genannt |
| **F-09 LOW** | DAO-Fallback/fehlender Unique-Constraint und spätere Packungszahlerhöhung als Restrisiken; letzteres #67 |
| **F-10 LOW** | Source-Zeilen werden vor Phase B live verifiziert; keine alten Fixanweisungen für Service übernehmen |

**Gate A bleibt CHANGES REQUIRED / REVIEW OPEN, bis ein unabhängiger enger Re-Review diesen geänderten Entwurf tatsächlich akzeptiert. Phase B NICHT freigegeben. Keine Produktcodeänderung, kein CI-/Pixel-PASS behauptet.**
