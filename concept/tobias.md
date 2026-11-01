## Wirtschaft und Verkehrsmittel
*Tobias Brandt, Systems & Economy Designer. Alle Zahlen sind Startwerte für den Vertical Slice.*

### Güter und Ketten
Ketten liegen als Cluster zusammen (Rohstoff → Verarbeiter ≤ 30 Felder), Städte 40–90 Felder davon entfernt.

| Kette | Stufen | Rohstoffort | Abnehmer |
|---|---|---|---|
| Getreide → Mühle → Mehl | 2 | Ebene, Flussnähe | Städte (Nahrung) |
| Vieh → Schlachthof → Fleisch | 2 | Weideland, Hügel | Städte (Nahrung, Frischegut) |
| Holz → Sägewerk → Bretter | 2 | Wald | Städte (Bau) |
| Kohle → Kraftwerk | 1 | Bergrand | Energie (Multiplikator) |
| Erz + Kohle → Stahlwerk → Stahl → Werkzeugfabrik → Werkzeug | 3 | Gebirge | Städte ab Stufe „Stadt“ |

### Ressourcen-Umfang: Wie viele Ketten?
Fünf Ketten reichen für den Start, aber es sollten **andere** fünf sein als im Prototyp. Öl kommt erst in E2, dafür ist **Kohle** schon in E1 dabei. Kohle beliefert zwei Abnehmer (Kraftwerk und Stahlwerk). Damit entsteht die erste echte Verteilungsentscheidung: Strombonus oder Stahl?

**Begründung:**
- **Lesbarkeit:** In E1 höchstens ca. 12 unterscheidbare Güter. Jedes Gut braucht eine eigene Farbe, ein Icon und eine Industrie-Silhouette. Mehr Güter überfordern Diagnose und Legende.
- **Entscheidungsvielfalt:** Eine Kette verdient ihren Platz nur, wenn sie eine **neue Entscheidung** bringt, zum Beispiel:
  - geteilter Input (Kohle)
  - Frische (Fleisch)
  - Substitut (Mehl/Fleisch)
  - neue Verkehrsmittel-Nische (Massengut fürs Schiff)
  - Strombedarf (Chips)

  Eine Kette, die nur „noch ein Gut von A nach B“ ist, fliegt raus.

| | Vertical Slice | Release |
|---|---|---|
| Epochen | E1 (+ Ausblick E2) | E1–E4 |
| Ketten | 5 (Tabelle oben) | 10 |
| Güter | ca. 12 | ca. 28 |
| Stadtkategorien | Nahrung, Bau, Werkzeug | + Treibstoff, Konsum, Mobilität, Elektronik |

### (a) Weiterentwicklung bestehender Ketten
Bestehende Ketten bekommen neue Endstufen. Jede Weiterentwicklung ist ein **Ausbau an der vorhandenen Firma** (Stufe, Spezialisierung, Firmenwert bleiben). Es wird kein Neubau an einem anderen Ort nötig.

| Epoche | Bestehende Kette | Neue Stufe / Endprodukt | Inputs | Wer braucht es |
|---|---|---|---|---|
| E2 | Mehl | Bäckerei → Brot (Frische) | Mehl | Städte, Nahrung +15 % |
| E2 | Fleisch | Konservenfabrik → Konserven | Fleisch, Stahl | Städte, Nahrung (haltbar, Massengut) |
| E2 | Werkzeug | Maschinenbau → Maschinen | Werkzeug, Stahl | **Industrien** (Ausbau ab Stufe 3) |
| E3 | Bretter | Möbelfabrik → Möbel | Bretter, Kunststoff | Städte, Konsum |
| E3 | Stahl | Elektrostahl (Modernisierung) | Erz, **Strom** statt Kohle | Stahlwerke, Autofabrik |

### (b) Epochengebundene neue Industrien

| Epoche | Neue Industrie | Inputs | Wer braucht es |
|---|---|---|---|
| E2 | Ölfeld → Raffinerie → Benzin | Öl | Städte (Treibstoff), Ölkraftwerk |
| E3 | Chemiewerk → Kunststoff | Öl, Strom | Autofabrik, Möbel, Chipfabrik |
| E3 | Autofabrik → Autos | Stahl, Kunststoff, Maschinen | Großstädte (Mobilität) |
| E4 | Siliziumwerk → Chipfabrik → Chips | Quarzsand, Kunststoff, **Strom ≥ 80 %** | Elektronikwerk |
| E4 | Elektronikwerk → Elektronik | Chips, Kunststoff | Großstädte (Elektronik), passt zum Flugzeug |

### Was passiert mit alten Industrien beim Epochenwechsel?
Wann eine Epoche wechselt, steht in Lenas Epochenmodell. Hier geht es um die Folgen für die Wirtschaft.

**Grundregel: Das System schließt nie eine Spielerfirma. Investitionen sind geschützt.**

- **Bleiben:** Jede Industrie produziert weiter. Ihre Produktion ist nie wertlos.
- **Nachfrage verschiebt sich:** Veraltete Güter verlieren je Epoche bis zu −30 % Bedarf, nie unter 40 % des Ausgangswerts. Beispiel: Kohle für Kraftwerke, sobald Öl- und Gaskraftwerke verfügbar sind. Das wird **eine Epoche vorher** in der Technik-Vorschau angekündigt.
- **Modernisieren:** Kostet 50 % der Neubaukosten und dauert 60 s Stillstand. Danach +20 % Produktivität. Stufe und Spezialisierung bleiben, der Strombedarf kann steigen.
- **Umrüsten:** Umstellung auf eine verwandte Kette, zum Beispiel Kohlemine → Erzmine oder Sägewerk → Möbelfabrik. Kostet 40 % eines Ausbaus. Die Stufe bleibt, die Spezialisierung wird neu gewählt.
- **Schließen/Verkaufen:** nur durch den Spieler, sofort zu 70 % des Firmenwerts oder an ein Übernahmeangebot der KI.
- **Investitionsschutz:** Ein Epochenwechsel senkt den Firmenwert um höchstens 20 %.

Für den Spieler ist ein Epochenwechsel damit eine **Optimierungsentscheidung mit Vorlauf**, keine Enteignung: weiterlaufen lassen, modernisieren oder umrüsten.

### Personenverkehr
- Jede Stadt erzeugt **1 Fahrtwunsch/min je 100 Einwohner**. Aufteilung: 60 % Wohnen ↔ Arbeit innerorts, 25 % Stadt ↔ Stadt, 15 % Pendler zu Industrien im Umkreis von 25 Feldern.
- **Pendler als Produktivitätsbonus:** Industrien laufen ohne Pendler mit 80 % (lokale Grundbelegschaft) und mit voller Pendlerabdeckung mit 110 %. Damit sind Industrien nie „ohne Arbeiter“ tot, aber Busse und Nahverkehr zu Industrien zahlen sich messbar aus.
- **Ticketerlös** = 0,6 $ × Luftlinie × Zeitfaktor. Mindestdistanz 4 Felder. Wer länger als 3 min wartet, verfällt und taucht in der Heatmap „Wartende“ auf.

### Ertragsformel
Ertrag gibt es **nur bei Abgabe an einen Endabnehmer**, also an einen Verarbeiter (für sein Eingangsgut) oder an eine Stadt. Jede Einheit trägt einen **Herkunftsstempel** (Ursprungsfirma, Abfahrtszeit), der beim Umladen im Lager erhalten bleibt.

**E = M × P_gut × D_eff × F_zeit × F_sätt × (1 + B_skill)**

- M = Menge, P_gut = Preis je Einheit und Feld
- D_eff = Luftlinie Ursprung → Abnehmer: bis 60 Felder linear, darüber 60 + 0,5 × (D − 60). Unter 6 Feldern gibt es keinen Ertrag. Umwege zahlen nie mehr.
- F_zeit = clamp(1 − (t − t_frist) / t_verfall; 0,3; 1). Frischegüter: t_frist 60 s, t_verfall 120 s. Massengut: 300 s / 600 s.
- F_sätt siehe Nachfrage, B_skill ≤ +0,40

| Gut | P_gut | Gut | P_gut |
|---|---|---|---|
| Getreide | 0,40 | Mehl | 1,00 |
| Vieh | 0,50 | Fleisch | 1,30 (Frische) |
| Holz | 0,35 | Bretter | 0,90 |
| Erz / Kohle | 0,45 / 0,40 | Stahl / Werkzeug | 1,00 / 2,00 |

**Warum:** Der Lager-Pingpong-Exploit (Testskript `scratch_eco/_eco.gd`: zwei Lager, zwei Lkw A↔B, Ertrag pro Teilstrecke) erzeugte Geld aus dem Nichts. Mit Herkunftsstempel und Luftlinie ist das strukturell ausgeschlossen.

### Nachfrage und Sättigung
- **Warenkorb nach Stadtstufe:** Dorf (< 1.000 Einwohner) Nahrung · Kleinstadt (< 5.000) + Bau · Stadt (< 20.000) + Werkzeug, ab E2 + Benzin · Großstadt + Autos/Elektronik (E3/E4).
- Bedarfe sind **Kategorien mit Substituten**: Nahrung lässt sich mit Mehl ODER Fleisch decken (gemischt gibt +10 % Versorgung). So brauchen Städte nicht mehr „genau zwei Dinge“.
- Bedarf je Kategorie = Einwohner / 100 Einheiten/min.
- **F_sätt:** bis 100 % des Bedarfs 1,0; von 100 auf 150 % linear auf 0,4; darüber 0,1. Die Sättigung gilt für alle Lieferanten gemeinsam, also auch für den KI-Spediteur.
- **Versorgungsgrad V** (Mittel der Kategorien) steuert das Wachstum je Spielmonat: V ≥ 80 %: +2 %; 50–80 %: +0,5 %; unter 30 %: −0,5 %.

### Verkehrsmittel-Nischen

| | Lkw | Zug | Schiff | Flugzeug (E3) |
|---|---|---|---|---|
| Rolle | sammeln/verteilen, < 25 Felder | Hauptstrecke Lager ↔ Lager | Massengut, Küste/Fluss, > 60 Felder | Passagiere, Post, Elektronik |
| Kauf | 400 $ | Lok 1.500 + Waggon 300 $ | 3.000 $ + Hafen 2.500 $ | 8.000 $ + Flughafen 10.000 $ |
| Fix/min | 90 $ | 300 $ + Gleis 0,5 $/Feld | 400 $ | 900 $ |
| Variabel/Feld | 0,08 $ | 0,15 $ | 0,10 $ | 1,00 $ |
| Kapazität | 10 | 4 × 10 (bis 8 Waggons) | 200 (nur Massengut) | 30 |
| Tempo (Felder/s) | 6 | 10 | 4 | 30 |

Die Straße hat eine Kapazität von ca. 12 Lkw/min je Richtung, danach entsteht sichtbarer Stau. Das ist die natürliche Bremse für reine Lkw-Netze.

**Lager:** 800 $, Unterhalt 30 $/min, 200 Einheiten (Ausbau auf 600 / 1.500), 2 Rampen à 2 Einheiten/s, Umschlag kostet Zeit (zählt in F_zeit). **Kein eigener Ertrag.** Der Wert des Lagers ist das Bündeln: Erst durch Bündeln erreicht ein Zug volle Auslastung, und die Diagnose zeigt Füllstand und Rückstau pro Gut.

### Firmen
- **Kaufen:** Basispreis 1.000–4.000 $ × Stufe, außerhalb des Einflussradius +3 % je Feld.
- **Ausbauen:** Stufe 1–4 = 20 / 40 / 70 / 110 Einheiten/min, Kosten 2.000 / 6.000 / 15.000 $.
- **Spezialisieren** ab Stufe 2 (eine von drei, per Skill freigeschaltet): Menge +30 %, Qualität (P_gut +20 %) oder Effizienz (Unterhalt −40 %).
- **Verkaufen:** sofort zu 70 % des Firmenwerts.
- **Firmenwert** = 60 % der Investitionen + 12 × Ø Monatsüberschuss ab Werk. Der Firmenwert ist sichtbar und auch die Grundlage für KI-Übernahmeangebote.

### Energie und Konkurrenz
- **Energie:** Die Grundversorgung (100 %) ist immer da. Ein beliefertes Kraftwerk gibt allen Industrien im Radius von 25 Feldern bis zu **+25 % Produktion**, anteilig zum Versorgungsgrad. **Bremse:** Überlappende Kraftwerke addieren sich nicht (es zählt das Maximum), der Bonus wirkt nur auf die Menge und nicht auf Preise, und der Gesamtmultiplikator auf die Produktion ist auf ×1,6 gedeckelt (Energie, Pendler, Skills, Spezialisierung zusammen).
- **KI-Spediteur** (Aus / Passiv / Aggressiv, frühestens ab Meilenstein 3): Er kauft freie Firmen, beliefert Städte und frisst damit den gemeinsamen Sättigungsanteil. Er bietet auf Verträge und macht Übernahmeangebote für schwache Firmen. Sabotage gibt es nicht: Der Druck entsteht nur über Markt und Fläche.

### Late-Game-Druck: Empfehlung
**Primär: Sättigung + Alterung**, sekundär Verträge, Konkurrenz optional.
- **Alterung:** Nach der Lebensdauer (Lkw 15, Zug 30, Schiff 40 Jahre) steigt der Unterhalt um +5 %/Jahr, und Pannen erscheinen als Diagnose-Ereignis mit Ort.
- **Epochenwechsel:** Er macht alte Fahrzeuge relativ teuer. Ersetzen ist damit Optimieren und keine reine Geldsenke.
- **Verträge:** Beispiel „Liefere 400 Stahl in 10 min nach Metropole“. Sie zahlen +50 % und erzeugen Ziele im Netz.
- **Skilltree:** Skillpunkte gibt es **nur über Meilensteine, nicht über Geld**, damit Geld nicht in Boni zurückfließt.
  - Rangskills: +5–10 % je Rang, maximal 5 Ränge.
  - Deckel: Erlösboni pro Segment maximal +40 %, Kostensenkungen maximal −30 %.
  - Fähigkeiten statt Prozente, zum Beispiel „Kühlwaggon“ (halber Frischeverfall), „Lagerverbund“ (Umschlag +50 %), „Stadtticket“ (+10 % Tickets je Rang), „Konzession“ (Firmenkauf außerhalb des Einflusses ohne Aufschlag).

### Balancing-Leitlinien
1. **Kein Ertrag ohne Endabnehmer.** Lager, Umladen und Umwege erzeugen nie Geld.
2. **Kreuzung Lkw/Zug bei ca. 25 Feldern und ≥ 20 Einheiten/min.** Kosten je Einheit: Lkw ≈ 0,05 × D + 0,6 $, Zug ≈ 0,025 × D + 1,25 $. Das passt zur Prototyp-Beobachtung (gleiches Ergebnis bei ~28 Feldern). Unter 20 Einheiten/min wartet der Zug auf Ladung.
3. **Schiff schlägt Zug ab 60 Feldern und 50 Einheiten/min Massengut**, wenn Wasser vorhanden ist (keine Wegkosten).
4. **Jede Linie ist ab 10 Feldern positiv, aber keine Linie trägt mehr als 25 % des Gesamtgewinns**, weil die Sättigung vorher greift.
5. **Multiplikatoren gedeckelt:** Produktion maximal ×1,6, Erlös maximal +40 % aus Skills. Keine Quelle skaliert unbegrenzt.
6. **Druck muss lokalisierbar sein.** Jeder Ertragsverlust (Sättigung, Frische, Stau, Alterung) erscheint mit Ort und Ursache in der Linien-Diagnose.
