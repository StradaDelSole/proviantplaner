# Startprompt für eine Gemini-Sitzung v0.1

Stand: 23.09.2026 · Vor jeder Sitzung: `git pull`. Pro Slice eine neue Sitzung.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |

## Startprompt (Slice-Nummer anpassen)

```
Lies zuerst GEMINI.md vollständig und halte dich strikt daran.
Lies dann README.md und in der Slice-Datei mit der höchsten Versionsnummer (docs/SLICES_vX.Y.md) die technischen Leitplanken und den Abschnitt zu Slice S0.
Bearbeite ausschließlich S0. Lies weitere Dateien nur, wenn S0 sie wirklich braucht.

Bevor du Code schreibst:
1. Fasse die Abnahmekriterien von S0 in eigenen Worten zusammen.
2. Lege einen Plan vor: betroffene Dateien, benötigte Pakete, Vorgehen, wie du jedes Abnahmekriterium prüfst.
3. Nenne alles, was im PRD oder Slice-Plan unklar ist, als Frage.
Warte dann auf mein "OK".

Nach der Umsetzung: flutter analyze und flutter test ausführen, CHANGELOG.md ergänzen und den Abschlussbericht im Format aus GEMINI.md liefern. Nicht committen, nicht pushen.
```

## Folgeprompts

- **Freigabe:** `OK, setze den Plan um.`
- **Fehler gesammelt melden:** `flutter analyze meldet folgende Fehler: <einfügen>. Behebe sie, ohne Tests abzuschwächen, und berichte erneut.`
- **Abweichung stoppen:** `Das gehört nicht zu S<Nr>. Mach es rückgängig und bleib im Umfang des Slices.`
