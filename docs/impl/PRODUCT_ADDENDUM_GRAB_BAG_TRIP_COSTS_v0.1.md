# Product Addendum v0.1 – Grab Bag & vollständige Törnkosten

Stand: 04.10.2026
Status: Owner-accepted product direction, noch nicht implementiert
Vorrang: Dieses Addendum ergänzt die bestehende PRD-/UX-/Slice-Dokumentation. Es erweitert den bestehenden Bordkassenumfang und führt eine neue Grab-Bag-/Departure-Readiness-Funktion ein. Es darf den laufenden Slice FB2-B nicht verändern oder aufblähen.

## 1. Grundsatz

Provy soll entlang des realen Törnablaufs vier Fragen gut beantworten:

1. Was brauchen wir?
2. Ist das Wesentliche vor dem Ablegen bereit?
3. Welche gemeinsamen Törnkosten fallen unterwegs an?
4. Wer hat am Ende was bezahlt bzw. wer schuldet wem?

Die beiden Erweiterungen sind:
- **TC1 – vollständige variable Törnkosten in der Bordkasse**
- **GB1 – Grab Bag / Departure Readiness**

## 2. TC1 – vollständige variable Törnkosten

### 2.1 Bestehender Stand

Die aktuelle Domain enthält bereits Bordkassen-Kategorien für:
- Proviant
- Getränke
- Hafen und Liegeplatz
- Diesel
- Charter und Kaution
- Restaurant
- Sonstiges

Damit sind Sprit und Liegegebühren bereits grundsätzlich im Cost Share vorhanden. TC1 darf diese bestehende Funktion nicht doppelt bauen.

### 2.2 Verbindliche Erweiterung

Die Bordkasse soll als vollständige **Törnkosten-Kasse** sichtbar werden, nicht nur als Lebensmittelabrechnung.

Pflicht:
- Diesel/Treibstoff bleibt eigene Kategorie.
- Hafen/Marina/Liegeplatz bleibt eigene Kategorie.
- Marina-Nebenkosten wie Wasser/Strom/Duschen müssen entweder als klar erkennbare eigene Kategorie oder über eine explizite, gut benannte flexible Position erfasst werden können. Entscheidung im Implementierungsslice anhand minimaler Datenmodelländerung.
- Freie sonstige Ausgaben bleiben möglich.
- Eine Ausgabe enthält weiterhin Betrag, Währung, Kategorie, wer bezahlt hat bzw. Zahlung aus der Bordkasse und Beteiligung/Split.
- Die bisherige individuelle Betragsaufteilung bleibt erhalten.
- Optionales **Belegfoto** pro Ausgabe wird ergänzt. Offline-first: lokaler Dateiverweis; Cloud-/Backup-Verhalten explizit definieren, keine stillschweigende Synchronisation großer Binärdateien.
- Belegfoto ist Komfortfunktion, kein Pflichtfeld.

### 2.3 Törnkosten-Zusammenfassung

In der Törn-Übersicht bzw. beim Abschluss wird eine verständliche Zusammenfassung angezeigt:

Beispiel:
- Proviant 620 €
- Diesel 184 €
- Hafen/Liegeplatz 310 €
- Sonstiges 86 €
- **Gesamt 1.200 €**
- **Ø 200 € pro beteiligter Person** (nur anzeigen, wenn mathematisch sinnvoll; individuelle Beteiligungsregeln dürfen dadurch nicht überschrieben werden)

Wichtig:
- Der Durchschnitt ist nur Information.
- Die eigentliche Abrechnung basiert weiter auf den existierenden Beteiligungsregeln und Custom Splits.
- Mehrere Währungen dürfen nicht naiv addiert werden. Falls in v1 nur EUR zuverlässig aggregierbar ist, muss die UI getrennte Summen je Währung anzeigen oder die Gesamtanzeige entsprechend einschränken.

### 2.4 Akzeptanz TC1

- Diesel-Ausgabe wird erfasst und korrekt geteilt.
- Marina-/Liegeplatz-Ausgabe wird erfasst und korrekt geteilt.
- Marina-Nebenkosten sind eindeutig erfassbar.
- Beliebige eigene sonstige Ausgabe bleibt möglich.
- Kategorie-Summen entsprechen exakt der Summe der zugrunde liegenden Ausgaben.
- Gesamtsumme entspricht exakt der Summe der kompatiblen Währungsbeträge.
- Settlement-Ergebnis bleibt mathematisch korrekt.
- Optionales Belegfoto lässt sich hinzufügen, anzeigen, ersetzen und entfernen.
- Löschen einer Ausgabe hinterlässt keine verwaisten lokalen Belegdateien.
- Backup/Restore-Verhalten von Belegen ist dokumentiert und getestet.
- UI ist offline nutzbar.

## 3. GB1 – Grab Bag / Departure Readiness

### 3.1 Zweck

Provy erhält eine **konfigurierbare Grab-Bag-/Notfalltaschen-Checkliste** als Teil der Törnvorbereitung.

Die Funktion soll helfen, Dinge **nicht zu vergessen**. Sie darf nicht behaupten, eine vollständige sicherheitsrechtliche, medizinische oder professionelle Offshore-Ausrüstungsplanung zu ersetzen.

Verbindlicher Hinweis:
> Anforderungen hängen von Boot, Fahrtgebiet, Crew, Wetter, Reiseart und gesetzlichen Vorgaben ab. Provy unterstützt beim Prüfen und Erinnern; der Skipper bleibt verantwortlich.

### 3.2 Standardbereiche

Die Default-Checkliste soll mindestens diese Bereiche abdecken:

- Dokumente / Kopien
- Notfallkommunikation
- Licht / Energie
- Notwasser
- Notverpflegung
- Erste Hilfe / persönliche Medikamente
- Wärme-/Wetterschutz
- Signalmittel
- Messer / Multitool
- persönliche notwendige Gegenstände
- sonstige boots-/crew-spezifische Punkte

Keine einzelne Liste darf als universell „vollständig“ oder „vorgeschrieben“ bezeichnet werden.

### 3.3 Bedienung

Pflicht:
- Standardpunkte abhaken.
- Eigene Punkte hinzufügen, bearbeiten und löschen.
- Bereiche einklappbar.
- Status in der Törn-Übersicht, z. B. **„Grab Bag 8/11 bereit“**.
- Eintrag kann optional einen kurzen Hinweis enthalten.
- Eintrag kann optional ein Prüf-/Ablaufdatum oder „vor Abfahrt prüfen“ besitzen.
- Physischer Aufbewahrungsort der Grab Bag kann erfasst werden und soll vor Abfahrt sichtbar bestätigt werden.

### 3.4 Readiness-Checks

Mindestens folgende prüfbare Zustände als Default-Vorlagen vorsehen:
- Dokumente vorhanden
- Batterien geprüft
- Powerbank geladen
- Notwasser ergänzt
- persönliche Medikamente geprüft
- Signalmittel geprüft / Gültigkeit geprüft
- bekannte Grab-Bag-Position bestätigt

Keine automatische Behauptung „sicher“ oder „seetüchtig“.

### 3.5 Mengenabhängige Hinweise

Provy darf für ausgewählte Punkte neutrale **Planungshinweise** aus Crewgröße und gewünschtem Zeitraum ableiten, insbesondere:
- Notwasser
- Notverpflegung

Aber:
- keine medizinische Ernährungsempfehlung,
- keine Behauptung regulatorischer Mindestmengen,
- klar als Nutzer-/Planungshilfe kennzeichnen,
- Werte datengetrieben und später konfigurierbar, nicht hart codiert in UI-Widgets.

### 3.6 Segelschulen / B2B

GB1 ist ausdrücklich auch als B2B-Mehrwert gedacht:
- Segelschulen können strukturiertes „ready for departure“-Denken lehren.
- Schüler planen zunächst selbst und vergleichen anschließend mit der Checkliste.
- Provy ersetzt nicht die Ausbildung.
- Partner dürfen die Checkliste später ergänzen, sofern dies separat entschieden wird; ein White-Label-Sicherheitsstandard ist ausdrücklich nicht Teil von GB1.

### 3.7 Akzeptanz GB1

- Grab Bag kann für einen Törn aktiviert/deaktiviert werden.
- Default-Checkliste wird lokal erzeugt.
- Punkte lassen sich abhaken.
- Eigene Punkte lassen sich CRUD bearbeiten.
- Fortschritt wird korrekt berechnet.
- Ablauf-/Prüfhinweise sind sichtbar.
- Aufbewahrungsort kann erfasst und vor Abfahrt bestätigt werden.
- Status erscheint in der Törn-Übersicht, ohne einen neuen permanenten Haupttab einzuführen.
- Offline vollständig nutzbar.
- Backup/Restore umfasst die strukturierten Checklistendaten.
- Keine Formulierung behauptet Vollständigkeit, rechtliche Compliance oder garantierte Sicherheit.
- Widget-/Unit-Tests decken Fortschritt, CRUD, Persistenz und Readiness-Status ab.

## 4. UX-Einordnung

Keine neue globale Navigation.

Empfehlung:
- In der **Törn-Übersicht** innerhalb des Vorbereitungs-/Planungsbereichs eine kompakte Karte:
  - „Grab Bag · 8/11 bereit“
  - Hauptaktion „Prüfen“
- Detail als Vollbild-Sheet oder höchstens eine Ebene tiefer.
- Törnkosten-Zusammenfassung in „Unterwegs / Bordkasse“ und im Abschluss.

## 5. Priorität und Reihenfolge

- **TC1: hohe Priorität**, weil die Bordkasse den gesamten Törnkosten-Nutzen sichtbar ausschöpfen soll.
- **GB1: wertvolle Erweiterung nach dem aktuellen MVP-Test**, besonders für Segelschulen/B2B.

Beide dürfen den aktuell laufenden FB2-B-Slice nicht verändern.

Empfohlene Reihenfolge:
1. aktuellen bestehenden Plan bis zur internen Testphase abschließen,
2. reale Testphase durchführen,
3. TC1 implementieren,
4. GB1 implementieren,
5. danach B3–B5 bzw. öffentliche Veröffentlichung entsprechend dem dann aktuellen Rebaseline-Plan einordnen.

Vor Implementierung ist der aktuelle Repo-Stand erneut zu reconciliieren.
