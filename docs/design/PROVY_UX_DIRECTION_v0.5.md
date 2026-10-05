# Provy UX Direction v0.5

Stand: 05.10.2026  
Status: **OWNER-ACCEPTED / verbindliche Design-Grundlage, Detailausarbeitung läuft**

Version v0.5 integriert zusätzlich die owner-accepted Beleg-/Settlement-Entscheidung und die amendierten Wireframes aus `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`.

Die UX-Detailrunde ist damit **abgeschlossen und eingefroren**.

Bei Widerspruch zwischen älteren UX-Dokumenten und diesem Decision Set gilt **v0.3 + Decision Set**.

Dieses Dokument ergänzt und präzisiert die bestehende UX-Konzeption. Es ersetzt noch nicht vollständig `UX_KONZEPT_v0.6.md`; bei neuen oder überarbeiteten Oberflächen haben die hier ausdrücklich owner-accepted Prinzipien jedoch Vorrang. Nach Abschluss der laufenden Detaildiskussion wird daraus die nächste vollständige UX-Konzeptversion abgeleitet.

## 1. Produktgefühl

Provy soll sich nicht wie ein Feature-Dashboard oder eine typische SaaS-App anfühlen, sondern wie ein hochwertiges, professionelles Bordwerkzeug.

Prioritäten:

1. **Low friction**
2. **Einfachheit**
3. **Professioneller Eindruck**
4. **Funktionaler Eindruck**
5. **Psychologische Klarheit und Vertrauen**

Designziel:

> Der Nutzer versteht innerhalb von Sekunden, wo er ist, was relevant ist und was er als Nächstes tun kann.

Nach wenigen Benutzungen soll Provy räumlich und funktional so vertraut sein, dass zentrale Abläufe nahezu ohne Nachdenken funktionieren.

## 2. Psychologische Prinzipien

### 2.1 Cognitive fluency
Informationen, Begriffe, Positionen und Aktionen müssen leicht entschlüsselbar und vorhersehbar sein.

### 2.2 Recognition statt Recall
Funktionen werden sichtbar und konsistent angeboten. Der Nutzer muss sich keine versteckten Menüs oder wechselnden Pfade merken.

### 2.3 Eine klare nächste Handlung
Jeder zentrale Screen hat eine sofort erkennbare primäre Aktion. Auf der Törnübersicht wird der nächste sinnvolle Schritt besonders hervorgehoben.

### 2.4 Stable spatial memory
Hauptfunktionen bleiben an stabilen Positionen. Karten dürfen ihren Status ändern, aber nicht ständig Größe oder Position wechseln.

### 2.5 Sofortige Ursache-Wirkung
Jede wichtige Aktion erhält direktes visuelles und – wo sinnvoll – haptisches Feedback.

### 2.6 Kontrolle statt Bevormundung
Provy assistiert, prüft und erklärt. Der Skipper entscheidet.

### 2.7 Kompetenzgefühl
Fortschritt wird sachlich sichtbar gemacht, z. B.:
- 24/31 eingekauft
- Einlagerung erledigt
- 3 Hinweise offen

Keine künstliche Gamification.

### 2.8 Ruhige Warnsprache
Keine unnötige Angst oder rote Alarmästhetik.

Bevorzugt:
- „Wasserreserve prüfen“
- „Vielleicht noch prüfen“
- „Aktion nötig“ nur bei tatsächlich relevanten Problemen

Nicht:
- unnötige Fehlermeldungs-/Alarmrhetorik für normale Planungsentscheidungen.

## 3. Törn als mentales Zentrum

Provy ist um den **Törn als Objekt** organisiert.

Keine Rückkehr zu einer globalen Bottom-Navigation als primärer Informationsarchitektur.

Die Törnübersicht bleibt der zentrale Hub.

### Törnidentität
Kompakt sichtbar:
- Törnname / Revier
- Datum
- **Bootsname**
- optional Bootstyp/Modell
- Crewgröße
- Törndauer

Beispiel:

> Kroatien · 12.–26. Juli  
> **SY Aurora · Bavaria 46**  
> 5 Personen · 14 Tage

Mit PIVOT3 werden diese Angaben mit gespeicherten Bootsprofilen verbunden.

## 4. Home als Launchpad

Home ist kein Mehr-Törn-Dashboard.

Standardmäßig wird **nur der aktuell relevanteste Törn** prominent gezeigt:
- laufender Törn, sonst
- zeitlich nächster relevanter Törn.

Zukünftige weitere Törns werden nicht als permanente Kartenfläche auf Home angezeigt.

Sekundär erreichbar:
- **Alle Törns**
- **+ Neuer Törn**

Prinzip:

> Home beantwortet „Was ist jetzt relevant?“. „Alle Törns“ dient der Verwaltung.

Wenn kein Törn existiert, zeigt Home nur einen klaren Empty State mit direkter Aktion zum Anlegen des ersten Törns.

## 5. Adaptive Command Center

Die Törnübersicht verwendet eine **Hybrid-Informationsarchitektur mit zurückhaltender Bento-Geometrie**.

Nicht „Bento um des Bento-Stils willen“, sondern ein funktionales Command Center.

### Ebene 1 – Kontext
Kompakte Törnidentität, keine übergroße dekorative Hero-Card.

### Ebene 2 – genau eine dominante Next Action
Beispiel:

> ALS NÄCHSTES  
> Einkauf · Marina Kaštela  
> 24 von 31 erledigt  
> [ Einkauf fortsetzen → ]

Diese Fläche beantwortet:
> Was ist jetzt wahrscheinlich die sinnvollste Aktion?

Sie sperrt keine anderen Bereiche.

### Ebene 3 – stabiles Command Grid

Owner-accepted Zielstruktur mit **vier** permanenten Hauptbereichen:

- **Vorräte**
- **Einkaufen**
- **Crew & Boot**
- **Bordkasse**

Einlagern und Abrechnung sind **keine permanenten gleichrangigen Dashboard-Kacheln**:
- Einlagern ist situative Aktion innerhalb des Einkaufs-/Provisioning-Flows.
- Abrechnung ist situative Aktion innerhalb der Bordkasse.

Einkaufsstopps gehören unter **Einkaufen**, nicht als separater Hauptbereich.

**Verbindlich:** Positionen der vier Hauptbereiche bleiben stabil. Keine dynamische Umordnung oder Größenwechsel je Phase.

Bento ist hier eine Layout-Geometrie, keine wechselnde Dashboard-Spielerei.

## 6. Task-Screens sind keine Bento-Screens

Bento/Command-Grid dient der Orientierung.

Arbeitsmodi werden radikal auf die Aufgabe reduziert.

### Provisioning
Search-first:
1. Produkt suchen
2. Variante wählen
3. Gebinde wählen
4. Anzahl wählen
5. hinzufügen

Keine unnötigen Hierarchieebenen.

### Einkaufen
- große Touch-Ziele
- klare Abteilung
- Produkt
- Gebinde/Menge
- ein Tap zum Abhaken
- Fortschritt
- Abschlussaktion

### Einlagern
Nur relevante Lager-/Einlagerungshinweise und Abschluss.

### Bordkasse
Zahlen und häufigste Aktionen im Vordergrund.

### Abrechnung
Wer zahlt wem, Zahlungsweg, erledigt – ohne Dashboard-Ablenkung.

### Belege
- Expense bleibt einfach: Betrag, Währung, bezahlt von, Kategorie/Beschreibung
- optional `Beleg fotografieren`
- mehrere Fotos für lange Belege möglich
- Guest Shopper erfasst keine Finanzdaten
- am Törnende `Abrechnung senden`: `Abrechnung.pdf` + `Belege.pdf` über nativen Mail-/Share-Composer
- Belegverarbeitung offline-first; kein OCR-Zwang und kein eigenes Mailbackend

## 7. Color Coding

Color Coding ist ausdrücklich erwünscht, aber funktional und zurückhaltend.

### Bereichsidentität
Funktionsbereiche dürfen konstante Akzentfarben erhalten, z. B. über:
- Icon-Hintergrund
- schmalen Rand
- kleinen Statusbereich
- Primary Action

Keine vollflächig bunte Kachelwelt.

### Statussemantik getrennt halten
Funktionsfarbe und Statusfarbe dürfen nicht dieselbe Bedeutung tragen.

Status:
- neutral
- Hinweis / prüfen
- Aktion nötig
- erledigt

**Farbe ist nie das einzige Signal.** Zusätzlich immer Text, Icon, Form oder Position.

Nachtwache erhält eigene kontrastarme/rote Umsetzung ohne Bedeutungsverlust.

## 8. Motion & Haptics

Animationen sind ausdrücklich Teil der Designsprache, aber als Feedback – nicht als Dekoration.

Vier Motion-Klassen:

### Press
Button/Karte reagiert sofort auf Berührung, z. B. leichte Scale-/Depth-Änderung.

### Confirm
Checkmark, Statuswechsel, dezentes Haptic.

### Transition
Räumlich nachvollziehbare Screen-/Content-Transition.

### Value change
Geänderte Zahlen dürfen kurz rollen/zählen, sofern dies die Änderung verständlicher macht.

Nicht verwenden:
- Konfetti
- permanente Bounce-Effekte
- willkürlich fliegende Karten
- lange Animationen
- Motion ohne Informationswert

`Reduce Motion` / Accessibility respektieren.

## 9. Mechanische Controls

Provy darf gezielt ein leicht mechanisches / instrumentelles Bediengefühl haben.

Bevorzugt bei diskreten numerischen Werten:
- Törndauer
- Crewgröße
- Packungsanzahl
- Literwerte
- Einkaufsstopp-Tag
- Restauranttage

### Grundmuster
Schnellbedienung:
> −   3   +

Tap auf den Wert darf ein Pickwheel öffnen.

Damit:
- Stepper für kleine Änderungen
- Pickwheel für größere Änderungen
- direkte Eingabe als Fallback

Beim Einrasten eines Pickwheels dezentes haptisches Tick-Feedback.

Pickwheels werden bewusst eingesetzt, nicht überall.

## 10. Value ohne Überladung

Neue Funktionalität wird bevorzugt **kontextuell** statt als neuer Hauptbereich ergänzt.

### Progressive Disclosure
Zuerst nur das Wesentliche. Details bei Bedarf öffnen.

### Smart Defaults
Frühere Entscheidungen können sinnvoll vorausgewählt werden, aber nie ungefragt als Wahrheit übernommen werden.

### Zuletzt verwendet / für dieses Boot üblich
Bei wiederkehrenden Törns sollen häufig verwendete Produkte oder Einstellungen schnell verfügbar sein.

### Contextual Review
Hinweise möglichst dort anzeigen, wo sie entstehen.

Beispiel:
> 30 frische Brötchen · Haltbarkeit ca. 1 Tag · später nachkaufen?

### Quick Actions
Kontextabhängig besonders häufige Aktionen mit 1–2 Taps erreichbar:
- Position hinzufügen
- Ausgabe erfassen
- Einkaufsstopp hinzufügen

Keine permanente globale Feature-Leiste erforderlich.

### Intelligent Repeat
Bei neuem Törn z. B.:
> SY Aurora zuletzt verwendet – übernehmen?

Keine unnötige separate Template-Verwaltung.

### Gute Empty States
Ein leerer Screen erklärt direkt die erste sinnvolle Handlung.

### Readiness statt Score
Kein künstlicher 0–100-Score.

Bevorzugte Zustände:
- **Bereit**
- **Noch prüfen**
- **Aktion nötig**

## 11. Situative UI ohne manuellen Modusschalter

Provy passt den Fokus an den aktuellen Kontext an:

- Planung → informationsreicher
- Einkauf → maximal reduzierte Abhakoberfläche
- Einlagerung → Lagerhinweise
- Unterwegs → schnelle Bordkassenaktionen
- Abschluss → Abrechnung im Fokus

Der Nutzer wählt keinen „Modus“. Der Workflow ergibt den Kontext.

## 12. Guest Shopping Collaboration

Mehrere Personen dürfen parallel einkaufen, ohne Provy-App-, Account- oder Lizenzpflicht für Gäste.

Verbindliche Grundlage:
`docs/PRODUCT_GUEST_SHOPPING_v0.3.md`

UX:
- Einstieg ausschließlich unter **Einkaufen**
- **Einkauf aufteilen**
- nach Abteilungen, Einkaufsort oder frei ausgewählten Positionen
- QR anzeigen
- Link teilen
- Offline teilen
- kein separates Team-/Collaboration-Dashboard
- keine Rollen-/Kanban-UX

Offline ist First-Class:
- bereits geladene Gastliste funktioniert bei Verbindungsverlust weiter und synchronisiert später
- bei komplett fehlendem Internet kann der Owner lokal ein lesbares Offline-QR-/Share-Paket erzeugen
- rein offline erledigte Pakete werden beim Owner über „Alles gekauft“ + Ausnahmen reconciliiert

Gastzugriff zeigt ausschließlich das freigegebene Einkaufspaket.

## 13. Anti-Overload-Regeln

Nicht auf das Command Center aufnehmen, nur weil die Funktion existiert:
- Wetter
- Backup
- Sprache
- PDF
- Export
- Hilfe
- Profil
- allgemeine Settings

Keine Mini-Charts oder Diagramme ohne echte Entscheidungsrelevanz.

Aktuell ausdrücklich nicht als neue Kern-UX:
- Chatbot-/AI-Screen
- Rezept-/Menügenerator
- Social Features
- Gamification
- Provy Score
- Analytics-Dashboard
- dekorative Informationskarten ohne Aktion oder Entscheidung

## 14. Qualitätsfilter für jedes neue Feature

Eine neue Funktion muss mindestens einen dieser Werte deutlich verbessern:

1. weniger Tippen
2. weniger Denken
3. weniger Vergessen
4. bessere Sicherheit/Plausibilität
5. bessere Übersicht
6. schnellere reale Aufgabe an Bord

Wenn sie hauptsächlich Oberfläche oder Erklärungsbedarf erzeugt, wird sie nicht in den Hauptflow aufgenommen.

## 15. Umsetzungsmapping

### PIVOT1
Muss bereits berücksichtigen:
- Search-first
- direkte Variante → Gebinde → Anzahl → Liste
- low friction
- progressive disclosure
- stabile, klare primäre Aktionen
- tactile feedback ohne unnötige Screens

### PIVOT2
Geeigneter Ort für:
- contextual review
- Readiness-Zustände
- ruhige, begründete Hinweise

### PIVOT3
Geeigneter Ort für:
- Bootsname/-profil in Törnidentität
- wiederverwendbare Bootsprofile
- „für dieses Boot üblich“
- intelligente Wiederverwendung von Bootskontext

### GUEST1
Verbindlicher zukünftiger Slice für:
- Einkauf aufteilen
- Gast-QR/Link ohne Account
- Offline-fähige Gastliste
- Zero-Internet Offline-QR/Share
- Reconciliation und sichere Capability-Sessions

Grundlage: `docs/PRODUCT_GUEST_SHOPPING_v0.3.md` und `docs/impl/GUEST1_plan.md`.

### RECEIPT1
Verbindlicher zukünftiger Slice für:
- Belegfoto(s) an Expenses
- Offline-Speicherung und Backup/Restore
- Settlement-Regressionsschutz für tatsächlich von Crewmitgliedern bezahlte Gruppenausgaben
- `Abrechnung.pdf` + `Belege.pdf`
- nativen Mail-/Share-Composer

Grundlage: `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md` und `docs/impl/RECEIPT1_plan.md`.

### UX-D – künftiger dedizierter UI/UX-Slice
Soll nach Abschluss der Detailausarbeitung umsetzen:
- Adaptive Command Center
- stabiles Command Grid
- Color-Semantik
- Motion-/Haptic-System
- mechanische Controls
- Screen-spezifische progressive disclosure
- konsistente Empty States / Next Action

## 16. Owner-accepted Detailentscheidungen

Verbindliche Detailentscheidungen stehen vollständig in:
`docs/design/PROVY_UX_DECISIONS_2026-10-05.md`

Zusammenfassung:
- Home: Situation zuerst; nur relevanter Törn; + Neuer Törn sichtbar; Alle Törns sekundär.
- Command Grid: vier gleich große Kacheln in fester Reihenfolge Vorräte | Einkaufen / Crew & Boot | Bordkasse.
- Kacheln: Name/Icon + maximal 1–2 relevante Statuswerte.
- Next Action: Lifecycle + realer Datenzustand; eine Hauptaktion + maximal eine sekundäre; grundsätzlich ignorierbar.
- Vorräte: Search-first; Bottom Sheet für Variante/Gebinde/Anzahl; Packungs-Chips; Stepper + Pickwheel; Standard-Sortierung nach Abteilung.
- Hinweise: kontextuell + kompakte Gesamtsicht; keine Score-Mechanik.
- Einkaufen: Stoppliste zuerst; Stop-Detail vor Shopping Mode.
- Guest Shopping: Abteilungsgruppen zuerst; Helfername optional; QR-first; Online/Offline automatisch; Rückgabe-QR nicht GUEST1-v1-Pflicht.
- Crew & Boot: ein Screen, Boot zuerst.
- Bordkasse: Kassenstand + Einzahlen/Ausgabe zuerst; Abrechnung erst gegen Törnende prominent.
- Quick Action: kontextabhängiger FAB; kein Long-Press als Pflichtpfad.
- Visual: Off-White/Navy als Light-Default; Dark und Nightwatch/Rotlicht müssen dieselbe Hierarchie/Lesbarkeit erhalten.
- Bereichsfarben: Icon + Akzentlinie + sehr leichte Tönung.
- Statusfarben global: neutral / Hinweis / Aktion nötig / erledigt.
- Motion/Haptics: funktional spürbar, nicht dekorativ.
- Neuer Törn: ein kompakter Screen; zuletzt verwendetes Boot als bestätigbarer Default.

## 17. UX-D Freeze

Die Screen-by-Screen-Wireframe-Runde ist abgeschlossen und owner-accepted.

Verbindliche Referenz:
`docs/design/PROVY_UX_WIREFRAMES_v0.2.md`

Für UX-D verbleiben nur Implementierungsdetails innerhalb des bestehenden Design-Systems:
- konkrete Komponentenmaße
- exakte Abstände
- finale Typografie-Ausprägung
- Motion-Durations/Easing
- technische Flutter-Komponentenwahl

Diese Details dürfen die eingefrorene Informationsarchitektur, Hierarchie, Navigation oder Interaktionslogik nicht verändern.
