# PIVOT2 UX Benchmark Pass – 17.10.2026

Status: **COMPLETED / PIVOT2 IMPLEMENTATION BASELINE**  
Reference: `docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md`  
Scope: Provisioning Review Surface & Vorräte Interaction Layer (PIVOT2 / Issue #26)

---

## 1. Einordnung & Leitplanken

Gemäß der owner-accepted UX Benchmark Strategy (`docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md`) wird vor der Implementierung der neuen PIVOT2-Review-Surface ein dokumentierter UX Benchmark Pass durchgeführt.

### North Stars & Leitplanken:
- **Instacart** als primärer Shopping-/List-Context-Benchmark (Informationsdichte, Zeilenaufbau, Warnhinweise, Contextual Hints, Handoff in bestehende Edit-/Search-Flows).
- **Material 3** als technische Komponenten- und Accessibility-Basis (Touch Targets >= 48dp, Farbkontraste, semantische Struktur, Color nicht alleiniger Zustandsträger).
- **Provy Frozen IA**: Die eingefrorene Informationsarchitektur (`docs/design/PROVY_UX_DIRECTION_v0.5.md`, `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`, `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`) bleibt eine strikte Obergrenze. Es wird keine neue Top-Level-Navigation oder globale Dashboard-Überladung eingeführt.
- **Provy Design System**: Off-White / Navy (Light), Dark Mode und Nightwatch (Rotlichtmodus) bleiben verbindlich. Kein Pixel-Kopieren fremder Markenmerkmale.

---

## 2. Detaillierte Klassifikation der PIVOT2-Muster

| Surface / Interaktions-Muster | Aktueller Zustand / Plan | Benchmark-Referenz | Analyse & Begründung | Klassifikation |
| :--- | :--- | :--- | :--- | :--- |
| **1. `Vorräte` Einstiegspunkt** | Vorratsliste unter `ShoppingListScreen` mit Suche, FAB, Popup-Menü. | **Instacart List View** / Airbnb Quiet Screen | Die Vorratsliste bleibt der Hauptort zur Bedarfs- und Vorratsplanung. Sie darf nicht durch neue permanente Banner oder Dashboards blockiert werden. | **`KEEP`** |
| **2. `Liste prüfen` CTA** | Neuer Review-Trigger in `Vorräte`. | **Instacart "Review Cart / Check Order"** | Ein gut sichtbarer, aber sekundärer Action-Button ("Liste prüfen" mit Status-Icon/Badge), der den Nutzer nicht blockiert, sondern situativ zum Audit einlädt. Keine modalen Sperren oder Zwangs-Gates. | **`ADOPT_PATTERN`** |
| **3. Review-Surface (Modal Sheet / Route)** | Öffnet eine dedizierte Review-Übersicht. | **Instacart Review / Order Issues Sheet** | Eine fokussierte, strukturierte Modal-Bottom-Sheet- oder Route-Ansicht. Bietet Übersicht über den Zustand der Liste ("Bereit", "Noch prüfen", "Aktion nötig") ohne Kontextverlust. Schließen/Verlassen ändert keinerlei Daten. | **`ADOPT_PATTERN`** |
| **4. Gruppierte Findings** | Findings nach Dringlichkeit gegliedert: Aktion nötig, Noch prüfen, Informationen. | **Instacart Item Attention Groups** | Gruppierung nach Dringlichkeit (Rot: Aktion nötig, Orange: Noch prüfen, Grau/Blau: Info). Leere Gruppen werden nicht gerendert (Vermeidung von Warning Clutter). Keine numerischen Scores/Prozentbalken. | **`ADOPT_PATTERN`** |
| **5. Kontextueller Inline-Hinweis** | Hinweis an einer betroffenen Zeile in der Vorratsliste. | **Instacart Inline Row Badges / Warnings** | Maximal **ein** höchstpriorer Hinweis pro betroffener Zeile (z. B. "Haltbarkeit beachten" oder "Kühlfach nötig"). Verhindert visuelle Überlastung der Standardzeile. | **`ADOPT_PATTERN`** |
| **6. Finding Action Handoff** | Aktion an einem Finding (z. B. "Hinzufügen", "Stopp zuweisen"). | **Instacart Contextual Actions** | Direkte Verlinkung in den bestehenden Such- oder Zuweisungs-Flow. Der Review mutiert die Daten nicht selbst, sondern übergibt den Kontext an die bestehende UI. | **`ADOPT_PATTERN`** |
| **7. Gamification / Prozent-Score** | Hypothetischer Vorrats-Score (z. B. "85% bordtauglich"). | Verstoß gegen Provy-Philosophie | Auf See existiert kein "85% fertig". Entweder fehlen essenzielle Dinge oder es gibt Unstimmigkeiten, oder die Liste ist geprüft. Scores führen zu falscher Scheinsicherheit. | **`REMOVE`** |
| **8. Automatische Korrektur / Auto-Add** | Hypothetischer "Fehlendes automatisch ergänzen"-Button. | Verstoß gegen "Skipper baut die Liste" | Provy darf niemals eigenmächtig Artikel auf die Liste setzen oder Stopps umverteilen. Alle Anpassungen bleiben bewusste Skipper-Entscheidungen. | **`REMOVE`** |
| **9. Neuer Top-Level-Navigationspunkt** | Eigener Tab "Review" in der Hauptnavigation. | Verstoß gegen Frozen IA | Würde die stabile 4-Tile-Hub-Architektur verwässern. Review gehört logisch als Werkzeug in den Bereich `Vorräte`. | **`REMOVE`** |

---

## 3. UI-Spezifikation für PIVOT2

### 3.1 Einstieg `Liste prüfen` in `ShoppingListScreen`
- In der App-Bar oder über der Sortier-Leiste als dezenter, kompakter Status-Chip / Button:
  - Icon: Status-Icon (Häkchen grün / Warning orange / Error rot).
  - Text: "Liste prüfen" / "Review".
  - Tap öffnet das `ProvisioningReviewSheet`.

### 3.2 `ProvisioningReviewSheet`
- **Header**: Gesamtstatus-Zusammenfassung (`Bereit`, `Noch prüfen` oder `Aktion nötig`) mit erklärendem Subtitel.
- **Sektionen** (strikt in Reihenfolge, leere Sektionen ausgeblendet):
  1. `Aktion nötig` (z. B. fehlendes Kühlaggregat bei Kühlware).
  2. `Noch prüfen` (z. B. Mindest-Trinkwasser-Abgleich, fehlende Grundausstattung, Haltbarkeit/Frische).
  3. `Informationen` (z. B. Gesamtgewicht, Gesamtvolumen).
- **Finding-Karten**:
  - Icon mit semantischer Farbe (Rot / Orange / Grau-Blau).
  - Klarer, knapper Titel und neutrale Erklärung (kein Befehlston, keine Bevormundung).
  - Konkreter Kontext (z. B. berechnetes Mindest-Trinkwasser vs. gewählte Menge, mit Tank-/Watermaker-Hinweis).
  - Kontextueller Aktions-Button: Springt direkt in die Suche (z. B. für Speiseöl) oder öffnet die Stopp-Zuweisung.

### 3.3 Inline Hint in `ShoppingListItemRow`
- Unterhalb der Mengen- und Packungszeile (sofern ein Finding für diesen Artikel existiert).
- Nur das höchstpriorisierte Finding anzeigen:
  - `ACTION_NEEDED` > `CHECK` > `INFO`.
- Kompakt, dezent gefärbt, mit Icon.

