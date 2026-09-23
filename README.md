# Proviantplaner (Arbeitstitel) – powered by HullQ

Mobile App (Flutter, iOS und Android) für die Proviant- und Bordkassenplanung auf Segeltörns. Eigenständige App ohne Bootsinhalte; die Mitglied-Version wird über ein HullQ-Konto freigeschaltet.

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `docs/PRD_v0.12.md` | Produktanforderungen, Quelle der Wahrheit |
| `docs/SLICES_v0.5.md` | Umsetzungsplan in Slices mit Abnahmekriterien |
| `docs/KATALOG_v0.4.md` | Vorratskatalog, lesbar |
| `data/catalog_v0.4.json` | Vorratskatalog, maschinenlesbar |
| `data/quantities_v0.3.json` | Mengen, Konsumprofile, Faktoren |
| `GEMINI.md` | Arbeitsanleitung für die Umsetzung mit Gemini |
| `CHANGELOG.md` | Fortschritt pro Slice |

## Versionierung der Dokumente

Jede neue Fassung eines Dokuments wird als neue Datei mit Versionsnummer im Namen abgelegt (z. B. `PRD_v0.8.md`). Ältere Fassungen bleiben im Repo. Das Arbeitsdokument für das Konzept liegt als Claude-Doc "Proviantplaner_PRD".

## Status

Konzeptphase läuft (PRD v0.12). Ältere Versionen der Dokumente bleiben im Repo; es gilt jeweils die höchste Versionsnummer. Nächster Konzeptschritt: Baseline der Mengen.
