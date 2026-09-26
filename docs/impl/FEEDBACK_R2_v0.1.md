# Feedback-Runde 2 v0.1 – ENTWURF

> **Entwurf, noch nicht freigegeben.** Gemini setzt diese Punkte erst um, wenn sie im README freigegeben sind. Wird nach dem Test der Feedback-Runde 1 ergänzt.

Stand: 26.09.2026 · Quelle: Praxistest durch den Product Owner

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 26.09.2026 | Entwurf: Navigation entlang des Törn-Ablaufs, sichtbare Hauptaktionen |

## 1. Navigation entlang des Törn-Ablaufs

Der Nutzer denkt in einem einfachen Ablauf:

**Törn anlegen → Liste erstellen → Einkaufen (ein oder mehrere Stopps) → Törn abschließen und abrechnen**

Die App bildet diesen Weg direkt ab, statt ihn auf Reiter und Menüs zu verteilen.

- **Törn-Startbildschirm = der Ablauf** als vier große Schritte untereinander:
  1. **Liste erstellen** – Status (z. B. "34 Positionen"), Button "Liste bearbeiten"
  2. **Einkaufen** – ein Eintrag je Einkaufsstopp (z. B. "Tag 1 Basis · 18 Posten") mit "Einkauf starten"; danach optional "Einlagern"
  3. **Unterwegs** – Kassenstand, Button "Ausgabe erfassen"
  4. **Abschließen und abrechnen** – Button "Abrechnung starten"
- Der nächste sinnvolle Schritt ist hervorgehoben, erledigte Schritte tragen ein Häkchen.
- Die App schlägt vor, sperrt aber nichts: jeder Schritt jederzeit erreichbar, auch zurück.
- **"Ausgabe erfassen" ist immer mit einem Tipp erreichbar** (z. B. als Hauptbutton), weil es unterwegs ständig gebraucht wird.
- Tagesleiste, Einkaufsstopps verwalten und Törn-Einstellungen als kleinere Einträge auf diesem Bildschirm.
- Die vier Reiter (Liste, Törn, Bordkasse, Mehr) entfallen weitgehend; "Mehr" bleibt als Symbol in der Kopfzeile.

## 2. Hauptaktionen sichtbar, nie im Drei-Punkte-Menü

**Regel für die ganze App:** Jede Aktion, die in einem normalen Törn mindestens einmal gebraucht wird, ist direkt sichtbar. Das Drei-Punkte-Menü enthält nur Seltenes (Umbenennen, Duplizieren, Archivieren, Löschen).

In der Liste:
- **"Einkauf starten · <Stopp>"** als gut sichtbarer Button unten
- **"+ Position hinzufügen"** als Hauptbutton unten rechts: öffnet die Katalogsuche; bei keinem Treffer direkt "Als eigene Position anlegen"
- **"Alle Vorschläge übernehmen"** sichtbar oben in der (leeren) Liste
- **Suche und Sortierung** als Symbole in der Kopfzeile

## Offen / wird ergänzt

- Weitere Punkte aus dem Test nach Feedback-Runde 1
- Danach: Design-Brief und Slice-Plan anpassen, Freigabe im README
