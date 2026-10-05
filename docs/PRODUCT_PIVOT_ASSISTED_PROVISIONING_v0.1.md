# Product Pivot v0.1 – Assisted Provisioning

Stand: 05.10.2026  
Status: **OWNER-ACCEPTED / verbindlich für die weitere Produktentwicklung**

## 1. Entscheidung

Provy wird von einer primär automatisch berechnenden Proviantliste zu einem **assistierten Provisioning-Workflow** umgestellt.

Neue Leitlinie:

> **Der Skipper baut die Liste. Provy macht sie vollständig, realistisch und bordtauglich.**

Provy entscheidet nicht mehr ungefragt, welche konkreten Lebensmittel eine Crew über einen ganzen Törn konsumieren soll.

Die App bleibt ausdrücklich **kein Rezept- und kein Menüplaner**.

## 2. Warum der Pivot notwendig ist

Der interne Praxistest hat systematische Grenzen der bisherigen universellen Mengenlogik gezeigt:

- Tofu wurde vorgeschlagen, obwohl nicht bekannt ist, wie viele Personen Tofu essen.
- Pesto wurde bei 5 Personen / 14 Tagen in einer Größenordnung von 14 Gläsern vorgeschlagen.
- 44 frische Brötchen wurden als Törnmenge vorgeschlagen, obwohl sie nur sehr kurz haltbar sind.
- Butter und Marmelade erschienen als mathematisch exakte, aber einkaufspraktisch ungeeignete Grammwerte.
- Geschmack, Essgewohnheiten und konkrete Mahlzeiten lassen sich ohne echte Nutzerentscheidung nicht zuverlässig aus Crewgröße und Törndauer ableiten.

Die Ursache ist nicht nur ein einzelner Rechenfehler. Das bisherige Modell beansprucht bei vielen Artikeln Wissen über die Crew, das Provy nicht besitzt.

## 3. Neues Produktmodell

### 3.1 Skipper-gesteuerte Liste

Ein neuer Törn beginnt mit einer leeren bzw. bewusst minimalen Liste.

Der Nutzer fügt Positionen aktiv hinzu:

1. Suchfeld öffnen / direkt tippen.
2. Bereits nach wenigen Buchstaben passende Produktgruppen/Varianten anzeigen.
3. Variante wählen.
4. Übliche Gebindegrößen anzeigen.
5. Gebinde und Anzahl wählen.
6. Position landet auf der Liste.

Beispiele:

- Eingabe `wasser` → Wasserarten + sinnvolle Gebindegrößen
- Eingabe `kä` → Käsesorten + Gebindegrößen
- Eingabe `pesto` → Pesto + vorhandene Gebindegrößen
- kein Treffer → eigene Position anlegen

Die Katalogsuche muss schnell genug sein, dass eine komplette Liste auf dem Handy ohne unnötige Navigation aufgebaut werden kann.

## 4. Drei Assistenzklassen

Nicht jeder Artikel wird gleich behandelt.

### A. Needs-based

Bedarf ist ausreichend objektiv, sodass Provy einen belastbaren Richtwert berechnen darf.

Beispiele:
- Trinkwasser / Sicherheitsreserve
- ggf. wenige klar quantifizierbare Verbrauchsgüter

Verhalten:
- Nutzer wählt weiterhin Produkt/Gebinde.
- Provy zeigt einen klar gekennzeichneten Richtwert.
- Nutzer entscheidet die tatsächliche Menge.

### B. Guided

Bedarf ist teilweise ableitbar, aber stark von Crew und Gewohnheiten abhängig.

Beispiele:
- Brot / Backwaren
- Milch
- Butter
- Toilettenpapier
- manche Getränke oder Standardvorräte

Verhalten:
- keine ungefragte automatische Aufnahme.
- nach Auswahl kann Provy einen Richtwert, MHD-Hinweis oder Plausibilitätscheck zeigen.
- Nutzer bestätigt/ändert die Menge.

### C. Preference-based

Provy kann nicht seriös wissen, ob bzw. wie oft das Produkt konsumiert wird.

Beispiele:
- Pesto
- Tofu
- bestimmte Käsesorten
- Aufstriche
- Snacks
- spezielle Saucen
- viele Getränke und Genussmittel

Verhalten:
- **keine automatische Bedarfsmengenberechnung als Listenvorschlag**.
- Nutzer wählt Produkt und Menge.
- Provy unterstützt mit Gebinde, Haltbarkeit, Kühlung, Gewicht/Volumen und Stop-Zuordnung.

## 5. Was Provy nach Fertigstellung der Liste tut

Provy wird stärker zum **Prüfer / Copilot**.

Die App analysiert die vom Skipper gebaute Liste und zeigt neutrale Hinweise:

### Fehlende Bereiche

Beispiele:
- keine Trinkwasserreserve erkannt
- keine haltbare Brotreserve
- kein Speiseöl
- keine Hygiene-/Reinigungsgrundlage
- keine Müllbeutel

Hinweise müssen als Vorschläge erscheinen, nicht als Fehler oder Zwang.

### Möglicherweise zu geringe Menge

Nur dort, wo ein belastbarer Richtwert existiert.

Beispiel:
> Deine Liste enthält 18 l Flaschenwasser. Für 5 Personen und 14 Tage erscheint die Sicherheitsreserve bei deiner Tank-/Watermaker-Konfiguration niedrig.

### Haltbarkeit

Beispiel:
> 44 frische Brötchen passen nicht zur angegebenen Haltbarkeit. Für spätere Tage frisch nachkaufen oder haltbare Alternative ergänzen.

### Kühlung / Tiefkühlung

- vorhandene Kühlschrank-/TK-Kapazität berücksichtigen
- Kühlpflicht kenntlich machen
- ggf. Warnung bei offensichtlich zu hohem gekühltem Volumen

### Einkaufsstopps

- Frischware einem sinnvollen Einkaufsstopp zuordnen
- nicht stillschweigend Gesamt-Törn-Frischmengen in den ersten Einkauf legen

### Gewicht / Volumen

Bestehende Summen bleiben erhalten und werden auf die tatsächlich ausgewählte Liste angewendet.

## 6. Listen-UX

### Entfernen / ersetzen

Die bisherige Hauptaktion **„Alle Vorschläge übernehmen“** wird aus dem primären Workflow entfernt.

Sie darf nicht länger eine vollständige automatisch berechnete Crewversorgung erzeugen.

### Neuer Hauptweg

Liste:
- prominente Suche / „Position hinzufügen“
- schnelle Autocomplete-Ergebnisse
- Varianten direkt auswählbar
- Gebindegrößen direkt im Auswahlflow
- Anzahl mit großen +/− Bedienelementen und Direkteingabe
- zuletzt/häufig verwendete Artikel optional später, nicht zwingend im ersten Pivot-Slice

### Grundausstattung

Falls eine Startvorlage angeboten wird, darf sie nur neutrale **Kategorien/Checkpunkte** oder wenige wirklich universelle Needs-based-Positionen enthalten.

Keine automatische Sammlung aus Tofu, Pesto, Käse, Snacks etc.

## 7. Relevanz der bestehenden Daten

Nicht wegwerfen:

- Produktkatalog
- Varianten
- Packungs-/Gebindegrößen
- Haltbarkeit
- `buy_fresh_underway`
- Kühl-/TK-Anforderungen
- `shelf_life_frozen_days`
- Gewicht/Volumen
- Einkaufsstopps
- Tank
- Watermaker (neu, Issue #5)
- internationale Gebindevalidierung

Diese Daten werden im neuen Modell sogar wichtiger, weil sie reale Nutzerentscheidungen unterstützen statt Entscheidungen zu ersetzen.

## 8. Quantity Engine

Die aktuelle universelle automatische Quantity Engine darf nicht mehr die Produktwahrheit für alle Katalogpositionen sein.

Ziel:
- erhalten, wo Needs-based/Guided fachlich sinnvoll;
- für Preference-based Artikel deaktivieren;
- Assistenz- und Plausibilitätsregeln klar von eigentlichen Listenmengen trennen.

Keine kosmetische Reparatur einzelner Faktoren, wenn das Grundmodell falsch ist.

## 9. Abgrenzung

Nicht Teil dieses Pivots:
- Rezeptplanung
- Menüplanung
- KI-Menügeneration
- automatische Ernährungsempfehlungen
- automatische Geschmacksannahmen
- Preisvergleich
- Händler-/Vendor-Integration
- Barcode-Scanner
- B3/B4/B5 Backend-Slices
- Store-Veröffentlichung

## 10. Zusammenhängende bestehende Findings

Der Pivot adressiert strukturell insbesondere:

- Issue #7 – unplausible Roh-/Packungsmengen
- Issue #8 – Frischware / Haltbarkeit
- Issue #9 – Meal-frequency items treated as daily staples

Diese Issues bleiben als Regression-/Abnahmereferenzen bestehen.

Zusätzlich zu berücksichtigen:
- Issue #4 – Crewgröße unter 5
- Issue #5 – Watermaker
- Issue #6 – wiederverwendbare Bootsprofile

## 11. Umsetzung in Slices

### PIVOT1 – Assisted List Core

Ziel:
- automatisches „komplette Liste übernehmen“ aus dem Hauptweg entfernen
- Suche → Variante → Gebinde → Anzahl → Liste
- Preference-based Artikel ohne Auto-Menge
- Needs-based/Guided-Struktur im Domainmodell
- bestehende manuelle Positionen weiterhin möglich
- keine Regression im Einkaufsmodus

### PIVOT2 – Provisioning Review

Ziel:
- Liste prüfen
- fehlende Kategorien/Grundbedarfe
- belastbare Mengenhinweise
- MHD-/Frischehinweise
- Kühl-/TK-Hinweise
- Wasser/Tank/Watermaker-Plausibilität
- keine Zwangsänderungen

### PIVOT3 – Boat Profiles & Setup Rebase

Ziel:
- Issue #6 Bootsprofile
- Issue #5 Watermaker
- Issue #4 Crewgrößen-Bug
- Bootsdaten als wiederverwendbares Profil + Törn-Snapshot

CAT1 (internationale Gebindegrößen) kann danach bzw. parallel zur Katalogpflege erfolgen, aber nicht mehr als Versuch, eine universelle automatische Vollversorgung zu perfektionieren.

## 12. Abnahmekriterium für den Pivot insgesamt

Ein Skipper muss einen 5-Personen-/14-Tage-Törn anlegen und eine sinnvolle Einkaufsliste bauen können, ohne dass Provy ungefragt konkrete Geschmacksentscheidungen oder tägliche Menüannahmen trifft.

Provy soll danach nachvollziehbar sagen können:
- was eventuell fehlt,
- was wahrscheinlich zu wenig ist,
- was zu schnell verdirbt,
- was Kühlung braucht,
- was besser an einem späteren Stopp gekauft wird,
- und wie die ausgewählten Waren real verpackt/eingekauft werden.

**Prinzip: assistieren statt erfinden.**
