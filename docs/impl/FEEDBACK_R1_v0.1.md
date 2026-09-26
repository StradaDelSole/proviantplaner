# Feedback-Runde 1 v0.1 – erster Praxistest auf dem Emulator

Stand: 26.09.2026 · Quelle: Test durch den Product Owner auf dem Android-Emulator, Code-Stichproben durch Claude · **Dieses Dokument ist vorrangig gegenüber PRD v0.16 und Design-Brief v0.4**; beide verweisen darauf.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 26.09.2026 | Erstfassung: 10 Punkte aus dem ersten Praxistest, Build-Einstellungen, Ergebnis manueller QR-Test |

## Ergebnis manueller Test (durch den Menschen)

- **EPC-QR-Scan:** Die Banking-App des Product Owners liest den Code; **Betrag und IBAN werden korrekt übernommen.** Übernahme von Empfängername und Verwendungszweck nicht bestätigt. Getestet mit der fest eingebauten Beispiel-IBAN (siehe Punkt 10).

## Punkte

### 1. Törnlänge bis 180 Tage
- Eingabe als Zahlenfeld (1–180) mit Schnellauswahl: 1 Woche, 2 Wochen, 1 Monat, 3 Monate, 6 Monate
- Tagesleiste ab 28 Tagen nach Wochen gruppiert (Woche einklappbar, Tage darin aufklappbar)
- Ab 15 Tagen neutraler Hinweis in der Liste: "Bei längeren Törns lohnt es sich, Einkaufsstopps anzulegen." (keine automatische Verteilung)

### 2. Kühlkapazität ab 0 Litern
- Regler/Feld beginnt bei 0; zusätzlich Schalter "kein Kühlschrank" (= 0 l)
- Bei 0 l: Varianten mit Einlagerungshinweis `cool_first` bzw. Abteilung Kühlregal erhalten den Hinweis "braucht Kühlung"; die App wählt nichts ab
- Hinweis mit Verweis auf ungekühlt haltbare Alternativen aus dem Katalog (H-Milch, gesalzene Butter, Hartkäse, Salami/Chorizo, Konserven)

### 3. "Wie warm wird es?" statt Revier
- Frage mit drei Antworten: **kühl** (meist unter 20 °C), **warm** (20–28 °C), **heiß** (über 28 °C)
- Trinkwasser: kühl 1,5–2 l, warm 2–3 l, heiß 3–4 l pro Person und Tag (`data/quantities_v0.5.json`, Schlüssel `cool`, `warm`, `hot`)
- Einlagerungs-Checkliste standardmäßig aktiv bei "heiß"
- Revier wird aus Oberfläche und Datenmodell entfernt (Migration: temperate → cool, mediterranean_summer → warm, hot_or_remote → hot)

### 4. Reiter ohne Törn
- Auf "Meine Törns" gibt es keine Reiterleiste (Design-Brief v0.4, Abschnitt 3.1). Reiter erscheinen nur innerhalb eines Törns. Tippen darf nie wirkungslos sein.

### 5. Neues Listenkonzept: leere Liste mit Vorschlägen
- **Die Liste startet leer.** Zu jeder Katalogposition wird ein **Vorschlag** angezeigt (z. B. "Vorschlag: 3 × 750 g").
- Übernehmen **einzeln** ("+ übernehmen" an der Position) oder **gesamt** ("Alle Vorschläge übernehmen", auch je Kategorie).
- Nach dem Übernehmen gehört die Menge dem Nutzer: direkt per Tipp eingeben (Zahlenfeld) oder mit +/−; der Vorschlag bleibt klein daneben sichtbar ("Vorschlag 3").
- Ändert sich die Crew oder die Dauer, ändern sich nur die **Vorschläge**, nie die übernommenen Mengen. Eine dezente Markierung zeigt, wenn Menge und neuer Vorschlag stark abweichen.
- **Nichts wird durchgestrichen.** Nicht übernommene Positionen stehen normal da.
- **Keine Bewertungen** ("gedeckt", "knapp" entfallen). Höchstens neutrale Info "Vorschlag gesamt: ca. 4,2 kg Brot".
- Alle Katalogvarianten sind wählbar, auch solche mit `default_selected: false`; `default_selected` bestimmt nur, welche Varianten bei "Alle Vorschläge übernehmen" enthalten sind.
- Rechenlogik (Mengen-Engine) bleibt unverändert und liefert die Vorschläge.

### 6. Fehler: Auswahl und Mengen nicht änderbar
- Checkboxen im Varianten-Sheet reagieren nicht (weder an- noch abwählen), Mengen nicht änderbar; betrifft alle Gruppen.
- Vermutete Ursache (Code-Stichprobe): Das Sheet erhält beim Öffnen eine Momentaufnahme (`widget.groupView`) und beobachtet den Provider nicht; Schreibaufrufe werden nicht abgewartet (`toggleVariantSelected` ohne `await`, sofortiges `invalidate`).
- Prüflisten-Gruppen (z. B. "Reparatur allgemein") brauchen drei Zustände: vorhanden / fehlt / nachkaufen.
- **Pflicht-Tests (Widget-Tests mit echter Interaktion):** Sheet öffnen → Eistee antippen → Eistee steht auf der Liste; wieder abwählen → verschwindet; Menge per Eingabe ändern → neuer Wert sichtbar und gespeichert.

### 7. Eine Liste statt zwei Sichten
- Die Sichten "Planen" und "Einkaufen" entfallen. **Eine Liste**, Umschalter nur für die **Sortierung**: "nach Kategorie" (Kategorie → Bedarfsgruppe → Variante) oder "nach Supermarkt-Abteilung" (flach, Ladenreihenfolge).
- Jede Position sieht in beiden Sortierungen gleich aus und ist gleich bearbeitbar.
- **Einkaufen ist ein eigener Modus** ("Einkauf starten" je Einkaufsstopp) mit großen Häkchen, ohne Bearbeiten.
- **Regel:** Der Einkaufsmodus eines Stopps zeigt exakt alle Positionen der Liste mit Menge > 0, die diesem Stopp zugeordnet sind (nicht zugeordnete gehören zum ersten Stopp), inklusive eigener Positionen. Test vergleicht Liste und Einkaufsmodus Position für Position.

### 8. Ausgaben bearbeiten und löschen
- Tipp auf eine Ausgabe öffnet sie mit allen Feldern; "Löschen" mit Rückgängig (5 s).
- Kassenstand und Salden werden sofort neu berechnet (Test).

### 9. Bordkasse neu gedacht
- **Kassenwart:** Beim ersten Öffnen "Wer verwaltet die Kasse?" (Standard: Skipper). "Die Kasse" ist kein Konto; alle Zahlungen an oder aus der Kasse laufen über den Kassenwart.
- **Einzahlen in einem Schritt:** "Wie viel zahlt jeder ein?" – ein Betrag für alle, darunter Namen zum Abhaken, wer bezahlt hat.
- **Ausgabe mit drei Feldern:** Betrag, wofür (Kategorie), wer hat bezahlt (Kasse oder Person). Abweichende Aufteilung nur unter "Mehr Optionen".
- **Nachschuss:** bei niedrigem Kassenstand Hinweis "Kasse fast leer – jeder legt X € nach?" mit Übernehmen.
- **Abrechnung auf einem Bildschirm:** je Person eine Zeile "bekommt 18,00 € von Anna" oder "zahlt 42,10 € an Anna" mit Button "Bezahlen" (öffnet QR/Links des Empfängers). Keine Zeilen "→ Kasse".
- Einzelabrechnung bleibt als Alternative, gleiche Darstellung der Abrechnung.

### 10. Kritisch: Zahlungsdaten fest im Code
- `settlement_screen.dart` verwendet eine fest eingetragene Beispiel-IBAN (`DE89370400440532013000`). Verstoß gegen Regel 4; echte Überweisungen wären unmöglich bzw. falsch adressiert.
- Je Crewmitglied: Name, IBAN (mit Prüfsumme validiert), optional PayPal-Link und Revolut-Link; Eingabe in der Crew-Verwaltung des Törns und unter "Mehr → Meine Zahlungsdaten" für den Nutzer selbst; nur lokal gespeichert.
- QR-Code und Links verwenden immer die Daten des jeweiligen **Empfängers**. Fehlen sie: Hinweis "Für Anna sind keine Zahlungsdaten hinterlegt" mit "Jetzt eintragen".
- Test: Kein IBAN-Literal im Code außerhalb von Tests (Suchtest im Testlauf).

## Technik

- `android/app/build.gradle`: `compileSdk = 35`, `ndkVersion = "26.1.10909125"` (Warnungen beim Build)
- Hinweis zum Prozess: Nach dem Push von S8a lag lokal eine unkommittete, fehlerhafte Änderung an `lib/core/config/feature_flags.dart`, die den Build brach. **Nach jedem Slice muss `git status` sauber sein**; nichts nach dem Push weiter ändern, ohne erneut zu committen.

## Vorgemerkt für v1.1

- Etappen mit Crewwechsel für lange Törns
