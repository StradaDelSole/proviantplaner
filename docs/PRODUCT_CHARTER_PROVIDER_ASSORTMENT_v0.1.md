# Product Decision v0.1 – Charter Provisioning Provider Assortments

Stand: 16.10.2026  
Status: **OWNER-ACCEPTED / verbindlich für spätere B2B- und Charter-Provisioning-Implementierung**

Owner decision:

Der bestehende B2B-/Charter-Provisioning-Ansatz wird um **anbieter- und basis-spezifische Sortimentsprofile** erweitert.

Diese Entscheidung konkretisiert und erweitert insbesondere:

- `docs/PRD_v0.21.md`, Abschnitte **Lieferanten: Liefern lassen (v1)** und **B2B-Kanal: Charterfirmen**
- `docs/BACKEND_KONZEPT_v0.2.md`, insbesondere B4/B5
- bestehende Einkaufsstopp-Semantik **Selbst einkaufen / Liefern lassen**

Sie ersetzt nicht den aktuellen WATER1-Slice und gibt **keinen Implementierungsslice** frei.

---

## 1. Produktziel

Provy soll Charterfirmen nicht nur als Distributionspartner dienen, sondern ihnen einen echten zusätzlichen Geschäftszweig ermöglichen:

- eigene Provisionierung anbieten;
- lokal selbst einkaufen und mit Service-/Marge weiterverkaufen;
- mit einem lokalen Supermarkt, Caterer oder Provisioning-Partner kooperieren;
- Crew-Bestellungen strukturiert vor Anreise erhalten;
- Sortiment und Gebinde so abbilden, wie sie an der konkreten Basis tatsächlich verfügbar sind.

Das Charter-B2B-Verkaufsargument lautet sinngemäß:

> Provy kann aus dem bestehenden Provisioning-Service einer Charterbasis einen strukturierten digitalen Zusatzumsatz machen – auch wenn die Charterfirma die Waren nicht selbst lagert oder führt.

Provy wickelt in diesem Scope keine Zahlung ab.

---

## 2. Zentrale Architekturentscheidung

Es wird **kein vollständig separater Provy-Katalog pro Charterfirma** aufgebaut.

Der globale kanonische Provy-Katalog bleibt die gemeinsame fachliche Produkt-Ontologie für:

- Kategorien und Gruppen;
- AssistType;
- Haltbarkeit;
- Kühlung / Tiefkühlung;
- Gebinde- und Mengenlogik;
- Gewicht / Volumen;
- Provisioning Review;
- sonstige fachliche Produktregeln.

Darüber liegt ein **Provider Assortment Overlay**.

Ein Anbieter definiert damit:

- welche Provy-Produkte er anbietet;
- welche Gebinde er anbietet;
- optional seinen eigenen Produktnamen / Marke;
- optional eine eigene SKU/Artikelnummer;
- ob ein Artikel aktuell verfügbar ist;
- später optional Preis, Mindestmenge, Ersatzregeln oder saisonale Gültigkeit.

Die fachliche Provy-Produktidentität und die reale Lieferfähigkeit bleiben getrennte Wahrheiten.

---

## 3. Provisioning Provider

Ein `ProvisioningProvider` kann sein:

- die Charterfirma selbst;
- eine einzelne Charterbasis;
- ein externer lokaler Provisioning-Partner;
- ein Supermarkt / Caterer / sonstiger Lieferpartner.

Ein Provider kann einer oder mehreren Basen zugeordnet werden.

Eine Charterorganisation kann mehrere Provider oder Profile führen.

Beispiel:

- Charterfirma A / Basis Split → eigener Provisioning-Service
- Charterfirma A / Basis Dubrovnik → lokaler Supermarkt-Partner
- Charterfirma B → externer Caterer für mehrere Basen

---

## 4. Provisioning Profile / Assortment Profile

Ein `ProvisioningProfile` beschreibt das konkrete Angebot eines Providers für eine Basis bzw. einen Gültigkeitskontext.

Mindestens fachlich vorgesehen:

- Provider
- Basis / Geltungsbereich
- aktiv / inaktiv
- Fulfillment-Modell:
  - `charter_company`
  - `local_partner`
- optional Saison / Gültigkeitszeitraum
- Kontakt-/Bestellkanal
- Sortiment

Spätere optionale Erweiterungen dürfen vorbereitet, aber nicht ohne eigenen Scope sichtbar umgesetzt werden:

- Mindestbestellwert
- Liefergebühr
- Bestellschluss / Lead Time
- Preise
- saisonale Verfügbarkeit
- Substitution
- Bestellstatus
- API-Integration

---

## 5. Provider Catalog Item

Ein Provider-Sortimentsartikel referenziert nach Möglichkeit eine kanonische Provy-Variante.

Beispiel:

`Provy water_15l`

kann beim Provider erscheinen als:

- eigener Name: „Jana 1.5 L“
- Provider-SKU: `8472`
- Gebinde: 1.5 l
- optional Multipack: 6 × 1.5 l
- verfügbar: ja

Ein anderer Provider kann dieselbe Provy-Variante mit anderer Marke, SKU oder anderem Gebinde anbieten.

### Provider-only products

Ein Provider darf außerdem Produkte anbieten, die im globalen Provy-Katalog nicht vorhanden sind.

Dafür gilt:

- Provider-only Produkt ist erlaubt;
- wenn fachlich sinnvoll, kann es einer Provy-Gruppe/Kategorie zugeordnet werden;
- es darf keine neue globale Provy-Produktwahrheit allein dadurch erzeugen;
- eine Promotion in den globalen Katalog ist eine separate Katalogentscheidung.

---

## 6. Selbst einkaufen vs. Liefern lassen

Die Entscheidung liegt weiterhin **pro Einkaufsstopp**, nicht zwingend pro Törn.

### Selbst einkaufen

Bei `Selbst einkaufen`:

- normaler globaler Provy-Katalog;
- keine Einschränkung durch Provider-Assortment;
- Skipper kann seine Liste frei bauen.

### Liefern lassen

Bei `Liefern lassen`:

- Einkaufsstopp erhält einen Provider / ein Provisioning Profile;
- Provy gleicht die dem Stopp zugeordneten Positionen mit dem realen Sortiment ab;
- verfügbare Produkte können bestellt werden;
- nicht verfügbare Produkte bleiben sichtbar.

Nicht verfügbare Positionen dürfen **nicht still verschwinden**.

Stattdessen muss Provy eine klare Aktion ermöglichen, z. B.:

- Alternative des Providers wählen;
- anderes Gebinde wählen;
- Position auf einen Selbst-einkaufen-Stopp verschieben;
- Position bei einem anderen Provider bestellen;
- bewusst offen lassen.

---

## 7. Planung und Lieferfähigkeit strikt trennen

Verbindlicher Grundsatz:

> **Die Crew plant ihren tatsächlichen Bedarf. Das Provider-Profil beschreibt nur, was dieser Anbieter liefern kann.**

Ein kleines Lieferantensortiment darf die fachliche Provy-Liste nicht verfälschen.

Beispiel:

Crew plant Pesto.

Provider A führt kein Pesto.

Dann darf Provy nicht so tun, als brauche die Crew kein Pesto.

Stattdessen:

`Pesto – bei diesem Anbieter nicht verfügbar`

und der Nutzer entscheidet über Ersatz oder anderen Einkaufsweg.

---

## 8. Einkaufsstopp als Fulfillment-Grenze

Die vorhandene ShoppingStop-/Allocation-Struktur bleibt konzeptionell richtig.

Ein Törn kann kombinieren:

- Tag 1: Liefern lassen durch Charterbasis
- Tag 4: Selbst einkaufen
- Tag 7: Selbst einkaufen
- optional weiterer Lieferpartner

Damit ist kein Trip-weites Entweder/Oder-Modell erforderlich.

Positionen oder Teilmengen können weiterhin unterschiedlichen Stopps zugeordnet werden.

---

## 9. Törn-Code / Charter-Integration

Ein Charter-Törn-Code darf später zusätzlich zu bestehenden Voreinstellungen übernehmen:

- Charterorganisation
- Basis
- bevorzugter Provisioning Provider
- Provisioning Profile / Assortment Profile
- Co-Branding

Die Crew kann dadurch bei Einlösung des Codes direkt mit dem realen Angebot der gebuchten Basis arbeiten.

Die genaue Override-/Wechsel-Semantik wird vor B4/B5 nochmals reconciliert.

---

## 10. Charter-Admin

Die spätere Charter-Admin-Seite muss nicht nur Basen und Kontaktangaben des Proviantservices verwalten können.

Sie muss perspektivisch mindestens ermöglichen:

- Provider anlegen/bearbeiten;
- Provider einer Basis zuordnen;
- Provisioning Profile verwalten;
- Provy-Katalogvarianten in das eigene Sortiment aufnehmen/entfernen;
- angebotene Gebinde festlegen;
- Provider-Name / Marke / SKU pflegen;
- Produkte aktiv/inaktiv setzen;
- Provider-only Produkte verwalten.

Massenupload / CSV / API-Import kann später sinnvoll sein, ist aber eine separate Detailentscheidung.

---

## 11. Bestellübergabe

Der bestehende v1-Grundsatz bleibt:

- strukturierte Bestellung;
- PDF / E-Mail / WhatsApp / Share;
- keine Zahlungsabwicklung durch Provy.

Die Bestellung muss bei Provider-Profilen später die **Provider-relevante Produktdarstellung** nutzen:

- Anbietername / Produktname
- Provider-SKU, falls vorhanden
- konkretes Gebinde
- Menge
- gegebenenfalls Provy-Referenz intern

Die Crew sieht weiterhin verständliche Provy-/Produktnamen.

---

## 12. Offline-/Snapshot-Prinzip

Provy bleibt offline-first.

Daher darf ein Törn nicht vollständig davon abhängen, dass beim Einkauf noch eine Live-Verbindung zum Provider besteht.

Vor späterer Implementierung ist zu reconciliieren, welche Provider-/Assortment-Daten beim Einlösen eines Charter-Codes bzw. beim Auswählen eines Providers lokal als Snapshot gespeichert werden.

Mindestens zu berücksichtigen:

- Anbieteridentität
- verwendetes Provisioning Profile
- Produktmapping
- angebotene Gebinde
- notwendige Bestellkontaktdaten

Live-Inventar ist **nicht** vorausgesetzt.

---

## 13. Preis und kommerzieller Scope

Preisfelder sind architektonisch erwartbar, aber **nicht automatisch Teil des ersten Assortment-Slices**.

Für einen ersten produktiven B2B-Scope reicht:

- verfügbares Sortiment;
- reale Gebinde;
- strukturierte Bestellung.

Später separat entscheidbar:

- Preis
- Mindestbestellwert
- Lieferkosten
- Preisgültigkeit
- Charter-Marge
- Provy-/HullQ-Provision
- Umsatzstatistik
- Bestellstatus
- API-basierte Orders

Keine Zahlungsabwicklung wird durch diese Entscheidung freigegeben.

---

## 14. B2B-Sales-Nutzen

Diese Funktion ist ausdrücklich Teil des Charter-Sales-Arguments.

Nutzen für Charterfirmen:

- zusätzlicher Ancillary-Revenue-Kanal;
- bestehende Provisioning-Dienstleistung digitalisieren;
- Provisioning auch ohne eigenes Lager anbieten;
- lokalen Partner integrieren;
- Bestellungen früher und strukturierter erhalten;
- weniger Rückfragen und Fehlbestellungen;
- besserer Service bei der Bootsübernahme;
- eigener Name / Co-Branding;
- kein eigenes Provisioning-Softwareprojekt notwendig.

---

## 15. Reconciliation-Status

### DECIDED_AND_IMPLEMENTED

- ShoppingStop-Grundmodell
- ListItem / Allocation-Grundmodell
- globaler Provy-Katalog
- Charter-/Trip-Grunddaten
- bestehende Lieferantenidee im Produkt

### DECIDED_NOT_IMPLEMENTED / READY FOR LATER RECONCILIATION

- Einkaufsstopp `Selbst einkaufen / Liefern lassen`
- strukturierte Bestellung
- gespeicherte Lieferanten
- Törn-Code mit Basis / Proviantservice / Co-Branding
- Charter-Admin B4/B5

### NEW OWNER-ACCEPTED DECISION / NOT IMPLEMENTED

- ProvisioningProvider
- ProvisioningProfile / Assortment Profile
- Provider-Assortment Overlay
- ProviderCatalogItem
- Provider-only Produkte
- Availability-/Gebinde-Mapping
- Supplier-aware Lieferstopp
- Assortment-Verwaltung im Charter-Admin

### UNDECIDED UNTIL LATER RECONCILIATION

- Preisfelder im ersten Slice
- Mindestbestellwert / Liefergebühr
- Lieferzeitfenster / Cutoff
- Substitution-Regeln
- Importformat für Provider-Sortimente
- Live-Inventar
- Bestellstatus
- API-Integration
- kommerzielles Provisionsmodell

---

## 16. Verbindliches zukünftiges Gate

Bevor einer der folgenden Bereiche implementiert oder wesentlich erweitert wird:

- B4 Törn-Codes
- B5 Charter-Admin
- Charter-Provisioning
- Provider-Sortiment
- Lieferanten-Backend
- supplier-aware `Liefern lassen`

muss eine neue **Decision/Implementation Reconciliation** gegen den dann aktuellen `origin/main` durchgeführt werden.

Diese Reconciliation muss dieses Dokument ausdrücklich berücksichtigen.

Dabei ist mindestens zu entscheiden:

1. exaktes Datenmodell;
2. Cloud vs. lokaler Snapshot;
3. Provider-only Produktsemantik;
4. Sortiment-/Gebindeimport;
5. UI für Verfügbarkeit/Alternativen;
6. Scope Preis / Mindestbestellwert / Delivery Fee;
7. welche Teile in v1 und welche später kommen.

Kein Agent darf B4/B5 nur nach dem älteren `BACKEND_KONZEPT_v0.2.md` implementieren und dabei das Provider-Assortment ignorieren.

---

## 17. Aktueller Gate-Status

Diese Entscheidung ist **OWNER-ACCEPTED**, aber **NICHT IMPLEMENTATION RELEASED**.

WATER1 bleibt der aktuell einzige freigegebene Implementierungsslice.

PIVOT2, B4/B5 und Provider-Assortment bleiben weiterhin separat gegatet.
