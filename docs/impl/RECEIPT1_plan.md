# RECEIPT1 – Expense Receipts & Settlement Package – Implementierungsrahmen

Stand: 05.10.2026  
Grundlage: `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`  
Status: **OWNER-ACCEPTED / verpflichtender zukünftiger Slice, noch NICHT freigegeben**

## Ziel

Belegfotos offline an Expenses hängen und am Törnende ein transparentes Versandpaket aus Abrechnung + Belegen erzeugen.

## Reconciliation vor Start

Vor Implementierung:
- aktuelles Expense-/Kitty-/Settlement-Modell lesen
- Drift-Migrationen prüfen
- aktuellen PDF-/Share-Export prüfen
- B2 Backup-/Restore-Format prüfen
- vorhandene Kamera/File-Picker-Abhängigkeiten prüfen
- keine bestehende Settlement-Logik unnötig ersetzen

## Pflicht-Scope

### A. Expense-Attachments
- lokale Attachment-Entität mit stabiler Expense-Referenz
- 0..n Belegbilder pro Expense
- offline create/read/delete
- kontrollierte Dateilebensdauer
- Migration ohne Datenverlust

### B. Capture UX
- `Beleg fotografieren` direkt im Expense-Flow
- Vorschau
- weitere Seite hinzufügen
- neu aufnehmen/entfernen
- Beleg optional, niemals Settlement-Blocker

### C. Bildpipeline
- lokal
- lesbare Kompression/Downscale
- EXIF/Location-Metadaten entfernen
- keine OCR-Pflicht

### D. Settlement correctness
- bestehende Regeln beibehalten
- explizit testen: Saldo = für Gruppe bezahlt − eigener Kostenanteil
- mehrere Zahler über mehrere Expenses
- Kategorien/Beteiligungen/Skipper-frei bleiben korrekt

### E. Settlement Package
- `Abrechnung.pdf`
- `Belege.pdf` mit Expense-Zuordnung
- automatische Aufteilung großer Belegsammlung
- kein stilles Weglassen

### F. Share / Mail
- nativer Share-/Mail-Composer
- vorbereiteter Betreff/Text
- Abrechnung + alle Beleg-PDFs angehängt
- kein eigenes Mailbackend
- Generierung offline möglich

### G. Backup / Restore
- Belege in bestehende Backup-Semantik integrieren
- Restore-Test mit mindestens einer Expense + mehreren Belegbildern

### H. Theme / Accessibility
- Light
- Dark
- Nightwatch/Rotlicht
- Vorschau und Aktionen verständlich
- kein Status ausschließlich über Farbe

## Nicht in RECEIPT1

- OCR / automatische Betragslesung
- automatische Kategorisierung
- Guest-Upload von Belegen
- eigenes SMTP-/Mailbackend
- Steuer-/Buchhaltungssoftware
- Händler-/Bankintegration

## DoD

- Flutter analyze grün
- vollständige relevante Flutter-Tests grün
- Drift-Migrationstest
- Attachment-Lifecycle-Test
- Settlement-Regressionen
- PDF-Tests
- Backup/Restore-Test
- Offline-Test
- manueller echter Kamera-/Share-Test im Bericht klar als menschlicher Test gekennzeichnet
- README/CHANGELOG aktualisiert
- Implementierungsbericht
- Commit/Push
- STOP für Owner-Review
