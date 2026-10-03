# Future Slices v0.1 – TC1 & GB1

Stand: 04.10.2026
Status: Owner-accepted backlog; verpflichtend vor Umsetzung jeweils gegen aktuellen Repo-Stand reconciliieren.

## TC1 – Törnkosten & Bordkassen-Zusammenfassung

### Ziel
Die bereits vorhandenen Cost-Share-Fähigkeiten für Diesel und Hafen/Liegeplatz als vollständige variable Törnkosten-Funktion sichtbar und rund machen.

### Scope
- bestehende Fuel-Kategorie beibehalten;
- bestehende Marina/Liegeplatz-Kategorie beibehalten;
- Marina-Nebenkosten explizit erfassbar machen;
- Kategorie-/Gesamtsummen;
- informative Pro-Kopf-Ansicht ohne Settlement-Semantik zu verändern;
- optionales Belegfoto pro Ausgabe;
- korrektes Lifecycle-/Backup-Verhalten der Belege;
- bestehende Custom Splits, Skipper-frei-Profile, Kassenwart und beide Kassenmodelle unverändert weiter unterstützen;
- Mehrwährungsfall korrekt behandeln, niemals Beträge unterschiedlicher Währungen naiv addieren.

### Nicht Scope
- eigene Zahlungsabwicklung;
- Bankkonten/Wallets führen;
- automatische OCR von Belegen;
- automatische Wechselkurse ohne separate Entscheidung;
- neue B2B-Funktionen.

### Abnahme
1. Diesel 186 €, 6 Beteiligte → korrekte Cost Shares.
2. Marina 92 €, 6 Beteiligte → korrekte Cost Shares.
3. Benutzerdefinierte Beteiligung (eine Person ausgeschlossen) bleibt korrekt.
4. Kategorietotale entsprechen Expenses.
5. Törnkosten-Summary zeigt korrekte Summen.
6. Settlement-Saldo bleibt exakt null in Cent.
7. Belegfoto add/show/replace/remove.
8. Ausgabe löschen räumt zugehörige lokale Belegdatei auf.
9. Offline-Test.
10. vollständige Regression der bestehenden Bordkassen-Tests.
11. Eine Ausgabe kann mehrere Zahler enthalten; Summe der Zahlungsteile = Ausgabenbetrag.
12. Minimierte finale Transfers liefern dasselbe Netto-Ergebnis wie die zugrunde liegenden Salden.
13. Jeder offene Transfer erzeugt QR/Payment-Aktion für den tatsächlichen Empfänger und exakten Restbetrag.
14. Bezahlt-Status ist persistent; optionaler Teilzahlungsstatus darf keine Doppelzahlung ermöglichen.
15. Einkauf/Lieferung kann nach Bestätigung als vorausgefüllte Bordkassen-Ausgabe übernommen werden; nie automatisch.
16. Optionales Budget vs. Ist beeinflusst Settlement nicht.
17. Smarter Nachschuss ist nur Vorschlag und benötigt Nutzerbestätigung.
18. Törnabschluss erzeugt einen stabilen Abschluss-Snapshot; Änderungen danach nur über explizites Wiederöffnen.
19. Export enthält Kategorie-Summen, persönliche Kostenanteile und finalen Transferstatus.

## GB1 – Grab Bag / Departure Readiness

### Ziel
Eine konfigurierbare, nicht-autoritativ formulierte Grab-Bag-Checkliste in den bestehenden Törnablauf integrieren.

### Datenmodell
Mindestens:
- Grab-Bag-Checkliste pro Trip oder äquivalente klare Relation;
- Item: stabile ID, Bereich, Label, optional Hinweis, checked, custom/default, optional check/expiry date;
- optionaler Aufbewahrungsort;
- Bestätigung „Aufbewahrungsort bekannt/geprüft“.

Migration muss bestehende Törns ohne Grab Bag unverändert öffnen.

### Default-Bereiche
- Dokumente/Kopien
- Notfallkommunikation
- Licht/Energie
- Notwasser
- Notverpflegung
- Erste Hilfe/persönliche Medikamente
- Wärme/Wetterschutz
- Signalmittel
- Messer/Multitool
- persönliche notwendige Gegenstände
- sonstige crew-/bootsspezifische Punkte

### UX
- keine neue Hauptnavigation;
- Karte in Törn-Übersicht: „Grab Bag · X/Y bereit“;
- Aktion „Prüfen“;
- Detail als Vollbild-Sheet oder max. eine Navigationsebene;
- CRUD für eigene Punkte;
- Ablauf-/Prüfhinweise;
- Aufbewahrungsort sichtbar.

### Safety Copy
Verbindlich sinngemäß:
„Die passende Sicherheitsausrüstung hängt von Boot, Fahrtgebiet, Crew, Wetter und gesetzlichen Vorgaben ab. Diese Checkliste hilft beim Prüfen und Erinnern und ersetzt keine professionelle oder rechtliche Sicherheitsplanung.“

### Mengenhinweise
Optional datengetriebene, neutral formulierte Planungshinweise für Notwasser/Notverpflegung aus Crewgröße + vom Nutzer gewählter Dauer. Keine Compliance-/Mindestmengen-Behauptung.

### Abnahme
1. Default-Checkliste wird pro Törn erzeugt.
2. Fortschritt X/Y korrekt.
3. Check/uncheck persistent.
4. eigene Punkte CRUD.
5. Prüf-/Ablaufdatum persistent und sichtbar.
6. Aufbewahrungsort persistent.
7. Trip Overview Status aktualisiert reaktiv.
8. komplett offline.
9. Backup/Restore strukturierten Daten.
10. keine Safety-/Compliance-Überversprechen in sichtbaren Strings.
11. Widget-/Unit-/Migrationstests grün.
12. bestehende Navigation bleibt ohne zusätzlichen Haupttab.

## Reihenfolge

Diese Slices werden **nicht in FB2-B hineingezogen**.

Vor Start von TC1/GB1:
- aktuellen main ziehen;
- internes Testfeedback berücksichtigen;
- PRD/Slice-Rebaseline erstellen;
- erst dann einzeln implementieren.

Empfehlung:
**TC1 vor GB1**.


## TC2 – Crewwechsel / zeitabhängige Beteiligung (später)

Nicht Teil von TC1.

Ziel:
Bei langen Törns mit wechselnder Crew können Ausgaben automatisch nur auf die zum Ausgaben-/Leistungszeitraum beteiligten Personen verteilt werden.

Vor Umsetzung separat entscheiden:
- Teilnahmeintervalle pro Crewmitglied;
- Zuordnung einer Ausgabe zu Tag/Zeitraum;
- Verhalten bei pauschalen Törnkosten;
- Migration bestehender Crew-Daten.

TC2 darf TC1 und die erste reale Testphase nicht verzögern.
