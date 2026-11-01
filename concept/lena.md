# Lena Hoffmann – Lead Game Design

## Core Loop, Spielablauf und Onboarding

### Core Loop (Sekunden bis Minuten)
1. **Erkennen:** Bedarf/Überschuss sehen (Lagerstand, Versorgungsgrad der Stadt, Wartende an Haltestellen).
2. **Bauen:** Strecke, Haltestelle, Lager oder Signal setzen – mit Kostenvorschau und Ghost.
3. **Verbinden:** Linie anlegen, Fahrzeuge zuweisen.
4. **Beobachten:** Gewinn/min je Linie, Auslastung, Diagnose-Marker („Zug 7 wartet auf Block B3 wegen Zug 4“).
5. **Optimieren:** Engpass beheben (Gleis doppeln, Lager zwischenschalten, Fahrzeug tauschen) → zurück zu 1.

### Meta-Loop (Run, 4–10 Stunden)
1. HQ gründen, Lizenzen erwerben → Einfluss entsteht; Firmenkauf ab Meilenstein 5b. *(23.11.2026, D12; vorher „Firma kaufen“)*
2. Ketten schließen, Städte versorgen → Geld + **Ast-XP** im genutzten Spielstil.
3. Skills kaufen → neue Fahrzeuge/Fähigkeiten → größere Ketten möglich.
4. Meilensteine erfüllen → Epochenwechsel → neue Ketten und Nachfrage.
5. Szenarioziel/Firmenwert erreichen → Run-Bilanz zeigt den gespielten Stil → nächster Run mit anderem Schwerpunkt.

### Run-Phasen

| Phase | Spielerziel | Hauptentscheidung |
|---|---|---|
| **1. HQ & Lizenzen** (0–30 min) *(23.11.2026, D12)* | Erste Kette profitabel schließen, Startkapital Testannahme 4.500 / 4.500 / 7.000 / 5.000 $ (D1, revidierbar nach L-05) | Welche Stadt wird Hauptsitz, welche Industrien lizenziere ich im Radius? (legt Startast nahe, `hq.md`) |
| **2. Expansion** (30–120 min) | Zweiter Cluster, erster Hub mit Lager, Personenlinie | Organisch im Einfluss wachsen oder teuer in fremden Cluster springen? |
| **3. Epochenwechsel** (je 60–120 min) | Netz auf neue Fahrzeuge/Ketten umstellen | Was modernisiere ich zuerst, was lasse ich auslaufen? |
| **4. Late Game** | Strom- und Hightech-Ketten, Konkurrenz verdrängen | Spezialisieren (Effizienz) oder diversifizieren (Absicherung)? |

### Druck und Optimierungsbedarf
- **Engpässe:** Gleisblöcke, Umschlagkapazität von Lagern/Bahnhöfen, Straßenstau in Städten. Klemmt etwas, wird es lokalisiert angezeigt.
- **Sättigung:** Jede Stadt hat pro Gut eine Nachfragekurve. Überliefern senkt den Preis (−50 % ab 150 % Versorgung). Mehr Geld kommt also nur aus *neuen* Abnehmern oder neuen Gütern im Warenkorb.
- **Wartung:** Fahrzeuge altern (Zuverlässigkeit sinkt ab 70 % Lebensdauer), Strecken verschleißen bei Last. Ersatz kostet und bindet Kapital.
- **Konkurrenz:** KI-Spediteur (abschaltbar) kauft freie Firmen und unterbietet schlechte Linien.
- **Gegen die Idle-Kurve:** Laufende Kosten steigen mit der Netzgröße (Verwaltung +2 % je Linie über 20). Jede Epoche verschiebt die Nachfrage (Kohle sinkt, Benzin steigt), und Negativsaldo führt zu Kreditrahmen und dann zu Zwangsverkauf einer Firma. Ein Netz, das einmal läuft, bleibt nicht von allein profitabel.

### Onboarding: Meilensteine als Tutorial
| # | Meilenstein | Lernt | Belohnung |
|---|---|---|---|
| 1a / 1b | HQ gründen / Erste Lizenz im Einfluss *(D12, Nummerierung nach `hq.md`)* | Einfluss; Laden nur mit Lizenz oder Besitz | Einflussradius / +1 freier Skillpunkt |
| 2 | Lkw-Linie zum Verarbeiter | Straßenbau, Linien | +1 Skillpunkt Straße |
| 3 | Endprodukt an Abnehmer geliefert (Stadt, Export oder nächste Verarbeiterstufe) *(23.11.2026, D13; vorher „in Stadt liefern“, im Bergbau nicht erreichbar)* | Warenkorb, Versorgungsgrad, Ertrag nur bei Abgabe an Endabnehmer | Stadt-Infopanel |
| 4 | Busline in einer Stadt | Personenverkehr, Abdeckungs-Heatmap | Ast Stadtverkehr offen |
| 5 | Lager als Sammelpunkt (2 Quellen) | Umschlag, Hub-Logik | Zug freigeschaltet |
| 5b | Erste Firma kaufen *(D12, aus `hq.md`)* | Ausbau, Spezialisierung, Firmenwert | Kaufrabatt −20 % auf die nächste (einmalig, D1) |
| 6 | Erste Zugstrecke mit Signal | Blöcke, Diagnose „wartet weil …“ | Gleis-Doppelbau-Tool |
| 7 | Ziel „HQ-Stufe 2 nach 35–50 min“; die Gewinnschwelle wird erst mit dem Ausbaupfad gesetzt (M1) *(23.11.2026, D13; vorher „5.000 $/min“, mit einer Kette von 399–844 $/min nicht belegbar)* | Linienbilanz, Optimierung | HQ-Stufe 2 freigeschaltet (statt „zweite Firma vergünstigt“, `hq.md`) |
| 8 | Epochenvorschau gelesen + 1 Epoch-Meilenstein | Epochenmodell | Epoche 2 rückt näher |

**Stufen-Tor der Städte (23.11.2026, D13):** Das Tor aus `city.md` („bei 95 % der Schwelle Halt, bis Bau ≥ 25 % versorgt“) greift erst beim Übergang Kleinstadt → Stadt, nicht bei Dorf → Kleinstadt. Damit stockt der Agrar-Start (Dorf 900 Einw., kein Bau im Radius) nicht ab Minute 3. Zusätzlich garantieren die HQ-Startkarten eine Bau-Rohstoffquelle im Radius. Einzutragen in `city.md` und `hq.md` bis GDD (Tobias, Lena).

**Erfahrener Start:** Mit dem Schalter beginnt man mit Meilensteinen 1–6 als erledigt, 60.000 $ *(Skala wird in M1 gegen das D1-Startkapital neu gesetzt, 23.11.2026)*, zwei Startfirmen, allen Ästen offen und 3 freien Skillpunkten. Tutorial-Hinweise bleiben als Tooltips verfügbar.

### Abschluss eines Runs
- **Szenarioziele:** z. B. „Versorge 3 Metropolen zu 90 %“ oder „Baue die Stahlachse Nord–Süd bis 1960“, mit Bronze/Silber/Gold.
- **Firmenwert:** Endlosspiel mit Rangliste nach Firmenwert (Firmen + Netz + Kapital) zum Epochenende.
- **Sandbox:** Ohne Konkurrenz und Bankrott, alle Epochen wählbar, Skillpunkte unbegrenzt.

## Epochen, Skilltree und Unlocks

### Epochenmodell
| Epoche | Zeitraum | Typische Fahrzeuge | Neue Ketten/Nachfrage |
|---|---|---|---|
| I Dampf & Pferd | 1850–1890 | Pferdewagen, Dampflok, Raddampfer | Getreide, Holz, Vieh, Kohle |
| II Industrialisierung | 1890–1925 | Erste Lkw, Straßenbahn, Güterzüge | Stahl, Werkzeug, Kohlekraftwerk |
| III Motorisierung | 1925–1960 | Diesel-Lkw, Bus, Diesellok, Frachter | Öl/Benzin, Konserven, Ziegel/Beton |
| IV Elektrifizierung | 1960–1995 | E-Lok, U-Bahn, Container-Schiff, Sattelzug | Kunststoff, Elektrogeräte (Strom nötig) |
| V Hightech | 1995–2030 | Hochgeschwindigkeitszug, Logistikdrohne, Großcontainer | Chips, Medikamente (Strom + Fachkräfte) |

**Epochenerreichung:** Zur Epoche gehört ein Zeitfenster. Die Spielzeit allein schaltet aber nichts frei: Man braucht **3 von 5 Epoch-Meilensteinen** (z. B. „2 Ketten mit Endprodukt“, „Stadt > 5.000 Einwohner“, „Kraftwerk beliefert“). Wer schneller ist, wechselt früher, wer langsamer ist, wird nach Zeitfensterende sanft gezogen: Die Nachfrage nach alten Gütern sinkt.
**Vorschau:** Ab 1 erfüllten Meilenstein zeigt das Epochenpanel die kommenden Fahrzeuge (Werte), neue Ketten und deren Standorte auf der Karte als Silhouetten. So kann man vorplanen und muss nicht blind warten.

### Bestehende Ketten vs. neue Epochen-Industrien
Pro Epoche gibt es zwei klar getrennte Arten von Neuerungen. Das Epochenpanel zeigt sie in zwei Spalten.

| | **Weiterentwicklung** (bestehende Ketten) | **Neue Industrien** (epochengebunden) |
|---|---|---|
| Was | Getreide, Holz, Stahl usw. bekommen eine neue Ausbaustufe oder Variante (Mühle → Großmühle, Stahlwerk → Elektrostahl) | Ganz neue Ketten erscheinen erst ab ihrer Epoche (Benzin III, Kunststoff IV, Chips V) |
| Wo | An der bestehenden Firma, Standort bleibt | Neue Standorte, vorab als Silhouetten in der Vorschau |
| Spielerrolle | Upgrade-Entscheidung auf eigenem Besitz | Erkundung und Erstkauf, wie zu Run-Beginn |

**Was mit alten Industrien beim Epochenwechsel passiert.** Keine Industrie verschwindet. Jede eigene Firma bekommt beim Wechsel einen von vier Zuständen, mit Symbol auf der Karte und einer Begründung:
1. **Bleibt:** Die Nachfrage ist stabil (z. B. Nahrung). Es ändert sich nichts.
2. **Modernisieren:** Ein optionales Upgrade bringt mehr Output und neue Varianten. Die alte Stufe bleibt profitabel, nur nicht mehr optimal.
3. **Schrumpft:** Die Nachfrage sinkt langsam über 30–60 Minuten, nicht schlagartig (Kohle ab Epoche IV). Eine Warnung erscheint eine Epoche im Voraus.
4. **Umrüsten:** Die Firma wechselt zu einem verwandten Produkt der neuen Epoche (Kohlekraftwerk → Gaskraftwerk, Sägewerk → Möbelfabrik). Der Standort, die Anschlüsse und 50 % des Firmenwerts bleiben erhalten.

**Warum sich das nicht wie Entwertung anfühlt:**
- **Netz bleibt Kapital:** Gleise, Lager und Bahnhöfe passen in jede Epoche. Alte Fahrzeuge fahren weiter, bis ihre Lebensdauer endet.
- **Vorwarnung statt Schock:** Schrumpfende Güter siehst du schon eine Epoche vorher in der Vorschau.
- **Übergangsbonus:** Wer früh umrüstet, bekommt Ast-XP und einen Umbaurabatt. Wer wartet, verliert nur Rendite, keine Substanz.
- **Erfolgsgefühl:** Das Run-Ende zeigt eine Zeitleiste „Dein Stahlwerk 1880–2010“. Die Firma ist mitgewachsen.

(Die Zahlen für Nachfragekurven und Umbaukosten kommen von Tobias.)

### Lesbarkeit: Wie viel gleichzeitig?
| Größe | Obergrenze | Regel |
|---|---|---|
| Relevante Ketten gleichzeitig | 4–6 aktiv bedient, ca. 8 auf der Karte | Ein Cluster bündelt 1–2 Ketten. Die Kettenübersicht zeigt nur Ketten, die du bedienst oder für die du ein Ziel hast |
| Neues pro Epoche | max. 2 neue Ketten, 3–4 Fahrzeuge, 2–3 Modernisierungen | Mehr als „eine Handvoll Neues“ pro Wechsel gibt es nicht |
| Skills pro Ast | 3–4 Knoten je Epochenstufe, insgesamt 15–20 je Ast | Sichtbar sind nur die aktuelle und die nächste Epochenstufe, spätere Stufen sind ausgegraut |
| Schlüssel-Fähigkeiten | 1 je Ast und Epoche | Sie sind deutlich größer gezeichnet und mit einem Satz Nutzen beschrieben („Was kann ich jetzt, was vorher nicht ging?“) |
| Epochenwechsel-Info | 1 Bildschirm | Darauf stehen drei Blöcke: Neu, Wird besser, Läuft aus |

Faustregel: Ein Spieler muss zu jedem Zeitpunkt die **drei wichtigsten Dinge** benennen können, die er gerade tun könnte. Das Ziele-Panel zeigt genau drei Vorschläge.

### Skilltree = Technik-Unlocks (ein System)
- **Struktur:** 6 Äste. Jeder Ast hat pro Epoche eine Stufe mit 3–4 Knoten. Neue Fahrzeuge sind Knoten im Ast und nicht in einem eigenen Forschungsbaum.
- **Währung:** **Ast-XP durch tatsächliches Transportieren** im Bereich (Tonnen-km bzw. Personen-km). Alle 1.000 XP gibt es 1 Punkt *für diesen Ast*. Dazu kommt 1 **freier Punkt** pro Tutorial- und Epoch-Meilenstein, der in jeden Ast gesetzt werden kann.
- **Knotentypen:** Rangskills (1/3 oder 1/5, Prozentwerte) und **Schlüssel-Fähigkeiten** (1 Punkt, schalten eine neue Spielmöglichkeit frei).

| Ast | Beispiel-Skills | Schlüssel-Fähigkeit |
|---|---|---|
| **Stadtverkehr** | Stadtticket 1/5: +10 % Ticketerlöse in Städten/Rang · Taktfahrplan 1/3: −8 % Wartezeit · Haltestellendichte 1/3: +15 % Einzugsradius · Pendlerstrom 1/3: +5 % Produktivität belieferter Firmen durch Arbeiter · Straßenbahn (Fahrzeug) | **Umsteigeknoten:** Haltestellen verschiedener Linien teilen Fahrgäste, und Wunschlinien werden sichtbar |
| **Agrar & Nahrung** | Ertragsfelder 1/5: +8 % Farmproduktion · Kühlkette 1/3: −20 % Verderb · Mühlenausbau 1/3: +10 % Durchsatz · Marktstand 1/3: +6 % Preis Nahrung · Kühlwagen (Fahrzeug) | **Genossenschaft:** Farmen im Umkreis von 15 Feldern liefern automatisch an das eigene Lager |
| **Schwerindustrie** | Hochofen 1/5: +8 % Stahlausbeute · Massengutrabatt 1/3: −10 % Umschlagzeit Erz/Kohle · Werksbahn 1/3: −15 % Gleiskosten im Industriegebiet · Abwärme 1/3: +10 % Kraftwerksradius | **Spezialisierung:** Eine Industrie wird auf ein Produkt festgelegt (+30 % Output, −1 Inputgut) |
| **Schiene** | Doppelgleis 1/3: −20 % Kosten Parallelgleis · Signaltechnik 1/3: −15 % Blocklänge · Laufruhe 1/5: −6 % Zugunterhalt · Elektrifizierung (E-Lok) | **Wegerecht:** Durch Städte darf mit 50 % Abrisskosten gebaut werden, Tunnel −30 % |
| **Straße & Logistik** | Sammeltour 1/5: +5 % Lkw-Kapazität · Lagerausbau 1/3: +25 % Lagerkapazität · Kurzstrecke 1/3: −20 % Lkw-Unterhalt unter 15 Feldern · Sattelzug (Fahrzeug) | **Verteilzentrum:** Ein Lager verteilt automatisch an alle Abnehmer im Radius (Lkw-Pool statt Einzellinien) |
| **Wasser** | Tiefgang 1/5: +10 % Schiffskapazität · Kaimauer 1/3: −15 % Hafenkosten · Flussbegradigung 1/3: +10 % Tempo auf Flüssen · Containerfrachter (Fahrzeug) | **Freihafen:** Der Hafen zählt als Lager mit +50 % Umschlag und erlaubt Export (Fixpreis, keine Sättigung) |

### Warum jeder Run anders wird
- **Begrenzte Punkte:** Bis Epoche V bekommt man ca. 40 Punkte, der Baum hat ca. 110 Knoten. Man kann also 2 Äste tief oder 4 flach ausbauen.
- **Ast-XP lenkt:** Punkte entstehen dort, wo man spielt. Wer Städte bedient, wird Stadtverkehr-Spezialist, und das verstärkt den Stil des Runs.
- **Exklusivitäten:** Pro Epoche ist **1 Schlüssel-Fähigkeit aus 2 benachbarten Ästen** wählbar, z. B. Verteilzentrum *oder* Genossenschaft.
- **Kartenstart:** Startfirma und Kartenlage (Küste, Gebirge) legen den ersten Ast nahe.
- **Respec:** Rangskills kann man jederzeit zurücknehmen, das kostet 25 % der bisherigen Ast-XP. Schlüssel-Fähigkeiten sind gesperrt, bis ein Epochenwechsel ein Gratis-Respec gewährt. Fahrzeugknoten bleiben, gekaufte Fahrzeuge verschwinden nicht.
- **Run-Bilanz:** Am Ende zeigt der Bericht das Stilprofil, z. B. „62 % Schiene, 25 % Agrar“, und schlägt ein Gegenszenario vor.
