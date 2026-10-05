# FIX-A Independent Review – 05.10.2026

Reviewed HEAD: `704ac83df04e7305033545af9072fa9a04d99e96`

Status: **AMENDMENT REQUIRED – FIX-A noch nicht owner-accepted**

## Zusammenfassung

Der Slice behebt die zentralen Routing-/Lifecycle-Regressionen tatsächlich und ist deutlich besser als der vorherige Stand. Die Behauptung „keine offenen Risiken“ ist jedoch zu stark.

### Positiv verifiziert
- #11: Einlagerungsabschluss setzt `underway` und navigiert explizit zur Törnübersicht.
- #12: vollständige Bordkasse und Timeline sind wieder sichtbar erreichbar.
- #13: `TripPhase` wird wieder verwendet; bloße Existenz aller berechneten ListItems gilt nicht mehr als fertige Nutzerliste.
- #14: „später“ und „streichen“ führen nicht mehr denselben Codepfad aus.
- #18: Detailnavigation wurde weitgehend auf `push` + sicheren Back-Fallback vereinheitlicht.
- #19: dedizierte FIX-A-Journey-Tests wurden hinzugefügt.

## Finding A – #16 nicht vollständig behoben

Der ursprüngliche Befund war nicht auf zwei Settings-Zeilen beschränkt. Im aktuellen `main` existieren weiterhin sichtbare deutsche Hardcodes, u. a. in:
- `TripOverviewScreen`
- `MoreScreen`

Beispiele im aktuellen Code:
- „Kühl- & Wasserkapazitäten“
- „Mindestens eine Person muss an Bord bleiben.“
- mehrere MoreScreen-Texte/Fehlertexte/Tooltips

Damit ist die Aussage „Issue #16 erfüllt“ nicht haltbar.

### Amendment
- sichtbare produktive Strings der von FIX-A berührten Hauptscreens vollständig über ARB lokalisieren
- mindestens EN auf echten Screens testen, nicht nur einzelne `l10n.*`-Strings künstlich rendern

## Finding B – #15 / Trip-Edit unvollständig

Der FIX-A-Prompt verlangte als aktuelle v1-relevante Editierdaten ausdrücklich auch:
- Restauranttage/-zähler

`TripService` besitzt `setRestaurantCounts()`, der neue Edit-Sheet bietet diese Werte jedoch nicht an.

### Amendment
- Restaurant-Mittag-/Abend-Zähler in den Edit-Flow integrieren
- Persistenz + Recalculation testen

## Finding C – #17 nur teilweise gelöst

Die früheren No-op-Zeilen:
- Sprache
- Gemerkte Packungsgrößen

öffnen nun Informationsdialoge.

Das ist besser als `onTap: () {}`, aber noch keine echte Einstellung. Besonders „Sprache“ darf nicht wie eine auswählbare Einstellung wirken, wenn nur erklärt wird, dass die Gerätesprache gilt.

### Amendment
Eine klare UX wählen:
- echte Funktion implementieren **oder**
- als reine Information ohne Settings-/Chevron-Affordance darstellen **oder**
- vorerst aus der sichtbaren UI entfernen.

Keine Pseudo-Einstellung.

## Finding D – „Später“ erzeugt keinen expliziten Nutzerentscheid über den Zielstopp

Der Code unterscheidet „später“ und „streichen“ nun fachlich. Das ist ein echter Fortschritt.

Die ursprüngliche Erwartung war jedoch: Bei „später“ soll ein vorhandener späterer Stopp gewählt bzw. ein neuer bewusst angelegt werden können. Automatisches Erzeugen eines Folgestopps ohne explizite Zielwahl ist als Low-Friction-Fallback denkbar, muss aber UX-seitig bewusst entschieden werden.

### Amendment
Für FIX-A reicht:
- Verhalten transparent machen und testen
- kein stilles unerklärliches Erzeugen eines Stopps

Die endgültige Interaktion kann im neuen UX-Konzept weiter verfeinert werden.

## Finding E – Journey-Tests dürfen nicht nur Servicezustände prüfen

Der Bericht nennt die Tests „End-to-End-Journey“. Vor Owner-Abnahme muss sichergestellt sein, dass die kritischen Pfade tatsächlich über Router/UI-Aktionen durchlaufen werden und nicht nur Screen + Service separat testen.

### Amendment
Mindestens die Kernpfade über echte Taps/Navigation verifizieren:
- Overview → Bordkasse → zurück
- Overview → Liste → zurück
- Einkauf → Einlagerung → Abschluss → Overview
- Trip Edit → Restaurantwerte ändern → speichern

## Abnahme nach Amendment

FIX-A kann owner-accepted werden, wenn:
- Findings A–C geschlossen sind
- D transparent/sicher gelöst ist
- E durch Tests belegt ist
- `flutter analyze` sauber
- vollständige `flutter test` Suite grün
- Bericht als Amendment ergänzt wird

PIVOT1 bleibt bis zur FIX-A-Abnahme gestoppt.
