# Provy UX Benchmark Strategy v0.1

Stand: 16.10.2026  
Status: **OWNER-ACCEPTED / verbindliche UX-Implementierungsstrategie**

Diese Strategie ergänzt:

- `docs/design/PROVY_UX_DIRECTION_v0.5.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`

Sie **ersetzt oder öffnet die eingefrorene Informationsarchitektur nicht erneut**.

Die bestehenden owner-accepted Entscheidungen zu Home, Törnübersicht, Command Grid, Vorräten, Einkaufen, Crew & Boot, Bordkasse, Guest Shopping, Navigation und Hierarchie bleiben verbindlich.

---

## 1. Grundsatz

Provy soll für bekannte Consumer-Interaktionen nicht aus Prinzip eine neue UX-Sprache erfinden.

Verbindlicher Grundsatz:

> **Bewährte Interaktionsmuster etablierter Consumer-Produkte werden bewusst als Benchmark verwendet und auf Provy übertragen, solange sie zu unserem Produktmodell und der bereits eingefrorenen Informationsarchitektur passen.**

Ziel:
- geringere Lernkurve;
- höhere Wiedererkennbarkeit;
- weniger UX-Experiment;
- weniger unnötige Eigenkonstruktionen;
- schnelleres Design und Implementieren;
- bessere Bedienbarkeit durch bekannte mentale Modelle.

Die Eigenständigkeit von Provy entsteht primär durch:
- Produktlogik;
- Inhalt;
- maritime Nutzungssituation;
- Offline-/Bordkontext;
- Marke;
- visuelles Designsystem;
- funktionale Qualität.

Nicht dadurch, bekannte Interaktionen absichtlich anders zu bauen.

---

## 2. Primäre UX-Benchmarks

### 2.1 Instacart – primärer Benchmark für Shopping-/Catalog-Surfaces

Instacart ist der primäre Referenzrahmen für:

- Produktsuche;
- Suchergebnisse;
- Produkt-/Artikelzeilen;
- Produktkarten, wenn Karten sinnvoll sind;
- Mengensteuerung;
- Packungs-/Variantenwahl;
- Kategorien / Departments;
- Einkaufslisten;
- In-Store-/Shopping-Mode;
- Verfügbarkeit;
- Händler-/Provider-Kontext;
- Ersatz / Alternative;
- Liste vs. tatsächliches Anbieterangebot.

Besonders relevant für Provy:

> **Planungsbedarf und reales Anbieterangebot sind getrennte Wahrheiten.**

Dies passt direkt zur owner-accepted Charter-Provider-Assortment-Entscheidung:

`docs/PRODUCT_CHARTER_PROVIDER_ASSORTMENT_v0.1.md`

Provy plant den Bedarf; Provider-Assortment beschreibt reale Lieferfähigkeit.

### 2.2 Airbnb – primärer Benchmark für Trip-/Context-Surfaces

Airbnb ist der primäre Referenzrahmen für:

- Home als kontextueller Einstieg;
- relevantes Objekt statt Dashboard-Überladung;
- Trip-/Booking-ähnlicher Kontext;
- kompakte Identität;
- Status und zeitlicher Kontext;
- klare nächste Aktion;
- Detail-Hierarchie;
- progressive disclosure;
- ruhige Cards / Sections;
- sekundäre Aktionen ohne Hauptfluss zu verwässern.

Dies passt zur eingefrorenen Provy-Struktur:

- Home zeigt nur den aktuell relevantesten Törn;
- Törnübersicht ist Hub;
- genau eine dominante Next Action;
- vier stabile Hauptbereiche.

### 2.3 Material 3 – technische Komponentenbasis

Material 3 bleibt die technische und Accessibility-orientierte Basis für Flutter-Komponenten, sofern kein Provy-spezifischer Grund dagegen spricht.

Verwenden für:
- Controls;
- States;
- Focus;
- Touch Targets;
- Dialoge / Sheets;
- Navigation primitives;
- Accessibility;
- systemnahe Verhaltenserwartungen.

Instacart/Airbnb definieren **UX-Pattern-Benchmarks**, Material 3 liefert **technische Component-Primitives**.

---

## 3. Kein visuelles Kopieren

Die Benchmark-Strategie bedeutet ausdrücklich **keine Pixel-Kopie**.

Nicht übernehmen:
- Markenfarben;
- Logos;
- proprietäre Illustrationen;
- exakte visuelle Identität;
- charakteristische Branding-Assets;
- unveränderte Texte;
- bewusst unverwechselbare Brand-Elemente.

Übernehmen bzw. analysieren dürfen wir:
- Informationsdichte;
- Hierarchie;
- Interaktionsfolge;
- Button-/Control-Position;
- bekannte Patterns;
- Disclosure;
- States;
- Feedback;
- Mengen-/List-Interaktion;
- Suchlogik;
- Provider-/Store-Kontext;
- Fehler-/Unavailable-Flows.

Danach erfolgt die Umsetzung im eigenen Provy-Designsystem:
- Off-White / Navy Light Default;
- Dark;
- Nightwatch / Rotlicht;
- eigene Typografie;
- eigene Spacing-/Shape-/Motion-Tokens;
- eigene Icons/Akzente soweit sinnvoll;
- Provy-spezifisches Wording.

---

## 4. Mapping auf Provy

### Home

Referenzdenken: **Airbnb**

Beibehalten:
- genau ein relevanter Törn;
- Situation zuerst;
- sichtbares `+ Neuer Törn`;
- `Alle Törns` sekundär;
- keine Dashboard-Kartenflut.

Benchmark-Fragen:
- Wie stark wird das primäre Objekt visuell priorisiert?
- Wie wird Zeit/Status verständlich?
- Wie bleibt die Hauptaktion eindeutig?
- Wie werden sekundäre Details zurückgenommen?

### Törnübersicht / Command Center

Referenzdenken: **Airbnb + Provy-frozen IA**

Beibehalten:
- kompakter Header;
- genau eine dominante Next Action;
- vier feste gleich große Hauptbereiche.

Benchmark darf:
- Card-Dichte;
- Typohierarchie;
- Statusplatzierung;
- CTA-Hierarchie;
- Section-Spacings;
- Disclosure verbessern.

Benchmark darf nicht:
- Hauptbereiche ändern;
- Tile-Positionen ändern;
- zusätzliche permanente Dashboard-Bereiche einführen.

### Vorräte / Planen

Referenzdenken: **Instacart**

Benchmark für:
- Search-first;
- Produktzeilen;
- Produktbilder nur wenn wirklich nützlich;
- Kategorie-/Department-Struktur;
- schnelle Mengenänderung;
- Add/Remove;
- Varianten;
- Gebinde;
- kompakte Status-/Hinweiszeilen.

Provy-spezifisch bleibt:
- Skipper baut die Liste;
- AssistType;
- Provisioning Review;
- Bordtauglichkeit;
- keine ungefragte Auto-Vollversorgung.

### Einkaufen

Referenzdenken: **Instacart In-Store / Shopping List**

Benchmark für:
- große Touch Targets;
- klare Department-Gruppen;
- ein Tap = gekauft;
- Fortschritt;
- Mengen auf einen Blick;
- schnelles Arbeiten ohne Detailnavigation;
- Substitution / nicht verfügbar;
- Stop-/Store-Kontext.

### Liefern lassen / Charter Provider

Referenzdenken: **Instacart Store/Availability-Modell**

Benchmark für:
- Provider auswählen;
- Liste gegen reales Sortiment abgleichen;
- verfügbar / nicht verfügbar;
- Alternativen;
- andere Packungsgröße;
- Provider-spezifische Darstellung;
- Nutzerbedarf bleibt erhalten.

Verbindliche Produktgrundlage:
`docs/PRODUCT_CHARTER_PROVIDER_ASSORTMENT_v0.1.md`

### Crew & Boot

Referenzdenken: **hochwertige Settings-/Profile-Patterns**, nicht Shopping-UI erzwingen.

Beibehalten:
- ein Screen;
- Boot zuerst;
- Crew danach;
- progressive disclosure;
- technische Details nur bei Relevanz.

### Bordkasse

Referenzdenken: **etablierte Consumer-Finance-/Wallet-Patterns**, ohne Banking-App zu imitieren.

Priorität:
- Kassenstand;
- Einzahlen;
- Ausgabe;
- klare Transaktionshistorie;
- Abrechnung erst situativ prominent.

---

## 5. Benchmark-Pass als verpflichtender UX-D-Schritt

Bevor UX-D implementiert wird, wird ein strukturierter **Provy UX Benchmark Pass** durchgeführt.

Für jeden Kernscreen:

1. aktuellen Provy-Screen / Wireframe erfassen;
2. primären Benchmark bestimmen;
3. relevante Referenz-Patterns beschreiben;
4. gegen Provy-Anforderungen prüfen;
5. Ergebnis klassifizieren:
   - `KEEP`
   - `ADOPT_PATTERN`
   - `SIMPLIFY`
   - `REMOVE`
6. Auswirkungen auf Accessibility, Dark/Nightwatch und Offline prüfen;
7. nur innerhalb der eingefrorenen IA umsetzen.

Der Pass umfasst mindestens:

- Home
- Törnübersicht / Command Center
- Vorräte
- Suche
- Add/Edit Item
- Einkaufen / Shopping Mode
- Einkaufsstopp
- Liefern lassen / Provider
- Guest Shopping
- Crew & Boot
- Bordkasse

---

## 6. Keine Mischmasch-UX

Provy soll nicht aus zehn unterschiedlichen Apps einzelne Stilelemente zusammenwürfeln.

Deshalb:

- Instacart = **primärer Shopping North Star**
- Airbnb = **primärer Trip/Context North Star**
- Material 3 = **technische Basis**

Weitere Produkte dürfen nur gezielt als Sekundärreferenz verwendet werden, wenn Instacart/Airbnb ein konkretes Problem nicht gut abdecken.

Eine zusätzliche Referenz muss immer mit einer konkreten Frage begründet werden.

---

## 7. Entscheidungsregel bei Konflikten

Wenn ein Benchmark-Pattern mit einer bereits owner-accepted Provy-Entscheidung kollidiert:

1. Provy-Produktentscheidung gewinnt;
2. frozen IA gewinnt;
3. Offline-/Bordtauglichkeit gewinnt;
4. Accessibility / Nightwatch gewinnt;
5. erst danach Benchmark-Pattern.

Der Benchmark ist **Werkzeug, keine neue Source of Truth über dem Produktmodell**.

---

## 8. Design Review Questions

Bei jeder neuen oder wesentlich geänderten Surface sind mindestens diese Fragen zu beantworten:

- Ist das Problem bereits ein etabliertes Consumer-Pattern?
- Wie löst der zuständige North Star dieses Problem?
- Können wir ein bekanntes Pattern übernehmen, statt ein eigenes zu erfinden?
- Ist unsere Lösung einfacher oder nur anders?
- Muss der Nutzer etwas erinnern, das er auch erkennen könnte?
- Ist die Hauptaktion sofort klar?
- Kann eine Aktion inline erfolgen statt über einen neuen Screen?
- Ist Information sichtbar, bevor sie gebraucht wird, aber nicht dauerhaft dominant?
- Funktioniert der Flow mit einer Hand / großen Touch Targets?
- Funktioniert er offline bzw. bei instabiler Verbindung?
- bleibt Dark/Nightwatch vollständig nutzbar?
- bleibt die bestehende Provy-Hierarchie erhalten?

---

## 9. Verbindliches zukünftiges Gate

Vor folgenden Arbeiten muss diese Strategie ausdrücklich berücksichtigt werden:

- UX-D / Issue #21
- wesentliche Überarbeitung von Vorräte
- wesentliche Überarbeitung von Einkaufen / Shopping Mode
- Provider-Assortment / Charter-Provisioning UI
- Guest Shopping UI
- Home / Command Center Redesign
- größere neue Consumer-Surface

Insbesondere darf UX-D nicht nur aus den vorhandenen Wireframes „pixelmäßig umgesetzt“ werden, ohne vorher den Benchmark Pass durchzuführen.

Der Benchmark Pass darf jedoch die eingefrorene Informationsarchitektur **nicht eigenmächtig ändern**.

Falls beim Benchmarking eine bessere IA oder Interaktionslogik entdeckt wird, die den Freeze berührt:
- als Owner-Decision-Vorschlag dokumentieren;
- nicht still implementieren;
- Product Owner entscheidet ausdrücklich.

---

## 10. Aktueller Gate-Status

Diese Strategie ist **OWNER-ACCEPTED**, aber kein eigenständiger Implementierungsslice.

WATER1 bleibt der einzige aktuell freigegebene Implementierungsslice.

UX-D bleibt separat gegatet.

Vor UX-D wird der Benchmark Pass verpflichtend durchgeführt und dokumentiert.
