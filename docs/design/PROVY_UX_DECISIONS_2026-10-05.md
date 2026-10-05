# Provy UX Decision Set — 05.10.2026

Status: **OWNER-ACCEPTED / verbindlich**

Grundlage: Questionnaire mit 40 offenen UX-/Produktentscheidungen. Alle Antworten wurden durch den Product Owner bestätigt.

## A. Home / Einstieg

1. **Situation zuerst** — laufend: `Tag X von Y`; davor: `In X Tagen`; danach: Abschlussstatus. Törnidentität und CTA folgen.
2. **Neuer Törn als sichtbares +**, `Alle Törns` als sekundärer Link.
3. Tap auf Törnkarte öffnet **Törnübersicht**; separater CTA öffnet die aktuelle Next Action.

## B. Command Center

4. Feste Anordnung:
   - oben links **Vorräte**
   - oben rechts **Einkaufen**
   - unten links **Crew & Boot**
   - unten rechts **Bordkasse**
5. Vier Kacheln bleiben **gleich groß**.
6. Jede Kachel zeigt Name/Icon plus **maximal 1–2 entscheidungsrelevante Statuswerte**.

## C. Next Action

7. Next Action basiert auf **Lifecycle + tatsächlichem Datenzustand**.
8. Bei konkurrierenden Aktionen: **eine Hauptaktion + maximal eine kleine sekundäre Aktion**.
9. Next Action ist eine Empfehlung und darf grundsätzlich **ignoriert** werden; nur echte fachliche/technische Unmöglichkeiten blockieren.

## D. Törn-Header

10. Tap auf Törnidentität öffnet direkt **Törn bearbeiten**.
11. Sichtbar: **Törnname/Revier + Bootsname + Crew + Dauer**; Datum dezent ergänzen. Bootstyp/Modell sekundär.

## E. Vorräte / PIVOT1

12. Produktsuche: großer Search-First Empty State; bei bestehender Liste kompakter/sticky schneller Zugang.
13. Variante → Packung → Anzahl in einem **kompakten Bottom Sheet**, keine zusätzliche Navigationsseite.
14. Packungsgrößen als **horizontale Chips**.
15. Anzahl: **− / Zahl / +**; Tap auf Zahl öffnet Pickwheel/Direkteingabe.
16. Vorratsliste standardmäßig **nach Supermarkt-Abteilung**; Kategorie bleibt sekundäre Sicht.

## F. Hinweise / Readiness

17. Hinweise erscheinen **kontextuell am Artikel** plus kompakte Gesamtsicht.
18. `Bereit / Noch prüfen / Aktion nötig` innerhalb des Bereichs und situativ in Next Action, nicht als dominanter globaler Score.
19. Provy macht Vorschläge **nur bei hoher Relevanz**; schwächere Hinweise unter ruhigem `Vielleicht noch prüfen`.

## G. Einkaufen

20. Einstieg in `Einkaufen`: **Liste aller Einkaufsstopps mit Status**, relevanter Stopp prominent oben.
21. Tap auf Stopp öffnet **Stop-Detail**; `Einkauf starten` als klarer eigener CTA. Direkter Start darf zusätzlich über Next Action erfolgen.

## H. Guest Shopping

22. `Einkauf aufteilen`: Provy schlägt standardmäßig **Abteilungsgruppen** vor; Einzelanpassung bleibt möglich.
23. Helfername ist **optional**.
24. Nach `Teilen`: **QR zuerst groß**, darunter `Link teilen` und `Offline teilen`.
25. Provy wählt **online/offline automatisch** nach Verbindung und erklärt den Zustand klar. Manuelles Umschalten bleibt unter weiteren Optionen möglich.
26. **Offline-Rückgabe-QR ist nicht GUEST1-v1-Pflicht.** Statischer Offline-Share + Owner-Reconcile reicht für v1; Rückgabe-QR kann danach folgen.

## I. Crew & Boot

27. Ein Screen mit **zwei klar getrennten Sektionen**, keine Tabs.
28. **Boot zuerst**, danach Crew.

## J. Bordkasse

29. Primäransicht: **aktueller Kassenstand + große Aktionen `Einzahlen` / `Ausgabe`**.
30. Abrechnung wird gegen Törnende prominent; davor bleibt sie sekundär erreichbar.

## K. Quick Actions

31. Während eines laufenden Törns **kontextabhängiger Floating Button**, z. B. unterwegs `+ Ausgabe`.
32. **Kein Long-Press als notwendiger Funktionspfad.** Alle Funktionen bleiben sichtbar auffindbar.

## L. Farbe / visuelles System

33. Grundästhetik: **helles, ruhiges Off-White mit Navy-Typografie und sparsamen maritimen Akzenten**.
    - Verbindliche Ergänzung des Product Owners: dieselbe Informationshierarchie und gute Lesbarkeit müssen auch in **Dark Mode** und insbesondere **Nightwatch/Rotlicht-Modus** erhalten bleiben.
    - Nightwatch ist keine bloße Farbinvertierung; Kontrast, Fokus, Statussemantik und Bedienbarkeit müssen für dunkle/rote Lichtbedingungen eigenständig geprüft werden.
34. Hauptbereiche erhalten **Icon + Akzentlinie + sehr leicht getönten Hintergrund**.
35. Statusfarben werden global standardisiert: **neutral / Hinweis / Aktion nötig / erledigt**. Farbe nie als einziges Signal.

## M. Motion / Haptics

36. Motion-Level: **deutlich fühlbar, aber funktional** — Press, Confirm, räumlich nachvollziehbare Transition, Value Roll.
37. Haptics: leichter Tick für mechanische Controls; stärkeres Confirm bei wichtigen Aktionen; Fehlerhaptic nur bei echten Fehlern.

## N. Neuer Törn

38. **Ein kompakter Screen** für Grunddaten, Boot und Crew; weitere Details danach.
39. Bekanntes/zuletzt verwendetes Boot wird **als bestätigbarer Default vorgeschlagen**, nie still übernommen.

## O. Freeze-Prozess

40. Diese Entscheidungen frieren Verhalten, Hierarchie und Interaktionsprinzipien ein. **Vor vollständigem UX-D-Freeze folgt noch genau eine konkrete Screen-by-Screen-Wireframe-Runde** für:
   - Home
   - Törnübersicht / Command Center
   - Vorräte
   - Einkaufen / Guest Shopping
   - Crew & Boot
   - Bordkasse

Danach wird das vollständige UX-Konzept finalisiert und UX-D implementierbar gemacht.

## Verbindliche Folge

Diese Entscheidungen dürfen in Implementierungsslices nicht eigenmächtig neu interpretiert werden. Ungeklärte visuelle Detailfragen werden in der Wireframe-Runde entschieden; bereits hier gefällte Entscheidungen werden nicht erneut geöffnet, außer der Product Owner ändert sie ausdrücklich.
