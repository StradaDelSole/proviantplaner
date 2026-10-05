# PIVOT1 – Assisted List Core – Implementierungsplan

Stand: 05.10.2026  
Grundlage: `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md` + `docs/design/PROVY_UX_DIRECTION_v0.4.md`  
Status: **OWNER-ACCEPTED PRODUKTRICHTUNG / UX-DETAILS FREIGEGEBEN / IMPLEMENTIERUNG GESTOPPT bis FIX-A owner-accepted ist**

## Ziel

Den Kernflow der Vorratsliste von automatisch berechneter Vollversorgung auf skipper-gesteuerte Auswahl umstellen.

## Vor Implementierung

1. `origin/main` aktualisieren.
2. Aktuellen Stand der List-/Catalog-/Quantity-Implementierung, Tests und Drift-Schema prüfen.
3. Decision/Implementation-Reconciliation:
   - was ist bereits implementiert,
   - was wird durch den Pivot superseded,
   - welche bestehende Logik bleibt nützlich.
4. Keine offenen lokalen Änderungen überschreiben.
5. `docs/design/PROVY_UX_DIRECTION_v0.4.md`, `docs/design/PROVY_UX_DECISIONS_2026-10-05.md` und `docs/design/PROVY_UX_WIREFRAMES_v0.1.md` lesen und die für PIVOT1 verbindlichen UX-Prinzipien/Wireframes reconciliieren.
6. PIVOT1 nur starten, wenn README es nach FIX-A-Abnahme ausdrücklich wieder freigibt.

## Scope

### 1. Hauptflow Liste

- neue Liste bleibt leer bzw. enthält keine ungefragt übernommenen konkreten Lebensmittel
- prominente Katalogsuche
- Suche reagiert auf Teilstrings
- Treffer zeigen konkrete Varianten
- Auswahl einer Variante führt unmittelbar zur Gebinde-/Mengenwahl
- vorhandene Packungsgröße vorauswählen
- Anzahl mit +/− und Direkteingabe
- Position anschließend auf der Liste

### 2. Preference-based Produkte

Mindestens Pesto und Tofu als Regressionfälle:
- keine automatische Mengenempfehlung aus Crew × Tagen
- keine automatische Aufnahme
- Nutzer bestimmt Anzahl/Gebinde

Domainmodell so gestalten, dass weitere Produkte ohne Sondercode klassifiziert werden können.

### 3. Needs-based / Guided vorbereiten

Eine explizite, testbare Klassifikation einführen oder vorhandenes Schema minimal erweitern.

Noch keine komplexe Review-Engine bauen; PIVOT1 muss nur verhindern, dass alle Produkte weiterhin wie automatisch berechenbare Staples behandelt werden.

### 4. „Alle Vorschläge übernehmen“

- aus dem primären Flow entfernen
- keine Aktion darf eine komplette automatisch errechnete Ernährungsliste erzeugen
- vorhandene Implementierung nur erhalten, falls für Migration/Tests technisch nötig, aber nicht als aktive Hauptfunktion

### 5. Bestehende Funktionen erhalten

- eigene Position
- Kategorie-/Abteilungssortierung
- Einkaufsstopps
- Einkaufsmodus
- gekauft/eingelagert
- Packungsgröße
- Gewicht/Volumen der tatsächlich übernommenen Liste
- MHD-/Kühlmetadaten
- Offline-Funktion
- Backup-Kompatibilität
- stabile `ListItem`-/`ShoppingStop`-/Allocation-Referenzen so erhalten/gestalten, dass spätere GUEST1-Share-Pakete darauf sicher referenzieren können; GUEST1 selbst wird in PIVOT1 noch nicht implementiert

### 6. Keine Menüplanung

Keine Rezepte, Mahlzeiten oder Tagesmenüs generieren.

## Verbindliche UX-Leitplanken aus Provy UX Direction

- Search-first statt Katalogbaum als Hauptweg.
- Eine sofort erkennbare primäre Aktion; keine unnötigen Zwischenebenen.
- Variante → Gebinde → Anzahl → Liste in einem flachen, mobilen Flow.
- Progressive Disclosure: MHD/Kühlung/Gewicht/weitere Details nur dort prominent zeigen, wo sie die Entscheidung unterstützen.
- Tactile feedback für Hinzufügen, Mengenänderung und Bestätigung; Animation erklärt Zustand, nicht dekorieren.
- Anzahl bevorzugt als schneller Stepper; Tap auf Wert darf später Pickwheel öffnen; direkte Eingabe bleibt möglich.
- Color Coding nur als subtiler Funktions-/Statusakzent, nie als einzige Information.
- Gute Empty States: leere Liste führt unmittelbar in die Produktsuche.
- Keine neue Dashboard-/Bento-Struktur innerhalb des eigentlichen Listen-Task-Screens.
- Alle UI-Entscheidungen müssen Low Friction, Einfachheit, professionellen und funktionalen Eindruck priorisieren.

## UX-Abnahme

Ein Nutzer kann z. B.:
1. `kä` tippen,
2. Käsevarianten sehen,
3. eine Variante wählen,
4. Gebinde sehen,
5. Anzahl wählen,
6. zur Liste hinzufügen,

ohne zusätzliche verschachtelte Maske.

Analog für Wasser, Pesto und andere Katalogartikel.

## Tests

Mindestens:
- leere neue Liste
- Teilstringsuche
- Auswahl Variante → Gebinde → Anzahl → Persistenz
- Pesto erzeugt keine automatische 14-Tage-Menge
- Tofu erzeugt keine automatische Crewmenge
- manuelle Änderung bleibt nach Crew-/Daueränderung stabil
- bestehender Einkaufsmodus zeigt exakt die vom Nutzer gewählten Positionen
- eigene Position funktioniert weiterhin
- Offline-Test
- bestehende relevanten Tests aktualisieren, nicht einfach löschen

## Nicht in PIVOT1

- PIVOT2 Review-/Missing-items-Engine
- Bootsprofile
- Watermaker
- Crewgrößenfix
- CAT1-Recherche
- B3/B4/B5
- Store-Publikation
- neue Backend-Funktionen
- GUEST1 Guest-Shopping-Backend/QR/Offline-Sharing (nur Datenmodell-Kompatibilität vorbereiten)
- Preise/Vendor/Barcode/AI

## Abschluss

- Implementierungsbericht unter `docs/impl/PIVOT1_bericht.md`
- README/CHANGELOG aktualisieren
- analyze + vollständige Flutter-Tests
- Commit + Push
- danach STOP und Review anfordern
