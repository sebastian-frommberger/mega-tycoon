# G-01 Progression nach M7 (Lena Hoffmann, nur Konzept, keine Balance)

**Problem (Tagebuch):** Alle 7 Ziele nach 12 min, danach 38 min dieselbe Handlung ohne Druck und Fernziel. Tobias: Plateau ab ca. 20 min, Sättigung bremst, aber niemand sagt es. Alle Zahlen unten sind Platzhalter für Tobias.
**Genre (D15):** TF2-Missionen/Endlosspiel, OpenTTD-Ziele, RE-Kampagnenziele, Anno-Stufen.

## 1. Fernziele bis 60 min (neue Welt: verteilte Industrien, Kleinstadt Radius 450 m)
Ein Ziel gilt erst, wenn die Messgröße erfüllt ist, nicht beim ersten Lkw (Bug "Ziel hakt falsch").

| # | Min | Ziel | Messgröße | Belohnung |
|---|---|---|---|---|
| F1 | 15 | Zweite Stadt versorgt | Versorgungsgrad V ≥ 50 % in 2 Städten (Regel 8: 2 Zulieferer-Typen in 6 km, also keine Stadt braucht "ihre" Kette) | Auftragsfenster (s. u.) |
| F2 | 22 | Gewinn tragfähig | Netto ≥ 1.000 $/min, 5 min gehalten, ohne offenen Kredit | 1 Skillpunkt |
| F3 | 30 | Stadt wächst durch dich | Eine Stadt passiert ihr Stufen-Tor (Dorf → Kleinstadt) durch eigene Lieferung | 1 Skillpunkt |
| F4 | 38 | Fernkette über Gelände | Linie ≥ 3 km Luftlinie, quert den Fluss (Brücke) oder ≥ 2 Hangfelder, Linien-Gewinn > 0 über 5 min | Lizenzrabatt −10 % (nächste) |
| F5 | 45 | M7: HQ Stufe 2 | 5.000 $/min Einnahmen (bestehendes Ziel) | 1 Skillpunkt |
| F6 | 52 | Ausgewogenes Netz | 3 Städte mit V ≥ 80 %, davon ≥ 1 Kleinstadt; Zug- und Lkw-Anteil je ≥ 25 % der Einnahmen | 1 Skillpunkt |
| F7 | 60 | Etappe "Bilanz" | Firmenwert ≥ 100.000 $ **und** Netto ≥ 2.500 $/min nach Unterhalt | 1 Skillpunkt + Schlüssel-Fähigkeit-Wahl |

F6 zwingt das Zug-Lkw-Gleichgewicht ins Ziel (Zug dominiert +1.091 vs. +100). Danach **Endlosspiel**: alle ca. 8 min ein neuer Auftrag mit Frist und Wahl zwischen 2 Aufträgen (TF2), plus Epoche-Ziele.

## 2. Leerlauf-Regel: keine 3 min ohne Entscheidung
Immer ≥ 1 offene Entscheidung mit **mindestens 2 Optionen unterschiedlicher Kosten**, sichtbar in der Kopfleiste. Quellen: Skillpunkt setzen, Auftrag annehmen, Warnung mit Wahl (Sättigung, Unterhalt, Lizenzende), Stufen-Tor in einer Stadt. Prüfung per Bot-Lauf: Lücke zwischen Entscheidungsereignissen ≤ 3 min, sonst Test rot.

Beispiele (Minuten ca.):
- **13:** Mühle>Stadt gesättigt (Einnahmen 879 → 647 $/min). Wahl: zweiten Abnehmer über 3 km anbinden, Lager bauen oder Linie halbieren.
- **19:** Skillpunkt bereit (F2 naht): Ast festlegen oder sparen für die Schlüssel-Fähigkeit.
- **26:** Lizenz Farm läuft in 3 min aus, +10 %: verlängern, wechseln oder Betrieb kaufen (S8).
- **33:** Gleis zur Stahlkette kostet 6.320 $ und Unterhalt je Feld. Wahl: Zug oder zweiter Lkw-Ast.
- **41:** Stadt wartet am Stufen-Tor auf Bau: Bau liefern oder Kleinstadt B bevorzugen.

## 3. Druckquellen mit Empfehlung
| Quelle | Wirkung | Empfehlung |
|---|---|---|
| **Stadtwachstum** | wächst die Stadt, steigt Bedarf (Einwohner/100), ein Stufen-Tor verlangt neue Kategorie; V < 30 % schrumpft | **Ja, Hauptquelle** (Anno-Stufen). Wachstum zieht, kein Würfelglück |
| **Nachfrageverfall/Sättigung** | F_sätt gilt für alle Lieferanten; Linien kippen nach dem 2. Lkw | **Ja, schon da.** Fehlt nur die Sichtbarkeit: Warnung "gesättigt, +x $ nur durch neuen Abnehmer" |
| **Lizenzpreise** | Verlängerung +10 % je Zyklus, Preis nach Entfernung vom HQ | **Ja, moderat.** Toast sichtbar (liegt in B-xx). Bremst Lkw-Spam, nie Bankrott |
| **Gleisunterhalt** | Unterhalt je Gleisfeld, Brücken-Zuschlag, Hang-Baufaktor nur beim Bau | **Ja.** Ziel Zug : Lkw ≤ 3 : 1 (T-15). Nimmt dem Zug den Alleinstatus |
| **KI-Konkurrenz light** | passiver KI-Spediteur frisst Sättigungsanteil an 1 Industrie/Stadt | **S8 nur Passiv**, abschaltbar, ab Min 35, kein Kauf, kein Sabotage. Aggressiv und Übernahmeangebote erst R2 mit dem Firmenkauf, sonst doppelte Last |

## 4. Etappenziele → Skillpunkte (bis 60 min: **6 Punkte**)
Quellen nur Meilensteine und Etappen, **keine Transport-XP** (Streitprotokoll). Reihenfolge nach Minute: M1b (1, frei) · F2 (22) · F3 (30) · F5=M7 (45) · F6 (52) · F7 (60). **Bis M7: 4 Punkte** (SK-01-Gefühl 3 bis 4). Etwa alle 8 min ein Punkt, damit Punkte die Lücken füllen, aber nicht allein die 3-min-Regel tragen.

Anbindung an die 3 Äste: **Etappe gibt Punkt im Ast der Leistung**, wo es passt, sonst frei.
- F2/F3 (Versorgung, Wachstum) → Agrar & Nahrung oder Straße & Logistik (Spieler wählt, Empfehlung zeigt den Ast der Leistung)
- F6 (Zug und Lkw ausgewogen) → Straße & Logistik oder Schwerindustrie
- M1b, M7 → frei (Startrichtung)
- F7 → frei plus **eine** Schlüssel-Fähigkeit (Genossenschaft, Verteilzentrum, Spezialisierung) aus 2 benachbarten Ästen

Jede Etappe zeigt vorab ihren Punkt (D21: "Etappe geschafft = Punkt").

## 5. Firmenkauf (S8) als Ziel
- Der Kauf wird angeboten, wenn die Lizenz-Firma profitabel beliefert wird (M5b, Kaufrabatt −20 % auf die nächste Firma).
- Er ist **Wahlziel neben F4**: Fernkette bauen **oder** erste Firma kaufen, beide ergeben Rabatt. Wer beides tut, bekommt bei F7 mehr Firmenwert.
- F7 nutzt den Firmenwert (60 % Investition + 12 × Monatsüberschuss) als Messgröße. Das verbindet Kauf mit der 60-min-Etappe.
- Preise erst mit den neuen Industrien kalibrieren, deshalb S8, nicht früher.

## 6. Offene Fragen an Tobias
1. Passen die Minuten F1–F7 zur Proxy-Kurve in der neuen Welt (Slice: M7 33 bis 43 min, Plateau ab 20)? Messgrößen F2 und F7 kalibrieren.
2. 6 Punkte bis 60 min, 4 bis M7: verschwinden +8 % pro Rang im Sättigungsrauschen?
3. Lizenz +10 % je Verlängerung: wie hoch, bevor es wie Strafe wirkt? Verhältnis zu Größenfaktor A2?
4. Gleisunterhalt: welcher Wert je Feld und je Brücke hält Zug : Lkw ≤ 3 : 1, ohne dass Zug sich nie lohnt?
5. KI passiv: wie viel Sättigungsanteil darf sie nehmen (Platzhalter 15 %)?
6. F6 (Anteile je ≥ 25 %): messbar und exploit-frei? Und F4 in der Welt bei Plateau-Regel lösbar auf jedem der 20 Seeds?
