# Proviantplaner (Arbeitstitel) – powered by HullQ

Mobile App (Flutter, iOS und Android) für die Proviant- und Bordkassenplanung auf Segeltörns. Eigenständige App ohne Bootsinhalte; die Mitglied-Version wird über ein HullQ-Konto freigeschaltet.

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `docs/PRD_v0.16.md` | Produktanforderungen, Quelle der Wahrheit |
| `docs/SLICES_v0.14.md` | Umsetzungsplan in Slices mit Abnahmekriterien |
| `docs/KATALOG_v0.7.md` | Vorratskatalog, lesbar |
| `data/catalog_v0.8.json` | Vorratskatalog, maschinenlesbar |
| `data/quantities_v0.4.json` | Mengen, Konsumprofile, Faktoren |
| `docs/design/DESIGN_BRIEF_v0.4.md` | Stilrichtung, Stitch-Prompts, Animationshinweise |
| `docs/design/mockups/` | Mockups der Kernbildschirme |
| `docs/PROMPT_SESSION_START_v0.2.md` | Startprompt und Folgeprompts für jede Gemini-Sitzung |
| `docs/impl/` | Pläne und Berichte von Gemini je Slice |
| `GEMINI.md` | Arbeitsanleitung für die Umsetzung mit Gemini |
| `CHANGELOG.md` | Fortschritt pro Slice |

## Versionierung der Dokumente

Jede neue Fassung eines Dokuments wird als neue Datei mit Versionsnummer im Namen abgelegt (z. B. `PRD_v0.8.md`). Ältere Fassungen bleiben im Repo. Das Arbeitsdokument für das Konzept liegt als Claude-Doc "Proviantplaner_PRD".

## Status

Konzeptphase läuft (PRD v0.16). Es gilt jeweils die höchste Versionsnummer.
Umgesetzt: S0, S1, S2, S2a, S-UI, S3, S4, S5, S5a, S6, S7, S8, S8a.

**Freigegeben für Gemini: nur S8a (Nachbesserung, Vorrang – abgeschlossen).** Umgesetzt: S0–S8, S2a, S5a, S-UI, S8a. S9 und S10 noch nicht freigegeben. Offen: manueller QR-Scan und PDF-Viewer-Test durch den Menschen (siehe docs/impl/REVIEW_S5a-S8_v0.1.md).
