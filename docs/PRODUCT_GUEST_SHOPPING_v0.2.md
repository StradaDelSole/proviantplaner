# Provy Guest Shopping Collaboration v0.2

Stand: 05.10.2026  
Status: **OWNER-ACCEPTED / verbindliche Produktentscheidung**

Version v0.2 integriert die Guest-Shopping-Entscheidungen aus `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`.

## 1. Ziel

Mehrere Personen sollen einen Einkauf parallel erledigen können, **ohne dass jedes Crewmitglied Provy installieren, einen Account besitzen oder eine Lizenz benötigen muss**.

Leitprinzip:

> Der Provy-Owner organisiert den Törn. Einkaufshelfer bekommen nur genau den Einkaufsteil, den sie benötigen.

Das Feature muss auch in Revieren mit schlechtem oder fehlendem Internet praktisch funktionieren.

## 2. Produktentscheidung

Provy erhält **Guest Shopping Sessions** mit QR-/Link-Freigabe und einem gleichwertigen Offline-Fallback.

Der eingeloggte/lizenzierte Provy-Nutzer bleibt Owner des Törns. Gasthelfer:
- benötigen keinen Account,
- benötigen keine Provy-App,
- belegen keinen Lizenz-/Seat-Platz,
- erhalten keinen Zugriff auf Bordkasse, Crewprofile, Bootsdaten oder andere Törndaten außerhalb des freigegebenen Einkaufspakets.

Vollständige Multi-User-/Crew-Accounts und allgemeine kollaborative Törn-Bearbeitung sind weiterhin **nicht** Voraussetzung dieses Features.

Die Aussage in `BACKEND_KONZEPT_v0.2.md`, dass gemeinsame Echtzeit-Listen nicht in v1 liegen, ist für **vollwertige Account-Kollaboration** weiterhin gültig. Für die hier definierte, eng begrenzte Guest-Shopping-Freigabe ist sie superseded.

## 3. Nutzer-UX: „Einkauf teilen“

Ein Einkaufsstopp kann optional in **Einkaufspakete** aufgeteilt werden.

Der Nutzer sieht nach außen keine technische Bezeichnung wie „Shopping Packet“.

UI-Begriffe:
- **Einkauf aufteilen**
- **Einkauf teilen**
- **QR anzeigen**
- **Link teilen**
- **Offline teilen**

Ein Paket kann entstehen aus:
- einer oder mehreren Supermarkt-Abteilungen,
- frei ausgewählten Positionen,
- einem konkreten Einkaufsort,
- einer frei benannten Gruppe.

Beispiele:
- Getränke
- Lebensmittel
- Hygiene
- Lidl
- Getränkemarkt
- Markt

Standardfall: **Provy schlägt vorhandene Abteilungsgruppen automatisch vor**, damit nicht jede Position einzeln zugewiesen werden muss. Einzelne Positionen dürfen anschließend angepasst werden.

Ein optionaler Helfername darf gesetzt werden, ist aber niemals Pflicht.

## 4. Online-Flow – Gast ohne App und Account

Owner:
1. öffnet Einkaufsstopp,
2. wählt „Einkauf aufteilen“,
3. markiert z. B. Getränke,
4. wählt „Teilen“,
5. Provy erzeugt einen zeitlich begrenzten Capability-Link,
6. Provy zeigt **QR zuerst groß**; darunter bleiben `Link teilen` und `Offline teilen` sichtbar.

Gast:
1. scannt QR oder öffnet Link,
2. landet direkt auf einer mobilen Gast-Einkaufsliste,
3. sieht nur das freigegebene Paket,
4. hakt Artikel ab,
5. Fortschritt wird bei Verbindung synchronisiert.

Beispiel:

> Provy  
> Einkauf für SY Aurora  
> **Getränke**  
> 3 / 8 erledigt  
>
> ☐ Wasser · 6 × 1,5 l  
> ✓ Bier · 24 × 0,33 l  
> ☐ Tonic · 4 × 1 l

Keine Registrierung, kein Login-Dialog, kein App-Install-Prompt vor der eigentlichen Liste.

## 5. Offline-first ist verbindlich

Das Feature gilt erst als vollständig, wenn **Online- und Offline-Nutzung** funktionieren.

Es gibt drei Offline-Situationen.

### 5.1 Verbindung fällt erst nach Öffnen der Gastliste aus

Die Gastseite wird als kleine offlinefähige Web-App/PWA gebaut:

- Session-Snapshot und notwendige UI-Assets werden beim erfolgreichen Öffnen lokal gecacht,
- Häkchen funktionieren ohne Verbindung weiter,
- Änderungen werden lokal als Pending Events gespeichert,
- bei wieder verfügbarer Verbindung werden sie automatisch/idempotent synchronisiert,
- der Gast muss den Einkauf nicht neu öffnen.

Das schützt gegen schlechten Empfang im Supermarkt.

### 5.2 Beim Verteilen existiert überhaupt kein Internet

Der Owner muss **vollständig lokal aus der Drift-Datenbank** ein Offline-Einkaufspaket erzeugen können.

Mindestens zwei Ausgabeformen:

1. **Offline-QR**
   - enthält eine kompakte, menschenlesbare Momentaufnahme des Einkaufspakets,
   - keine Serverauflösung erforderlich,
   - mit normaler Kamera/QR-Scanner lesbar,
   - bevorzugt ein QR pro kleines Einkaufspaket,
   - bei zu großer Datenmenge automatisch nummerierte mehrere QR-Codes statt stiller Kürzung.

2. **Lokaler Share-Export**
   - als Text und/oder Bild/PDF lokal erzeugbar,
   - kann über das Betriebssystem-Share-Sheet übertragen werden,
   - Erstellung darf kein Netz benötigen.

Der Offline-QR ist der universelle physische Fallback: zwei Telefone nebeneinander reichen.

Provy entscheidet im Normalfall automatisch anhand der Konnektivität zwischen Live-/Offline-Pfad. Der Nutzer sieht verständliche Zustände wie `Live-Synchronisierung verfügbar` oder `Offline-Liste – später in Provy bestätigen`, nicht technische Netzwerkbegriffe. Ein manueller Moduswechsel darf unter weiteren Optionen verfügbar bleiben.

Ein statischer Offline-Pass muss nicht live zurücksynchronisieren. Er muss den Einkauf zuverlässig lesbar machen.

### 5.3 Rückführung nach einem rein statischen Offline-Einkauf

Der Owner öffnet das Paket in Provy.

Normalfall:
- **Alles gekauft** → ein Tap markiert das gesamte Paket gekauft.

Ausnahmen:
- einzelne nicht erhaltene Positionen wieder öffnen,
- „später“ oder „streichen“ nach dem bestehenden Shopping-Flow behandeln.

Damit bleibt der Offline-Fallback schnell, obwohl der Gast keine interaktive Provy-Session hatte.

## 6. Optionaler Offline-Rückkanal

Wenn die Gast-Web-App bereits einmal geladen/cached wurde, darf sie später zusätzlich einen kompakten **Rückgabe-QR** erzeugen:

- enthält nur Paket-ID/Revision und gekaufte Statuswerte bzw. ein kompaktes Ergebnis,
- Owner scannt ihn in Provy,
- Provy zeigt vor Import eine kurze Zusammenfassung,
- Import ist idempotent.

Dieser Rückkanal ist wertvoll, aber **nicht Bestandteil der GUEST1-v1-Definition of Done**. Für v1 reichen statischer Offline-Share + Owner-Reconcile. Ein Rückgabe-QR kann danach als Erweiterung folgen.

## 7. Daten-/Domainmodell

Das bestehende lokale Trip-/Shopping-Modell bleibt kanonisch für den Owner.

Vorgesehenes Modell:

### Lokal
`ShoppingSharePacket`
- local_id
- trip_id
- shopping_stop_id
- label
- revision
- created_at
- optional server_share_id
- state: draft / active / reconciled / revoked

`ShoppingSharePacketItem`
- packet_id
- list_item_id
- allocated_packages
- snapshot_name
- snapshot_pack_display
- snapshot_department
- bought_state

Snapshots sind notwendig, damit ein bereits ausgegebener Offline-Pass nachvollziehbar bleibt, auch wenn der Owner später die Hauptliste ändert.

### Backend
`shopping_shares`
- id
- owner_account_id
- opaque_token_hash
- trip_ref
- label
- revision
- expires_at
- revoked_at
- created_at

`shopping_share_items`
- share_id
- item_ref
- display snapshot
- allocated_packages
- bought_state
- updated_at

Exakte Tabellen-/Feldnamen werden im Implementierungsslice final reconciliiert; die fachliche Trennung und Snapshot-Semantik sind verbindlich.

## 8. Source of Truth und Konfliktregeln

- Owner-App/Drift bleibt Source of Truth für den Törn.
- Backend-Guest-Session ist eine begrenzte Kollaborationsprojektion.
- Gast darf nur Status der ihm freigegebenen Positionen verändern.
- Keine Änderung von Crew, Boot, Gesamtmengen, Bordkasse oder anderen Stopps.
- Share erhält eine Revision.
- Wird die Owner-Liste nach Freigabe substanziell geändert, darf dies nicht still den bereits ausgegebenen Snapshot mutieren.
- Owner kann Share aktualisieren/regenerieren oder widerrufen.
- Reconciliation in die lokale Liste muss idempotent sein.
- Keine Mengenverdopplung; Allocation-Invarianten bleiben bestehen.

## 9. Security / Privacy

Online-Share als Capability Link:

- kryptografisch zufälliger, ausreichend langer opaque Token,
- serverseitig nur Token-Hash speichern,
- scoped auf exakt ein Share-Paket,
- Ablaufdatum,
- jederzeit widerrufbar,
- kein erratbarer Trip-Identifier als Berechtigung,
- Rate Limiting für öffentliche Endpunkte,
- keine Indexierung,
- keine Finanz-/Crew-/Kontodaten im Gastpayload,
- Bootsname/Törnbezeichnung nur soweit für den Einkauf hilfreich und vom Produkt bewusst freigegeben.

Der Capability-Link ist die Berechtigung. Keine zusätzliche Registrierung oder Captcha-Hürde im normalen Einkaufspfad, sofern Abuse-Schutz dies nicht später zwingend erfordert.

## 10. Lizenzmodell

- Nur der Owner benötigt die für den Törn erforderliche Provy-Berechtigung.
- Gastzugriff verbraucht keinen zusätzlichen Lizenzplatz.
- Gast muss kein HullQ-/Provy-Konto anlegen.
- Gast-QR/Link darf nicht als künstlicher Conversion-Gate missbraucht werden.

Optionales Provy-Branding ist erlaubt, aber Einkauf kommt zuerst.

## 11. Psychologische/UX-Regeln

- „Einkauf teilen“ statt „User einladen“.
- „Getränke“ statt technische Rollen-/Teambegriffe.
- Keine Kanban- oder Projektmanagement-UI.
- Keine Pflicht, jedem Artikel einzeln eine Person zuzuweisen.
- Normalfall in wenigen Taps.
- Fortschritt klar: z. B. `5/8 erledigt`.
- Owner sieht, welche Pakete offen/erledigt sind.
- Ein Paket kann optional einen frei eingegebenen Helfernamen tragen, ohne Accountbindung.
- Offline-Zustand wird sichtbar, aber nicht alarmistisch erklärt.

## 12. Command-Center-Integration

„Einkauf teilen“ wird **kein neuer Hauptbereich**.

Es gehört unter:
> **Einkaufen**

Törnübersicht behält die stabilen Hauptbereiche:
- Vorräte
- Einkaufen
- Crew & Boot
- Bordkasse

Einlagern und Abrechnung bleiben situative Aktionen / Unterfunktionen.

Während geteilter Einkäufe kann die Next-Action z. B. anzeigen:

> Einkauf läuft  
> 22 / 31 erledigt  
> Getränke 5/8 · Lebensmittel 11/17 · Hygiene 6/6

## 13. Akzeptanzkriterien

Das Feature ist nicht fertig, bevor mindestens folgende Szenarien funktionieren:

1. Owner teilt ein Paket per QR; Gast braucht weder Account noch App.
2. Gast hakt online Artikel ab; Owner kann Fortschritt übernehmen.
3. Gastseite verliert nach dem Öffnen Internet; Häkchen funktionieren offline und synchronisieren später.
4. Owner hat beim Verteilen kein Internet; Offline-QR wird vollständig lokal erzeugt und ist auf zweitem Telefon lesbar.
5. Zu großes Offline-Paket wird nicht gekürzt, sondern sauber auf mehrere nummerierte QR-Codes/Exports aufgeteilt.
6. Reiner Offline-Einkauf lässt sich mit „Alles gekauft“ + Ausnahmen schnell reconciliieren.
7. Widerruf/Expiry verhindert weiteren Online-Zugriff.
8. Gast kann keine anderen Törndaten oder Finanzdaten lesen.
9. Mehrere parallel geteilte Pakete desselben Stopps verletzen keine Mengen-/Allocation-Invarianten.
10. Bestehender Solo-Einkaufsflow bleibt genauso einfach wie zuvor.

## 14. Nicht Teil dieser Entscheidung

Noch nicht beschlossen:
- echte Crew-Accounts für alle,
- vollständige gemeinsame Törn-Bearbeitung,
- Chat,
- Rollen-/Rechtesystem für Crew,
- verpflichtende Realtime-WebSockets,
- Presence/„Gary ist gerade online“.

Polling/Refresh bzw. einfache Synchronisierung reicht zunächst, wenn die UX schnell genug reagiert.

## 15. Umsetzung

Das Feature wird als eigener verbindlicher Slice **GUEST1 – Shared Shopping, QR & Offline** geführt.

Reihenfolge:
- FIX-A vollständig owner-accepted,
- PIVOT1 Assisted List Core,
- danach GUEST1 in die aktive Roadmap einplanen,
- spätestens vor Store-v1-Abnahme vollständig implementieren.

PIVOT1 muss das Datenmodell so weiterentwickeln, dass stabile ListItem-/Allocation-Referenzen und spätere Share-Pakete möglich bleiben. PIVOT1 baut GUEST1 aber noch nicht vorweg.
