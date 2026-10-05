# Repo Regression Audit – 05.10.2026

Status: **OWNER-REQUESTED / verbindliche Grundlage für die nächste Reparaturrunde**

Basis: aktueller `main` nach Produkt-Pivot-Dokumentation (`d497536...`).

## Ziel

Repo-weite statische Prüfung der aktuellen produktiven Flutter-Flows nach dem ersten echten Gerätetest. Fokus:

- Erreichbarkeit
- Routing / Rückwege
- Törn-Lifecycle
- Liste / Einkauf / Einlagerung
- Bordkasse / Abrechnung
- Törn-Bearbeitung
- Settings
- Lokalisierung
- Testqualität

Keine Code-Fixes in diesem Audit. Findings werden als GitHub-Issues dokumentiert und danach in einem eigenen Reparatur-Slice umgesetzt.

## Bereits im Gerätetest gefundene Findings

- #4 Crewgröße kann nicht unter 5 reduziert werden
- #5 Watermaker fehlt
- #6 wiederverwendbare Bootsprofile fehlen
- #7 unplausible Roh-/Packungsmengen
- #8 Frischware/MHD als Gesamt-Törnmenge
- #9 Meal-frequency-Produkte als tägliche Staples
- #11 Einlagerungsabschluss führt zurück in den Listen-Editor

Produktreaktion:
- #10 / `PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`: Skipper baut die Liste, Provy assistiert.

## Neue Repo-Audit-Findings

### #12 – Bordkasse und Törnverlauf verwaist

Router und Screens existieren, aber der aktuelle UX-Hauptflow bietet keinen vollständigen Einstieg:
- `KittyScreen`
- `TripTimelineScreen`

Besonders relevant: Einkaufsstopp-CRUD steckt weiterhin in der Timeline und ist damit über den neuen Hub nicht sauber erreichbar.

### #13 – Workflow-State fehlerhaft

`TripPhase` existiert im Datenmodell, wird aber im Alltag nicht als Workflow-Wahrheit geführt.

`TripOverviewScreen` errät den nächsten Schritt aus Datum, Ausgaben und `_items.isNotEmpty`.

Problem: `createTripWithCrew() -> recalculateTrip()` legt bereits Katalogvarianten als ListItem-Datensätze an. Deshalb bedeutet `_items.isNotEmpty` nicht „Nutzerliste ist fertig“.

Einkauf und Einlagerung schreiben keinen klaren Lifecycle-Fortschritt.

### #14 – „Später“ und „Streichen“ tun dasselbe

Im Einkaufsabschluss führen beide Dialogaktionen lediglich zu `_promptStorage()`.

Keine der versprochenen Datenoperationen findet statt.

### #15 – Törn bearbeiten kann nur den Namen ändern

Der Edit-Button im zentralen Overview öffnet nur ein Namensfeld.

Crew, Dauer, Startdatum, Kühlung, Tank und andere Setup-Daten sind über den Hauptflow nicht vollständig editierbar.

### #16 – S9-Lokalisierungsregression

Trotz S9-Bericht „keine fest eingebauten Texte“ existieren weiterhin sichtbare deutsche Hardcodes, insbesondere in:
- TripOverviewScreen
- MoreScreen

Der S9-Test rendert ausgewählte Localizations künstlich statt echte Screens und konnte dies daher nicht erkennen.

### #17 – sichtbare No-op-Settings

In MoreScreen:
- „Gemerkte Packungsgrößen“ → `onTap: () {}`
- „Sprache“ → `onTap: () {}`
- Sprache hartkodiert „Deutsch“

Produktive UI darf keine funktionslosen Chevron-/Tap-Elemente enthalten.

### #18 – Inkonsistenter Routingvertrag

Hauptscreens werden teils mit `context.go()` geöffnet, Zielseiten versuchen jedoch mit `Navigator.pop()` zurückzugehen.

Betroffen u. a.:
- Overview → Liste
- Overview → Einkauf
- Overview → Abrechnung
- Einkauf → Einlagerung
- Einlagerung → Rückweg

Folge: Rückweg hängt vom zufälligen Stack ab statt vom Produktflow.

### #19 – Testlücke: keine echten Journeys

Tests prüfen häufig:
- Screen isoliert renderbar
- Buttontext vorhanden
- URL-Tiefe

Sie prüfen nicht:
- kann ein echter Nutzer vom Startscreen dorthin navigieren?
- funktioniert die Aktion?
- kommt er korrekt zurück?

Damit konnten #11–#18 trotz grüner Tests bestehen.

## Auditbewertung

Die Kern-Domainlogik ist nicht „weg“. Viele Funktionen sind weiterhin im Repo vorhanden. Der schwerwiegende Zustand liegt vor allem in der **Informationsarchitektur, Verdrahtung und Workflow-Orchestrierung** nach UX-A/UX-B und späteren Ergänzungen.

Das erklärt den Gerätetest:
- Funktionen existieren in Tests,
- sind aber im realen Pfad nicht oder falsch erreichbar.

## Reparaturreihenfolge

### FIX-A – Navigation & Lifecycle Regression Repair
Vor PIVOT1.

Muss mindestens schließen:
- #11
- #12
- #13
- #14
- #15
- #18
- #19

#16/#17 dürfen im selben Slice behoben werden, wenn Scope überschaubar bleibt; sonst direkt danach als FIX-B.

### PIVOT1 – Assisted List Core
Erst nachdem der zentrale Törnflow wieder zuverlässig navigierbar ist.

Warum:
Ein neuer Listen-Flow darf nicht auf einer kaputten Routing-/Lifecycle-Basis aufgebaut werden.

### Danach
- PIVOT2 Provisioning Review
- PIVOT3 Boat Profiles / Watermaker / Crew Fix
- CAT1 internationale Gebindevalidierung

## Definition of Done für FIX-A

Vom Startscreen auf echtem Routerpfad:

1. Törn öffnen.
2. Törn bearbeiten.
3. Liste öffnen und zurück.
4. Einkauf starten.
5. offene Position wirklich verschieben oder streichen.
6. Einlagerung abschließen.
7. zur Törnübersicht gelangen.
8. vollständige Bordkasse öffnen.
9. Abrechnung öffnen.
10. aus der Abrechnung korrekt zurück.
11. zweiten Einkaufsstopp anlegen/bearbeiten/löschen.

Alle Schritte durch mindestens einen Router-/Journey-Test abgesichert.

## Wichtig

Keine Rückkehr zur alten Bottom-Navigation.

Die Törn-Übersicht bleibt das zentrale Rückgrat. Der Fix soll vorhandene produktive Funktionen wieder sauber an dieses Rückgrat anbinden.
