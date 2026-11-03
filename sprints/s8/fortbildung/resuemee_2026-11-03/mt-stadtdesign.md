# Stadt-/Level-Design: Resümee (Stand 03.11.2026)

Pfade relativ zu `/home/claude/mega-tycoon/`. Marken: [Beleg] = Datei oder URL genannt, [Eindruck] = meine Wertung.

## 1. Wie ich Spiel und Konzept heute sehe
**Kern:** Eine Karte, 512² Felder à 25 m (12,8 km, ca. 164 km² Innenfläche), die nach Eignung, nicht nach Raster besiedelt ist: gestufte Ortsordnung (E6), Umland-Modell (Sim-EW = Ort-EW + Umland) und Hierarchie B+ mit 2 Kleinstädten, 2–3 Marktflecken, 12–16 Dörfern, 6–12 Weilern (`sprints/s8/design-sprint/phase3b/15_regelwerk_v1_1.md`; `charter.md` E6, E13) [Beleg]. Orte wachsen nur bei Versorgung (E7).

**Was trägt:** Der Validator prüft 58 Regeln, alle bestanden (`phase4/stadt_welle1.md`); Orte entstehen aus Poisson-Disc mit Eignungs-Annahme; Bastis Kritik („Millimeterpapier“, Baukasten-Reviere) ist im Regelwerk adressiert [Beleg: `sprints/s7/basti_feedback_01-11.md`, `sprints/s8/feedback_02-11/basti_feedback_02-11.md`].

**Was noch Papier ist:** Der Generator läuft nur im Prototypfenster (2 × 1,6 km), nicht auf der vollen Karte. Die Stadt-KI wurde nur 12 Monate getestet (Erlenbach 244 → 307 EW), die Schritte 3, 5 und 6 des Wachstumspfads wurden nie erreicht [Beleg: `stadt_welle1.md`]. [Eindruck] Ich kann zeigen, dass Regeln gelten, aber nicht, dass die Welt als Ganzes gut aussieht und spielt.

## 2. Entwicklungsverlauf aus meiner Sicht
- **S2–S4:** Slice-Karte mit 8 Orten, handplatziert; sie war Testbett für Tobias, kein Stadtentwurf.
- **S5–S6:** HQ frei wählbar (D22). Kohlberg-Fall: M7 nach 33/24 min, Karte wurde nachgezogen statt entworfen (D24) [Beleg: `sprints/s6/block-b/tobias.md`].
- **S7, Wendepunkt:** Daniels Abnahme: 9 von 12 HQ-Vorschauen „Wagnis“, H1–H4 und M1–M8 [Beleg: `sprints/s7/abnahme/daniel_d09.md`]. Basti am 01./02.11.: Städte sind Millimeterpapier.
- **S8-Design-Sprint:** Regelwerk v1 beseitigt 18 Widersprüche (§12), v1.1 bringt Epochen-Tabelle W1–W6 und Ortsklassen je Epoche (A2, A3).
- **Prototyp Welle 1:** Generator mit 6 Abweichungen von der Vorgabe; Erlenbach wächst in 12 Monaten von 244 auf 307 EW.
- **Welle 2:** Fixpass M1–M8 und Integration I1–I12; E6 „ABW bewusst“ mit Faktoren 1,30/1,38 × W/2 als dokumentierte Abweichung [Beleg: `fixpass_w2.md`, `integration_w2.md`].

## 3. Was gut lief (belegt)
- Regeln als Zahlen, nicht als Geschmack: 58 Validator-Prüfungen (`stadt_welle1.md`).
- Entscheid E6 (gestufte Ortsordnung) beendet die Rasterstadt-Debatte sauber (`charter.md`).
- Der Rundgang ist als Aufgabenkarten vorbereitet (`phase4/aufgabenkarten_v1_1.md`).
- Die Christaller-Reihe passt nach Prüfung ordentlich auf unsere Karte (7.1).
- Abweichungen werden benannt statt versteckt (6 in Welle 1, ABW in Welle 2).

## 4. Was nicht gut lief, wiederkehrende Kompromisse
| Muster | Zähler | Beleg |
|---|---|---|
| Generator nur im Prototypfenster, Vollkarte offen | 2 (Welle 1, Welle 2) | `stadt_welle1.md`; Erfüllbarkeit ≥ 18/20 nur gefordert, nicht gemessen |
| Dokumentdrift zwischen Regelwerk-Fassungen | 2 (Clark-Evans-Band 1,0–1,6 gegen 1,2–1,7; 4 gegen 8 Richtungen) | `12_welt_regelwerk_v1.md` §12, `15_regelwerk_v1_1.md` |
| Abweichung von der Vorgabe | 6 in Welle 1, 1 bewusste in Welle 2 | `stadt_welle1.md`, `integration_w2.md` |
| Wachstum nur kurz getestet | 1 (12 Monate) | `stadt_welle1.md` |
| Klassenlücke offen | 1 (360–670 Ort-EW) | `15_regelwerk_v1_1.md` A3 |
| Mensch-Test vertagt (Rundgang wartet) | 3 (S7-Abnahme nur simuliert, Basti-Rundgang offen, Aylin-Karten) | `aufgabenkarten_v1_1.md` |
[Eindruck] Mein Hauptfehler: Ich liefere Fenster-Beweise und schließe auf die Karte. Zweimal in Folge ist das nicht dasselbe.

## 5. Wo das Spiel oder das Konzept scheitern könnte (nach Wahrscheinlichkeit)
1. **Hoch: Vollkarte sieht wie Streuung aus.** Auf 164 km² mit rund 20–25 Orten kann Poisson-Disc zufällig wirken oder Cluster bilden. Ohne Clark-Evans-Messung je Seed unbekannt. [Eindruck]
2. **Hoch: Weltkarte und Ökonomie passen nicht.** 59 % der Orte unter ca. 15 Nachfrage/min (`tobias_welle1.md` §1); Orte, die ich erzeuge, führen zu 27–35 % Bankrott.
3. **Mittel: Wachstum zu langsam oder zu schnell.** 12 Monate sagen nichts über 60 Monate; Stufen 3/5/6 ungetestet.
4. **Mittel: Klassenlücke.** Zwischen 360 und 670 Ort-EW fehlt eine Klasse (Großdorf), Orte darin haben keine Regel.
5. **Mittel: Epochenwechsel der Stadtform.** W1–W6 sind Tabellen, keine gebauten Wechsel.
6. **Niedrig-mittel: Zu wenig Marktflecken.** Theorie sagt eher 3–4 Plätze ab Marktort-Rang, wir haben 4–5 insgesamt (7.1); hier eher kein Mangel.

## 6. Meine drei wichtigsten Empfehlungen für Sprint 8
1. **Generator auf die Vollkarte (ca. 2–3 PT: Stadt 1,5, Felix 1).** 20 Seeds, Clark-Evans R je Seed, Laufzeit messen, Orte je Klasse zählen; Abnahme: Anzahl je Klasse im Regelwerk-Band und R im dokumentierten Band.
2. **Drei offene Regeln entscheiden (ca. 1 PT, Basti 15 min).** Klassenlücke (Großdorf einführen oder Bänder verschieben), ein Clark-Evans-Band (1,0–1,6 oder 1,2–1,7), Feld `lagegrund` je Ort (damit jeder Ort einen Grund hat, dort zu stehen).
3. **Stadt-KI über 60 Monate (ca. 2 PT).** Wachstumsschritte 3, 5, 6 erreichen oder als nicht erreichbar belegen; gleichzeitig mit Tobias’ Bot auf derselben Welt laufen lassen, damit Wirtschaft und Stadt nicht getrennt kalibriert werden.

## 7. Recherchen dieser Runde und Lernlog
**7.1 Christaller K = 3 und Zentrale-Orte-Abstände.** Quellen: [Geografski vestnik 39, S. 143–155](https://zgs.zrc-sazu.si/Portals/8/Geografski_vestnik/Pred1999/GV_3901_143_155.pdf) (OCR): unterste Stufe Radius 4–5 km = 45 km², Nachbarort ca. 7 km; 12 km (135 km²); 36 km (400 km²); 62 km; 108 km; Einwohner Marktort ca. 1.000–1.200, Amtsort ca. 2.000, Kreisstadt ca. 4.000. [Radeff, Réseaux Christaller](https://cyberato.org/): Kreisradien 12, 21, 36 und 21, 36, 62, 108, 188 km. Ergebnis: Die √3-Reihe ist durch zwei Quellen belegt (Einwohnerzahlen: eine Quelle). Auf 164 km² ergeben sich 3,6 Orte ab Marktort-Rang, 1,2 ab Amtsort, 0,4 ab Kreisstadt; wir haben 2 Kleinstädte plus 2–3 Marktflecken, etwas dichter, aber plausibel. Die Skill-Aussage „Marktflecken knapp“ ist aus der eigenen Reihe abgeleitet und schwächer belegt. Vorbehalt: Theorie von 1933, nicht 1820, Süddeutschland. Konfidenz mittel.

**7.2 Dorfdichte um 1800.** Quelle: [de.wikipedia, Kurmark](https://de.wikipedia.org/wiki/Kurmark): „434 Quadratmeilen“ (1804), umgerechnet ca. 24.000 km² (meine Umrechnung, 55–57 km² je Quadratmeile). Mit der Skill-Zahl 2.053 Dörfer (1801, Brandenburgikon, S12) ergibt sich ein Dorf je 11,7 km², auf 164 km² ca. 14 Dörfer, genau mitten im Regelwerk-Band 12–16. Vorbehalte: eine Region (Sand-Brandenburg), Jahr 1801 gegen 1804, Umrechnung von mir. Konfidenz mittel-niedrig.

**Nicht belegt bzw. nicht erreichbar:** Clark-Evans-Band und R_max 2,149 bleiben [~] (en.wikipedia Nearest_neighbor_analysis: url_not_found). hls-dhs-dss.ch, BLB-Heinzelmann-PDF, schule-bw ab12c.pdf nicht nutzbar. Zusammenfassungen kamen über ein kleines Modell. Reddit gesperrt, nicht umgangen.

| Datum | Situation | Kompromiss / Lücke | Zähler |
|---|---|---|---|
| 2026-11-03 | Generator | Fenster-Beweis statt Vollkarte | 2 |
| 2026-11-03 | Dokumentdrift | Band und Richtungen widersprechen sich | 2 |
| 2026-11-03 | Skill gegen Repo | Skill „Marktflecken knapp“, Zahlen sagen plausibel | 1 |
| 2026-11-03 | Klassenlücke | 360–670 Ort-EW ohne Regel | 1 |
| 2026-11-03 | Christaller | 45/135 km² und √3 belegt (7.1) | 1 |
| 2026-11-03 | Dorfdichte | 14 Dörfer auf 164 km² abgeleitet (7.2) | 1 |

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)
- A1 und B3: Christaller-Zeile mit 45 km² (4–5 km Radius) und 135 km² (12 km), Einwohnerklassen 1.000–1.200 / 2.000 / 4.000, Quellen Geografski vestnik und Radeff [Beleg, mittel]; Satz „Marktflecken knapp“ streichen oder als [A] markieren.
- B3 Dorfdichte: „ca. 1 Dorf je 12 km² (Kurmark 1801) ergibt ca. 14 auf 164 km² [R, mittel-niedrig]“.
- A-Abschnitt Clark-Evans: Band und R_max ausdrücklich [~] lassen, bis eine Primärquelle vorliegt.
- A9 neuer Fehler: „Fenster-Test als Vollkarten-Beleg“ (Zähler 2) und „Regelwerk-Fassungen widersprechen sich“ (Zähler 2).
- Lernroutine: Abschlusskriterium je Generator-Änderung: Vollkarte, 20 Seeds, Clark-Evans je Seed.
