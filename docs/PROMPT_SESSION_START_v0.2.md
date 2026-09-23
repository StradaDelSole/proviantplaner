# Startprompt für eine Gemini-Sitzung v0.2

Stand: 23.09.2026 · Vor jeder Sitzung: `git pull`. Pro Slice eine neue Sitzung.

| Version | Datum | Änderung |
| --- | --- | --- |
| v0.1 | 23.09.2026 | Erstfassung |
| v0.2 | 23.09.2026 | Durchlauf-Modus: alle freigegebenen Slices nacheinander |

## Startprompt Durchlauf-Modus

```
Lies zuerst GEMINI.md vollständig und halte dich strikt daran, insbesondere an den Durchlauf-Modus, "Darf nicht" und die Stoppregeln.
Lies dann README.md und in der Slice-Datei mit der höchsten Versionsnummer (docs/SLICES_vX.Y.md) die technischen Leitplanken.
Arbeite alle im README freigegebenen Slices der Reihe nach ab, beginnend mit dem ersten noch nicht umgesetzten.
Pro Slice: Plan in docs/impl/S<Nr>_plan.md, umsetzen, flutter analyze und flutter test, CHANGELOG ergänzen, Bericht in docs/impl/S<Nr>_bericht.md, bei Grün committen, git pull --rebase und auf main pushen, dann weiter.
Wenn eine Stoppregel greift: anhalten und berichten.
```

## Folgeprompts

- **Freigabe:** `OK, setze den Plan um.`
- **Fehler gesammelt melden:** `flutter analyze meldet folgende Fehler: <einfügen>. Behebe sie, ohne Tests abzuschwächen, und berichte erneut.`
- **Abweichung stoppen:** `Das gehört nicht zu S<Nr>. Mach es rückgängig und bleib im Umfang des Slices.`
