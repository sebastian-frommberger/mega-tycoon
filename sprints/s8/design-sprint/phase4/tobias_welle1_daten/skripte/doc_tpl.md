# Tobias, Welle 1: Bot-Stichprobe Umland-Modell (Konflikt K1)

Phase 4, Design Sprint „Welt“, S8. Autor: Tobias (Ökonomie). Stand: 03.11.2026.
Frage: Hält die T-15-Ökonomie (Zug : Lkw 2,9 : 1, Kredit ab Minute 12, Zins 3 %/min, Bankrottquote 15/17/18 % im Band 10–30 %, M7 nach 30,4 min) unter der neuen Ortsordnung, **ohne** Kredit, Zins oder Bankrottregel neu zu kalibrieren?
Rohdaten (CSV), Skripte und die beiden Test-Hooks liegen neben dem Dokument in `tobias_welle1_daten/`.

## 1 Ergebnis in Kürze

**T-15 hält, mit einer Bedingung an das Ortsmodell. Kredit, Zins und Bankrottregel bleiben unverändert.**

| Frage | Antwort |
|---|---|
| Bankrottquote@30 gesamt (3 Standorte, 3 Welt-Draws, n = 2.700) | **17,8 %** (95 %-KI 16–19) gegen 15,6 % heute (n = 900). Im Band 10–30 % und im engeren T-16-Band 12–21 %. |
| Bankrottquote bei Dorf/Marktflecken-Senke | **hält nicht:** Senken unter etwa 15 Nachfrage/min treiben die Quote auf 27–35 % (Haberau-Kette ab Dorf ≤ 650 EW, Mittelfurt-Kette bei Dorf ≤ 550 EW oder Marktflecken 1.200 EW). Ortsmix-Erwartung: Haberau-Kette 24 %, Mittelfurt-Kette 21,5 %. Bankrott@60 steigt von 21 % auf 25 % gesamt, bei der Mittelfurt-Kette von 15 % auf 27 %. |
| Zug : Lkw 2,9 : 1 | **nicht berührt.** Gemessen wurde das Verhältnis am Eingang einer Mühle (Industrie), den die Ortsordnung nicht trifft. Nur Linien, die an einer Stadt enden, sind betroffen. |
| M7 | Skriptspieler B (T-15-Befehlsfolge): im Repo heute 36,0 min (T-15 war 30,4 min; das Repo ist seither gedriftet, siehe 2.4). Bei Senke ≥ 1.900 EW 36,0–38,2 min; bei Dorf 650 EW 52,5 min, bei Marktflecken 1.200 EW 55,4 min (außerhalb Band 35–50), bei Dorf ≤ 520 EW in 60 min nicht erreicht. |
| Erster Gewinn, erste Zahlung, Ziele Z1–Z7 | unverändert (erste Zahlung 2,5–2,7 min, Break-even-Median 11,8 / 13,6 min gegen 11,6 / 14,5 min heute, Z2–Z7 bis Minute 3,2). |
| Kapital nach 30 min | Ø 7.459 $ gegen 7.748 $ heute (−4 %). |
| Anteil ohne Abschluss | 30,5 % gegen 31,6 % heute. |
| Gegenmittel (Daten, keine Regeländerung) | Nachfrage je 100 EW × 1,25 bringt Bankrott@30 je Kette auf 16–17 %, × 1,5 auf 14–15 % (heute 14–18 %). Siehe 4. |

**Empfehlung:** Die Ortsordnung darf Dorf und Marktflecken **nicht** mit der heutigen Nachfragefunktion bedienen. In Regelwerk v1 liegt die Dorf-Nachfrage bei 8–18/min und die Marktflecken-Nachfrage bei 12–19/min (heute: Haberau 18, Mittelfurt 120). Nur die Kleinstadt (24–47/min, rund 11 % der Orte) hat Haberau-Niveau. Mit `demand_per_100` × 1,25 bis × 1,5 (oder einer Mindestnachfrage von 18/min je Senke) bleibt T-15 unverändert gültig. Details in Abschnitt 5.

{{METHODE}}

## 3 Ergebnisse

Lesehilfe: **Standort** ist die Kette, die der Bot spielt (Mittelfurt: Farm → Mühle → Mittelfurt; Haberau: 2 Farmen → Mühle → Haberau; Kohlberg: Erz/Kohle → Stahl → Werkzeug, **ohne** Stadtsenke, die Kontrolle). **(a0)** ist heute, **(a1)** die Einwohnerwerte der S7-Welt auf der Slice-Karte, **(b) W1–W3** die drei Welt-Draws der neuen Ortsordnung. Bankrott@30 ist die T-15-Größe. Bankrott@60 und die Proxy-M7-Quote ergänzen sie, weil der Bot-Kauf des Lagers (Hub) kassegesteuert ist und Bankrott@30 dadurch nicht monoton von der Nachfrage abhängt (2.4).

### 3.1 Stufe 1: das formale Design, 3 Seeds × 3 Läufe (9 Läufe je Standort)
9 Läufe lösen eine Quote von 15 % nicht auf (95 %-Intervall 2–44 %). Die Tabelle erfüllt den Auftrag und zeigt vor allem, dass die Stichprobe zu klein ist. Sie ist **keine** Grundlage für die Aussage, die Stufe 2 trägt.

{{S1}}

Lesart: Alle 9-Läufe-Zahlen liegen innerhalb der Intervalle der heutigen Quote. Das einzige sichtbare Signal (Mittelfurt W2: 1 von 3 Läufen pleite) wird in Stufe 2 bestätigt (33 % bei n = 300).

### 3.2 Stufe 2: n = 300 je Variante und Standort, gleiche Verhaltens-Seeds (gepaart)
Dieselben 300 Verhaltens-Seeds in jeder Variante: Unterschiede kommen nur aus den Ortsdaten. Die Kontrolle (Kohlberg) ist über alle Welten bitgleich, die Zeile (a1) für Mittelfurt unterscheidet sich von (a0) um 1 $.

{{S2}}

Befunde:
1. **Kleinstadt-Senken ab etwa 24 Nachfrage/min kosten nichts.** Mittelfurt W1 (2.490 EW, 24,9/min) liegt bei 14,3 % wie heute, 298 von 300 Seeds laufen gleich (je 1 Seed kippt in beide Richtungen).
2. **Dorf- und Marktflecken-Senken unter etwa 15/min kosten viel.** Mittelfurt W2 (Dorf 520 EW, 10,4/min): Bankrott@30 von 14,3 % auf 32,7 %; in 55 von 300 Seeds kippt ein vorher gesunder Lauf. Haberau W3/(a1) (Dorf 740/750 EW, 14,8–15/min): 22,0 % gegen 18,3 %.
3. **Marktflecken ist nicht besser als ein kleineres Dorf (K18-Knick).** Marktflecken 1.200 EW hat Sim-Nachfrage 12/min, Dorf 900 EW dagegen 18/min, weil der Dorf-Multiplikator ×2 beim Wechsel in die Marktflecken-Stufe entfällt. Das Regelwerk führt Marktflecken als Sim-Stufe „kleinstadt“ (×1,0) und lässt K18 „unverändert“. Gemessen: Mittelfurt-Kette 28,7 % (MF 1.200) gegen 14,7 % (Dorf 900). Ein größerer Ort ist hier der schlechtere Abnehmer.
4. **Bankrott@60 steigt stärker als Bankrott@30.** Mittelfurt W3 (Senke 1.460 EW, 14,6/min): Bankrott@30 13,0 %, aber Bankrott@60 32,0 % (heute 15,0 %). Eine knappe Senke zahlt langsamer zurück, die Lizenz-Verlängerung bei 30 min trifft dann zu viele. Die Haberau-Kette hat in **allen** Varianten 28,3 % Bankrott@60 (auch heute): das ist ein Bot-Verhalten dieser Kette und kein Effekt der Ortsordnung.
5. **Erste Zahlung und Ziele Z2–Z7 bleiben gleich.** Sie hängen an Bau, Lizenz und erster Lieferung, nicht an der Senkengröße.

### 3.3 Stufe 3: Raster nach Senken-Größe (n = 150)
Statt auf Welt-Draws zu warten, ist die Senke direkt über ihre Sim-EW gerastert. Die Spalte „Nachfrage/min“ erklärt die Reihenfolge besser als die Einwohnerzahl.

{{S3}}

Lesart: Ab etwa 15–18 Nachfrage/min ist die Mittelfurt-Kette wieder auf dem Niveau von heute (12–15 % Bankrott@30). Die Haberau-Kette braucht etwa 18/min (heute 18,0 %; bei 15,4/min 22,7 %, bei 13/min 26,7 %). Die Zeile „1.200 Kleinstadt“ (12/min) ist der K18-Knick. In den Rasterzeilen steht die Sim-Stufe: 1.200–1.900 EW sind Marktflecken-Größen mit Sim-Stufe „kleinstadt“ (×1,0). Die Zickzack-Form bei Bankrott@30 (z. B. Mittelfurt 770 gegen 650) ist der Kassen-Auslöser des Hub-Kaufs im Bot.

**Ortsmix-Erwartung.** Mit den Regelwerk-Anteilen (14 Dörfer : 2,5 Marktflecken : 2 Kleinstädte, also 76 / 14 / 10 %) und den Rastermitteln je Klasse ergibt sich für die Kette, die an ein zufälliges Sim-Ziel liefert:

| Kette | Dorf-Mittel | Marktflecken-Mittel | Kleinstadt | **Ortsmix Bankrott@30** | Ortsmix Bankrott@60 | heute Bankrott@30 / @60 |
|---|---|---|---|---|---|---|
| Mittelfurt | 22,9 % | 18,7 % | 14,3 % | **21,5 %** | 30,0 % | 14,3 / 15,0 % |
| Haberau | 25,5 % | 25,3 % | 15,3 % | **24,4 %** | 34,9 % | 18,3 / 28,3 % |
| Kohlberg (Kontrolle) | – | – | – | 14,0 % | 20,0 % | 14,0 / 20,0 % |
| **Mittel der drei Ketten** | | | | **20,0 %** | 28,3 % | 15,6 / 21,1 % |

Im Mittel bleibt die Quote im Band 10–30 % und nahe der Obergrenze des engen Bands (12–21 %). Für die einzelne Dorf-Kette liegt sie darüber.

**Anteil der Orte unter 15 Nachfrage/min** (Gleichverteilung in den Regelwerk-Bändern): Dorf 70 % (Sim-EW < 750), Marktflecken 43 % (Sim-EW < 1.500), Kleinstadt 0 %. Über die Ortsmischung sind das **59 % aller Orte**. Ein Mensch wählt die Senke, der Bot nicht (2.4, Annahme 2): in der Praxis ist die Wirkung kleiner, solange große Orte in Reichweite liegen.

### 3.4 Stufe 4: Skriptspieler B und C (Kennlinie über die Senke von Mittelfurt)
Deterministische Befehlsfolgen aus T-15 Block A, 1:1 als Spielbefehle. B ist die Mehlkette von HQ Kohlberg, C die Kohlberg-Kette mit Mittelfurt-Ast ab 18:06. Zielband M7: 35–50 min.

{{S4}}

Befunde:
- **B ist heute 36,0 min, nicht 30,4 min wie in T-15.** `tools/play.sh` mit denselben Befehlen weicht ebenfalls ab (12.595 $ gegen 14.318 $ Kasse bei 31:54). Das Repo ist seit T-15 gedriftet. C stimmt (39,8 gegen 39,4 min). Die Ortsordnung ist dafür nicht verantwortlich: Bis 3.550 EW Senke ist B bitgleich zur Basis.
- B bleibt im Band 35–50 min bis Senke 1.460 EW (48,7 min). Bei Marktflecken 1.200 EW (55,4 min) und Dorf 650 EW (52,5 min) fällt B hinaus, bei Dorf 520 und 400 EW wird M7 in 60 min nicht erreicht.
- C ist robuster, weil der Kohlberg-Teil nicht von der Senke abhängt: 39,8 bis 45,3 min bis zur Senke 520 EW, bei 400 EW (8/min) nicht erreicht.
- **Kein Lauf geht pleite.** Das sind Spielende, die wissen, was sie tun. Die Bankrottquoten kommen aus dem Bot (Stufe 2), nicht aus der Ökonomie.

### 3.5 Zielzeiten Z1–Z7 (Median, Stufe 2)

{{ZZ}}

Z1–Z7 sind von der Ortsordnung unberührt (Z7 bei Minute 3,0–3,2 in allen Varianten). Z3/Z4 bei Kohlberg (Median 8,2 min, nur bei 47 % der Läufe als erfüllt gezählt) beschreibt das Bot-Verhalten dieser Kette und ist zwischen (a0) und (b) identisch; die Ursache wurde nicht untersucht.

### 3.6 Bewertung gegen T-15

| Kriterium T-15 | Soll | Messung mit neuer Ortsordnung | Urteil |
|---|---|---|---|
| Bankrott@30, gepoolt | 10–30 % (T-16: 15/17/18 %) | 17,8 % (16–19), n = 2.700; Ortsmix 20,0 % | hält |
| Bankrott@30, Kette mit Dorf-/MF-Senke | 10–30 % | 22–35 % bei Senken < 15/min (Mittelfurt W2 32,7 %, Haberau Dorf ≤ 650 27–31 %) | hält nicht an der Kante |
| Kredit ab Minute 12, Zins 3 %/min | unverändert | nicht verändert; Kredit-Mix im Bot gleich | hält |
| Zug : Lkw 2,9 : 1 | unverändert | nicht berührt (Industrie-Eingang, kein Ort) | hält (nicht neu gemessen, folgt aus dem Code) |
| M7 | 35–50 min | B: 36,0 bis 48,7 min bei Senke ≥ 1.460 EW; 52,5–55,4 min bei Dorf 650 / MF 1.200; C: 39,8–45,3 min bis Dorf 520 | hält für Kleinstadt, nicht für schwache Senken |
| Kapital nach 30 min | – | Ø 7.459 $ gegen 7.748 $ | hält |
| ohne Abschluss | – | 30,5 % gegen 31,6 % | hält |

## 4 Gegenmittel (Stufe 5): Nachfrage je 100 EW × k
Nur Daten: `demand_per_100` (Sim-EW × k, Stufe unverändert). Gleiche Welt-Draws und Seeds 1–150 wie Stufe 2.

{{S5}}

**Stufenfolge k = 1,0 / 1,25 / 1,5 (gepoolt je Kette, n = 450):** Mittelfurt Bankrott@30 21,6 → 16,7 → 14,9 %, Bankrott@60 28,4 → 24,7 → 21,1 %; Haberau Bankrott@30 19,3 → 16,0 → 14,0 %. **×1,25 reicht schon, um Bankrott@30 in das T-16-Band (12–21 %) zu bringen**, ×1,5 holt zusätzlich Bankrott@60 näher an heute (Mittelfurt heute 15,0 %). Die Proxy-M7-Quote der Mittelfurt-Kette steigt von 48 % auf 56 % (heute 58 %).

Lesart: Mit ×1,5 sinkt Bankrott@30 gepoolt auf 14,9 % (Mittelfurt) und 14,0 % (Haberau), also auf oder unter das heutige Niveau (Mittelfurt 14,3 %, Haberau 18,3 %) und ins T-16-Band. Mittelfurt Bankrott@60 sinkt von 28,4 auf 21,1 %, Haberau bleibt bei 30,7 % (Bot-Verhalten dieser Kette, siehe 3.2). Ein Rest bleibt: Dorf mit 400–600 EW liegt auch bei ×1,5 nur bei 12–18/min (Mittelfurt W2: 780 EW × 2 = 15,6/min, Bankrott@60 noch 30,0 %). Die Mindestnachfrage von 18/min je Senke (= heutiges Haberau) behebt das, weil jede Senke dann mindestens so gut ist wie die Haberau-Kette heute. Dieser Fall ist über das Raster (900 EW Dorf, 18/min) gemessen, nicht als eigene Regel gelaufen.

## 5 Empfehlung

**1. T-15 bleibt.** Kredit ab Minute 12, 3 %/min Zins, Bankrottregel und Zug : Lkw 2,9 : 1 werden **nicht** angepasst. Die Messung findet keinen Hebel in diesen Werten, der das Problem löst (Stufe 5 löst es über die Nachfrage, nicht über Zins oder Kapital).

**2. Das Ortsmodell muss die Nachfrage nachführen**, sonst kippt die Ökonomie bei Dorf- und Marktflecken-Senken. Zwei Wege, beide nur Daten (`economy_slice.json`/Ortsdaten):

| Weg | Wirkung (gemessen) | Aufwand | Bewertung |
|---|---|---|---|
| **A: `demand_per_100` × 1,25 bis × 1,5** für alle Orte | ×1,25: Bankrott@30 16,7 % (Mittelfurt) und 16,0 % (Haberau), Bankrott@60 Mittelfurt 24,7 %. ×1,5: 14,9 % und 14,0 %, Bankrott@60 Mittelfurt 21,1 %. Bei ×1,5: Dorf 400–900 EW → 12–27/min, Marktflecken 1.200–1.900 EW → 18–29/min, Kleinstadt 36–70/min. | eine Konstante | **Empfohlen, ×1,5** (×1,25 ist die untere Grenze). Direkt getestet. Hebt das ganze Niveau über die 15/min-Schwelle. Das Dorf mit 400–600 EW (12–18/min) bleibt knapp. Der K18-Knick bleibt (siehe 3). |
| **B: Mindestnachfrage 18/min je Senke** (Boden unter der Funktion) | jede Senke so gut wie Haberau heute (Bankrott@30 18,3 %); Marktflecken- und Dorf-Größe wirken dann nur oberhalb von 18/min | eine Zeile in `city_demand` | Ergänzung zu A, wenn Dorf 400–600 EW im Spiel nicht schlechter sein soll als heute. Rasterwerte (900 Dorf, 1.900 MF) zeigen es; kein eigener Lauf. |

**3. K18 (Marktflecken unter Dorf) ist ein eigenes Thema, kein Ökonomie-Problem mehr, sobald 2 gilt.** Eine größere Stufe sollte nie weniger Nachfrage haben als eine kleinere. Weg A hebt beide Stufen gleich an und lässt das Verhältnis: Marktflecken 1.200 EW (18/min) bleibt unter Dorf 900 EW (27/min). Knickfrei wird es, wenn der Marktflecken-Multiplikator von 1,0 auf mindestens 1,5 steigt (MF 1.200 EW = 18/min bei k = 1, gleich Dorf 900 EW heute, im Raster gemessen: 14,7 % Bankrott@30 in der Mittelfurt-Kette). Der Gegenvorschlag, den Dorf-Multiplikator ×2 abzuschaffen, ist schlechter: Er senkt die Dorf-Nachfrage auf 4–9/min.

**4. Zielband beibehalten:** Bankrott@30 10–30 %, T-16-Messwert 15/17/18 %, engeres Band 12–21 %. Nach A (×1,25 und ×1,5) liegen alle gemessenen Mittelwerte darin. Die Prüfung nach der Änderung ist ein erneuter Lauf von Stufe 2 mit `k` im Ortsdatensatz (derselbe Hook, 20 min).

**5. Für S8 vormerken:** Die Test-Hooks `p4_umland_bot.gd` und `p4_umland_bot2.gd` wandern als Regressionstest in `tests/` (sie ändern nichts am Spiel). Wenn die Welt-Generierung steht, die Stichprobe auf der echten Welt (S7-Karte, bis zu 21 Knoten) wiederholen: das Slice hat nur 8 Orte.

## 6 Zusatzfrage: Schwierigkeits-Presets bei 15 % passivem Konkurrenzanteil (Skizze für S8)

Schnell, aus den Daten, ohne neuen Lauf. Annahmen: erste Näherung, siehe 6.3.

### 6.1 Presets (Start, Zins) gegen die Zielquoten aus `04_schwierigkeit.md`
Zielquoten: Leicht ≤ 5 %, Normal 15–18 %, Schwer 30–40 %. Die Zahl ist Bankrott@30, geschätzt aus dem Verlauf der Mindestkasse der Läufe (Kapital-Verschiebung gegenüber 6.000 $, Zinsdifferenz auf die mittlere Kredit-Exposition). Drei Ortszustände: **A heute**, **B Dorf 650 EW als Senke** (Worst-Case der neuen Ordnung), **C mit Gegenmittel ×1,5**.

| Preset (Kapital / Zins) | A heute | B Dorf 650 | C ×1,5 | Ziel |
|---|---|---|---|---|
| Leicht 9.000 $ / 2 % | 0,0 % | 0,0 % | 0,0 % | ≤ 5 % |
| Leicht 8.000 $ / 2 % | 0,2 % | 0,2 % | 0,2 % | ≤ 5 % |
| Leicht 7.000 $ / 2 % | 0,9 % | 0,9 % | 0,9 % | ≤ 5 % |
| Normal 6.000 $ / 3 % | 16,9 % | 20,9 % | 15,2 % | 15–18 % |
| Normal 6.500 $ / 3 % | 1,1 % | 1,1 % | 1,1 % | (Empfindlichkeit) |
| Schwer 5.500 $ / 4 % | 19,8 % | 26,0 % | 19,1 % | 30–40 % |
| Schwer 5.000 $ / 4 % | 27,6 % | 30,7 % | 27,4 % | 30–40 % |
| **Schwer 4.500 $ / 4 %** | **34,2 %** | **34,2 %** | **34,0 %** | 30–40 % |

Lesart:
- **Normal und Schwer treffen das Ziel** (16,9 % und 34,2 % bei heutigen Orten; mit ×1,5 15,2 % und 34,0 %). Ohne Gegenmittel steigt Normal bei einer Dorf-Senke auf 20,9 %, also leicht über das Band.
- **Leicht erfüllt „≤ 5 %“ mit großer Reserve** (0 %): Auch 7.000 $ / 2 % reichen (0,9 %). Der Abstand 9.000 $ gegen 6.000 $ ist größer als nötig. Hinweis: Die Schätzung nimmt gleiche Entscheidungen des Bots an. Ein Mensch mit mehr Geld kauft mehr, die Zahl ist hier optimistisch.
- **Die Quote ist steil in der Mitte:** 500 $ Startkapital verschieben Normal von 16,9 % auf 1,1 %, bei Schwer 5.000 $ → 5.500 $ um 8 Punkte. Die Läufe, die pleite gehen, fehlen meist nur wenige hundert Dollar. Preise für Presets deshalb in 500-$-Schritten messen, nicht schätzen.
- Der in `04_schwierigkeit.md` vorgesehene **Nachfrage-Hebel Schwer ×0,8** (Leicht ×1,25) wirkt wie k < 1 auf die Orte. Er trifft vor allem Dorf-Senken (18/min → 14,4/min; Stadt-Senken nicht). Mit Gegenmittel A (×1,5) und Schwer ×0,8 liegt die Dorf-Nachfrage netto bei ×1,2, zwischen den gemessenen Punkten ×1,0 und ×1,5. Nicht gemessen.

### 6.2 15 % passiver Konkurrenzanteil
Modell: Die Senken-Nachfrage sinkt um 15 % ab Startminute der Konkurrenz (Leicht Minute 45, Normal 35, Schwer 20). Die Ertragsfunktion der Senke kommt aus dem Raster (Stufe 3). Ertragsfaktor der Senke bei 15 % passiv:

| Senke (Nachfrage/min) | 8 | 10 | 13 | 16 | 18 | 24 | 40 und mehr |
|---|---|---|---|---|---|---|---|
| Haberau-Kette | 0,85 | 0,86 | 0,85 | 0,88 | 0,93 | 1,00 | 1,00 |
| Mittelfurt-Kette | 0,85 | 0,87 | 0,86 | 0,93 | 0,97 | 1,00 | 1,00 |

Wirkung auf einzelne Fälle (Bankrott@60 und Anteil Läufe mit Proxy-M7 in 60 min, vorher → nachher):

| Fall | Leicht (ab 45) | Normal (ab 35) | Schwer (ab 20) |
|---|---|---|---|
| Haberau-Kette, Senke 900 Dorf (18/min, heute) | Bankrott@60 30,7 → 30,7 % | 30,7 → 30,7 % | 30,7 → 30,7 % |
| Haberau-Kette, Senke 550 Dorf (11/min) | 30,7 → 34,0 % | 30,7 → 41,3 % | 30,7 → 56,0 % |
| Mittelfurt-Kette, Senke 12.000 Stadt | M7 56 → 56 % | 56 → 56 % | 56 → 56 % |
| Mittelfurt-Kette, Senke 650 Dorf (13/min) | M7 56 → 41 % | 56 → 39 % | 56 → 29 % |

Lesart:
- **Kleinstadt- und Stadt-Senken (≥ 24/min) verlieren nichts.** Dort ist die Nachfrage ohnehin gesättigt, 15 % weniger fallen in den Überschuss.
- **Dorf-Senken verlieren 3–15 % Ertrag** (0,85 bei 8–13/min, 0,93 bei 18/min). Die Wirkung liegt bei Bankrott@60 und der M7-Erreichung, **nicht bei Bankrott@30**, solange die Konkurrenz nach Minute 30 einsetzt (Leicht 45, Normal 35). Nur Schwer mit Start bei Minute 20 greift in das 30-Minuten-Fenster.
- **Folgerung für die Presets:** Mit Gegenmittel A (Dorf-Senken ≥ 12/min bis 27/min) und einer Konkurrenz, die erst nach Minute 30 greift, müssen Kapital und Zins der Presets für 15 % passiven Anteil **nicht** angepasst werden (Schwer 4.500 $ / 4 % bleibt). Wenn die Konkurrenz bei Schwer ab Minute 20 das Band nach oben verlässt (über 40 %), ist das Startkapital der Hebel: 500 $ mehr senken die Quote um 6–7 Punkte (4.500 → 5.000 $: 34,2 → 27,6 %). Ohne Gegenmittel A erhöht die Konkurrenz Bankrott@60 bei schwachen Haberau-Senken um 3–25 Punkte (Normal 41,3 %, Schwer 56,0 %).

### 6.3 Annahmen und Grenzen der Zusatzfrage
- Erste Näherung ohne Lauf. Kapital-Verschiebung und Zinsdifferenz werden aus der Mindestkasse der 450 bzw. 1.350 Läufe geschätzt (gleiche Entscheidungen angenommen). Die Rahmen und Sperren (Leicht 3.000 $ ab Minute 6, Schwer 1.500 $) sind offline nicht abbildbar.
- Konkurrenz als reiner Nachfrageverlust (kein Preiskampf, keine Ortswahl durch die KI). Die Startminuten (45/35/20) sind eine Annahme.
- Preise der Lkw, Bankrottregel (Zwangsverkauf unter Rahmen) und Nachfrage-Hebel der Presets sind nicht in die Näherung eingegangen.

## 7 Annahmen und Grenzen (Gesamt)
1. **Slice-Karte, 8 Orte.** Die Stichprobe prüft die Nachfrage je Senke, nicht die Wegewahl in einer dichten Welt mit 15–21 Knoten. Mit mehr Orten gibt es bessere Senken in Reichweite: Die Bot-Zahlen sind für Dorf-Senken eine **Obergrenze** des Schadens.
2. **Der Bot ist passiv.** Er wählt die Senke nicht nach Größe und kauft Lkw nach dem Angebot (20 E/min), nicht nach der Nachfrage. Ein Mensch würde bei einem schwachen Dorf weniger Lkw kaufen oder den größeren Nachbarn beliefern.
3. **Hub-Artefakt.** Der Bot kauft das Lager kassegesteuert. Dadurch ist Bankrott@30 nicht monoton in der Nachfrage: In einzelnen Läufen geht ein Lauf mit **weniger** Nachfrage nicht pleite, weil der Hub-Kauf später fällt (zu sehen in Stufe 3 bei Mittelfurt 770 gegen 650). Bankrott@60, Nettokapital und Proxy-M7 sind als Ergänzung ausgewiesen. Es ist kein Fehler der Simulation.
4. **Repo-Drift seit T-15.** Skriptspieler B ergibt heute 36,0 statt 30,4 min. Die Absolutzeit von M7 ist darum nur im Vergleich zwischen Varianten zu lesen. Die Ursache der Drift liegt nicht in der Ortsordnung (B ist bei großen Senken bitgleich zur Basis) und wurde nicht weiter verfolgt.
5. **Sim-EW und Sim-Stufe:** Die Sim-EW der Orte sind in den Welt-Draws gleichverteilt im Band des Regelwerks v1 (Dorf 400–900, MF 1.200–1.900, Kleinstadt 2.400–4.700), gerundet auf 10. Die drei Draws sind nicht ausgewählt oder nachgeführt. Der Ortsmix (3.3) setzt die Regelwerk-Anteile 14 : 2,5 : 2 und die Rastermittel ein.
6. **Sim-Stufe MF → „kleinstadt“** (Multiplikator ×1,0) folgt Regelwerk v1 und `15_regelwerk_v1_1.md`. Wird die Sim-Stufe „dorf“ für MF gewählt (×2), verschwindet der Knick, aber MF 1.200–1.900 EW hat dann 24–38/min.
7. **Kein Wachstum im Slice.** Die `wachstum`-Daten sind im Code nicht verdrahtet, die Einwohner sind statisch. „Umland fest ab Generierung“ gilt damit trivial. Eine Messung mit Wachstum ist in der Stichprobe nicht enthalten.
8. **Stufe 3 und Stufe 5 mit n = 150** statt 300 (die Maschine war durch Regressionsläufe anderer Agenten ausgelastet). Das 95-%-Intervall bei 15 % beträgt ±6 Punkte. Aussagen stützen sich auf die gepoolten Tabellen (n = 450, ±3 Punkte).
9. **Erste-Näherung-Anteile** der Presets und der Konkurrenz (Abschnitt 6) sind Schätzungen aus Messdaten, keine Läufe.

## 8 Reproduktion
Skripte in `tobias_welle1_daten/skripte/`. Hook-Lauf (Beispiel, Mittelfurt-Kette, Welt W2, n = 300):

```
godot --headless --path slice -s res://tests/p4_umland_bot.gd -- --n=300 --seed0=1 --label=b_w2 --stadt=mittelfurt --min=60 \
  --orte=kohlberg:2530:kleinstadt,lindach:1580:kleinstadt,weidenau:2670:kleinstadt,seehafen:660:dorf,eichwald:890:dorf,mittelfurt:520:dorf,steinbach:1390:kleinstadt,haberau:1580:kleinstadt \
  --csv=s2_b_w2_mittelfurt.csv
```

Die Welt-Draws erzeugt `gen_orte.py` (Seeds 1–3). Der Beispielaufruf zeigt die Draw-Werte von W2 (Stufe 2, k = 1,0). Für Stufe 5 (k = 1,5) sind alle Sim-EW mit 1,5 multipliziert und auf 10 gerundet.

Dateien: `stufe1_*.csv` (Stufe 1), `s2_*` (Stufe 2), `s3_*` (Raster), `s4_skript_B/C.csv` (Skriptspieler), `s5_*` (Gegenmittel), `kontrolle_a0_n100.csv` (Hook-Kontrolle gegen d08, n = 100). Die Hooks `p4_umland_bot.gd` (Bot) und `p4_umland_bot2.gd` (+ Spalten, + Skript-Modus) liegen in `slice/tests/` der Arbeitskopie (Kopien in `tobias_welle1_daten/hooks/`); keine Bestandsdatei wurde geändert.
