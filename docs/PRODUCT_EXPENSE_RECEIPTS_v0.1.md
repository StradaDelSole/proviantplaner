# Provy Expense Receipts & Settlement Package v0.1

Stand: 05.10.2026  
Status: **OWNER-ACCEPTED / verbindliche Produktentscheidung**

## 1. Ziel

Belege werden direkt an Bordkassen-Ausgaben dokumentiert und am Törnende zusammen mit der Endabrechnung versendet.

Leitprinzip:

> Ausgabe erfassen, Beleg fotografieren, am Ende transparent abrechnen.

Die Funktion bleibt bewusst einfach. Guest Shopping wird dadurch **nicht** zu einem Finanzworkflow.

## 2. Grundmodell

Eine Ausgabe bleibt eine normale `Expense`.

Verbindliche Kerndaten:
- Betrag
- Währung
- bezahlt von
- bestehende Kategorie/Beteiligungslogik
- optionale Beschreibung
- optional ein oder mehrere Belegfotos

Der Beleg ist Nachweis zur Ausgabe, **nicht** Quelle der Berechnung.

Kein OCR ist für v1 erforderlich. Betrag, Währung und Zahler werden bewusst und zuverlässig vom Nutzer bestätigt.

## 3. Wer bezahlt hat

Provy nimmt nie an, dass die Person, die einkauft, auch bezahlt hat.

Bei einer Ausgabe wird ausdrücklich `bezahlt von` erfasst.

Es gibt **keine angenommene „Bordkassenkarte“**.

Typische Fälle:
- Skipper bezahlt mit eigener Karte
- Crewmitglied bezahlt mit eigener Karte
- Kassenwart bezahlt mit eigener Karte
- falls tatsächlich eine gemeinsame Bargeld-Bordkasse verwendet wird, kann die bestehende Bordkassenlogik dies weiterhin abbilden

Guest Shopper, Crew Member und Zahler sind getrennte Konzepte.

## 4. Settlement-Regel

Alle bestätigten Ausgaben gehen in die vorhandene Kostenteilung ein.

Grundprinzip pro Person:

`Saldo = für die Gruppe bezahlt − eigener Kostenanteil`

- positiver Saldo → Person bekommt Geld
- negativer Saldo → Person muss noch zahlen
- null → ausgeglichen

Der eigene Kostenanteil berücksichtigt weiterhin die bestehenden Regeln, z. B.:
- Beteiligung je Kategorie
- abweichende Aufteilung
- Skipper-frei-Regeln
- Rundung

Beispiel:

Gesamtausgaben: 1.000 EUR, vier Personen mit gleichem Anteil = 250 EUR pro Person.

- Gary bezahlt 400 EUR → +150 EUR
- Anna bezahlt 100 EUR → −150 EUR
- Tom bezahlt 300 EUR → +50 EUR
- Lisa bezahlt 200 EUR → −50 EUR

Die Settlement-Engine reduziert dies wie bisher auf möglichst wenige Ausgleichszahlungen.

## 5. UX beim Erfassen einer Ausgabe

Primärfelder bleiben kompakt.

Beispiel:

> Ausgabe  
> Betrag: 86,40 EUR  
> Bezahlt von: Gary  
> Kategorie: Proviant  
> Beschreibung: Supermarkt Hvar  
> **[ Beleg fotografieren ]**  
> [ Ausgabe speichern ]

Der Beleg ist optional. Fehlender Beleg darf eine Ausgabe oder die Endabrechnung nicht blockieren.

Nach Aufnahme:
- kleine Vorschau
- `Neu aufnehmen`
- `Weitere Seite` / weiterer Beleg
- `Entfernen`

Mehrseitige/lange Belege dürfen mehrere Fotos besitzen.

## 6. Offline-first

Belegaufnahme und Zuordnung zur Ausgabe müssen vollständig ohne Internet funktionieren.

- Fotos werden lokal gespeichert
- Zuordnung zur Expense liegt lokal
- App-Neustart verliert keine Belege
- Dateiverarbeitung/Kompression erfolgt lokal
- für Mail-/PDF-Erstellung ist zunächst ebenfalls kein Internet erforderlich

Nur das tatsächliche Versenden einer E-Mail benötigt später eine Verbindung.

## 7. Bildverarbeitung

Belegfotos werden für Lesbarkeit und vernünftige Dateigröße optimiert.

Verbindlich:
- ausreichende Auflösung für lesbaren Text
- keine aggressive Kompression, die Belege unlesbar macht
- unnötige EXIF-/Standortmetadaten entfernen
- Originalkamera-Datei muss nicht dauerhaft zusätzlich gespeichert werden, wenn die optimierte Version lesbar und zuverlässig ist

Keine automatische OCR-/Buchungslogik in v1.

## 8. Backup / Restore

Wenn der Nutzer Cloud-Backup verwendet, gehören Belegdateien logisch zum Törn und müssen mitgesichert bzw. wiederhergestellt werden.

Eine Wiederherstellung darf nicht zu einer Endabrechnung ohne die zuvor gesicherten Belege führen.

Die konkrete Archiv-/R2-Struktur wird im Implementierungsslice mit B2 reconciliiert.

## 9. Endabrechnung

Am Törnende bietet Provy eine klare Aktion:

> **[ Abrechnung senden ]**

Provy erzeugt lokal mindestens:

1. `Abrechnung.pdf`
   - Törnidentität
   - Gesamtausgaben
   - nachvollziehbare Kostenanteile
   - pro Person: bezahlt / eigener Anteil / Saldo
   - minimale Ausgleichszahlungen

2. `Belege.pdf`
   - alle vorhandenen Belege des Törns
   - nachvollziehbar der jeweiligen Ausgabe zugeordnet
   - je Beleg mindestens: Datum/Expense-Kontext, Betrag, Währung, bezahlt von, Kategorie/Beschreibung soweit vorhanden
   - mehrere Fotos derselben Ausgabe bleiben zusammen

Das Ziel ist Transparenz: Jedes Crewmitglied kann die Endabrechnung anhand der Belege nachvollziehen.

## 10. Große Belegsammlungen

Default ist ein gemeinsames `Belege.pdf`.

Wird das Dokument für typische Mail-/Share-Grenzen zu groß:
- automatisch in nummerierte Dateien teilen, z. B. `Belege_1.pdf`, `Belege_2.pdf`
- niemals Belege still weglassen
- verständlichen Hinweis anzeigen

Die konkrete sichere Größenstrategie wird technisch getestet und nicht als starre Annahme eines bestimmten Mailproviders modelliert.

## 11. Versand

Provy betreibt dafür **kein eigenes Mail-Backend**.

`Abrechnung senden` öffnet den nativen Mail-/Share-Composer des Geräts mit:
- vorbereitetem Betreff
- kurzem Begleittext
- `Abrechnung.pdf`
- `Belege.pdf` bzw. nummerierten Belege-PDFs

Empfänger werden vom Nutzer gewählt/eingetragen. Crew-E-Mail-Adressen werden für diese Funktion nicht verpflichtend.

Wenn aktuell keine Verbindung vorhanden ist, können die Dateien trotzdem erzeugt/gespeichert und später geteilt werden.

## 12. Guest Shopping

Guest Shopping bleibt maximal einfach.

Gast:
- sieht sein Einkaufspaket
- hakt Positionen ab
- macht **keine** Buchhaltung in der Gast-Webseite
- muss keinen Betrag, keine Währung und keinen Zahler erfassen
- muss keinen Beleg hochladen

Nach Rückkehr:
1. Crewmitglied zeigt den Beleg.
2. Owner erfasst/öffnet die Expense.
3. Betrag, Währung und `bezahlt von` werden eingetragen.
4. Beleg wird fotografiert.
5. Expense fließt normal in die Endabrechnung ein.

Damit bleibt Guest Shopping unabhängig von Finance.

## 13. Datenschutz

Belege können sensible Zahlungs-/Ortsinformationen enthalten.

Deshalb:
- lokal/offline first
- keine automatische Analyse
- keine Marketingauswertung
- Cloud-Sicherung nur im Rahmen der vorhandenen Nutzer-Backup-Funktion
- E-Mail/Share nur durch explizite Nutzeraktion
- EXIF-/Standortmetadaten entfernen

## 14. Akzeptanzkriterien

Das Feature gilt erst als fertig, wenn mindestens:

1. Eine Expense kann offline mit einem Belegfoto gespeichert werden.
2. Mehrere Belegfotos können derselben Expense zugeordnet werden.
3. Bearbeiten der Expense erhält die Belegzuordnung.
4. Löschen behandelt zugehörige Dateien kontrolliert.
5. Betrag/Währung/Zahler bleiben manuelle, klare Expense-Felder; kein OCR-Zwang.
6. Settlement berücksichtigt korrekt, wie viel jede Person für die Gruppe bezahlt hat gegenüber ihrem eigenen Anteil.
7. Guest Shopping enthält keine Finanzpflichtfelder.
8. `Abrechnung.pdf` wird lokal erzeugt.
9. `Belege.pdf` enthält alle vorhandenen Belege und deren Expense-Zuordnung.
10. Große Belegsammlungen werden geteilt statt gekürzt/verloren.
11. Mail-/Share-Composer erhält Abrechnung + Beleganhänge.
12. Erstellung funktioniert offline; tatsächlicher Versand kann später erfolgen.
13. Backup/Restore erhält Belege bei aktivierter Cloud-Sicherung.
14. Light, Dark und Nightwatch unterstützen Belegaufnahme/-vorschau ohne Informationsverlust.

## 15. Umsetzung

Das Feature wird als eigener verpflichtender Slice **RECEIPT1 – Expense Receipts & Settlement Package** geführt.

RECEIPT1 muss vor Store-v1-Abnahme abgeschlossen sein.

Es verändert nicht die Guest-Shopping-Architektur und benötigt kein neues Mail-Backend.
