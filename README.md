# Proviantplaner (Arbeitstitel) – powered by HullQ

Mobile App (Flutter, iOS und Android) für die Proviant- und Bordkassenplanung auf Segeltörns. Eigenständige App ohne Bootsinhalte; die Mitglied-Version wird über ein HullQ-Konto freigeschaltet.

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `docs/PRD_v0.15.md` | Produktanforderungen, Quelle der Wahrheit |
| `docs/SLICES_v0.8.md` | Umsetzungsplan in Slices mit Abnahmekriterien |
| `docs/KATALOG_v0.6.md` | Vorratskatalog, lesbar |
| `data/catalog_v0.6.json` | Vorratskatalog, maschinenlesbar |
| `data/quantities_v0.3.json` | Mengen, Konsumprofile, Faktoren |
| `docs/design/DESIGN_BRIEF_v0.1.md` | Stilrichtung, Stitch-Prompts, Animationshinweise |
| `docs/design/mockups/` | Mockups der Kernbildschirme |
| `docs/PROMPT_SESSION_START_v0.2.md` | Startprompt und Folgeprompts für jede Gemini-Sitzung |
| `docs/impl/` | Pläne und Berichte von Gemini je Slice |
| `GEMINI.md` | Arbeitsanleitung für die Umsetzung mit Gemini |
| `CHANGELOG.md` | Fortschritt pro Slice |

## Versionierung der Dokumente

Jede neue Fassung eines Dokuments wird als neue Datei mit Versionsnummer im Namen abgelegt (z. B. `PRD_v0.8.md`). Ältere Fassungen bleiben im Repo. Das Arbeitsdokument für das Konzept liegt als Claude-Doc "Proviantplaner_PRD".

## Status

Konzeptphase läuft (PRD v0.15). Es gilt jeweils die höchste Versionsnummer.

**Freigegeben für Gemini: S0 bis S6.** Mengen und Oberfläche vorläufig. S1 und folgende erst nach Freigabe hier.
