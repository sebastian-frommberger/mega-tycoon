# Stadt-/Level-Designer, Phase 4 Welle 1: Orte, Instanzen, Wege, Wachstum

Stand 03.11. Arbeitskopie `/tmp/claude-0/gd/designsprint/p4/stadt/`, nichts committet. Alles deterministisch (Seed 7, eigener PCG32 mit FNV-Seed, gerundete Ausgabe, nur numpy und Standardbibliothek); zweimal erzeugt, md5 aller vier Dateien gleich (`stadt_gen.py --md5`).

## Dateien

| Datei | Inhalt |
|---|---|
| `slice/world/data/proto/proto_orte.json` | `{orte:[{id,name,klasse,ew,x,z,r_m,…}]}` plus `industrie`, `gewaesser`, `parzellen`, `_meta` (Abstände, See-Nutzung, Mauer, Kreuzungen) |
| `slice/world/data/proto/proto_instanzen.json` | 1049 Instanzen `{typ,x,z,rot_deg,parzelle,ort,[b,t,variante,rolle]}`, eine Zeile je Instanz |
| `slice/world/data/proto/proto_wege.json` | 15 Wege `{id,typ,name,breite_m,punkte,laenge_m,max_steigung_pct,…}`; die Chaussee trägt `bruecken`, `allee`, `trasse_m` |
| `slice/world/data/proto/proto_vorher_nachher.json` | Erlenbach Monat 0 / Monat 12 ohne und mit Versorgung, Aktionen, Instanz-Diff |
| `tools_proto/stadt_gen.py` | Hauptprogramm (`--bilder`, `--md5`), dazu `stadt_geo.py` (Gelände, PCG, A*), `stadt_wege.py`, `stadt_bau.py` (Hofstellen), `stadt_dorf.py` (Parzellen), `stadt_wachstum.py`, `stadt_out.py`, `stadt_bilder.py` |
| `tools_proto/stadt_validate.py` | Validator, Tabellenausgabe, Exit-Code 1 bei hartem FAIL |
| `_out/bilder/` | `uebersicht.png` (Monat 0, Monat 12, Gesamt), `bild_dorf_vorher_nachher.png`, `bild_dorf_monat0/12(.._ohne_versorgung).png`, `bild_gesamt.png`, `bild_markt.png` |

Aufruf: `python3 tools_proto/stadt_gen.py --bilder --md5` (ca. 40 s), danach `python3 tools_proto/stadt_validate.py`. Höhen und Fluss kommen direkt aus `ws_c/_out/ds_v2/` (Fenster laut Vorgabe, bilinear), nicht aus den TA-Dateien.

## Orte

| Ort | Klasse | EW | Gebäude | Lage (x / z) | r_m |
|---|---|---|---|---|---|
| Erlenbach | Dorf (Haufendorf) | 244 | 34 Wohnhäuser (12 Kate, 18 Bauernhof, 4 Handwerkerhaus) + Kirche, Gasthaus, Schmiede = 37; 44 Parzellen, davon 7 Lücken | 1690 / 720, Kreuzung 1625 / 730 | 190 (r_max 210) |
| Hasenwinkel | Weiler | 48 | 6 Bauernhöfe | 760 / 857 | 70 |
| Lindenfurt | Kleinstadt, Markt-Ausschnitt | 387 (nur Ausschnitt) | 20 Bürgerhäuser, 14 Handwerkerhäuser, Stadtkirche, Rathaus, Gasthaus, Speicher = 38, dazu Stadttor | Marktmitte 96 / 138, Tor 267 / 241 | 200 |
| Gut Kuppenhof | Getreidefarm | – | Vierseithof 40 x 40 auf der Kuppe (Plateau 61 m), 3 Schläge 200 x 125 m | 1935 / 1355 | – |
| Erlenmühle | Wassermühle | – | 12 x 12 m mit Wasserrad, 16 m östlich der Bachachse, 15 m vom Mühlteich | 1617 / 1090 | – |

Namen erfunden: Rotach (Fluss), Binsensee, Erlenbach (Bach und Dorf).

Abstände (Mitte zu Mitte): Dorf–Weiler 0,94 km (Kreuzung–Weiler 0,84 km), Dorf–Lindenfurt 1,70 km, Dorf–Gutshof 0,70 km, Dorf–Mühle 0,36 km, Gut–Mühle 0,43 km.

Lagebegründung (06_verteilung): Dorf auf dem flachen, aue-freien Streifen östlich des Bachs mit Kirche auf der höchsten Stelle (≤ 62 m um die Kreuzung); Weiler im westlichen Streifen mit 190 m Abstand zum Seeufer; Markt am Nordufer-Kernrand, Tor Richtung Brücke; Gut auf der Kuppe, weil nur dort Plateau mit ≤ 6 % für drei Schläge existiert.

### Dorf-Aufbau

Haufendorf: Hauptkreuzung mit Chaussee (West), Hauptstraße (Ost, 297 m, gekrümmt), Kirchstraße (Süd), Bachstraße (Nord); dazu Kirchgasse (Schleife) und Bachgasse. Hofstellen werden nach Abstand zur Ortsmitte plus Rauschen belegt (Annahme p = 1 − (d/r)², Slots alle 12,5 m), dadurch Haufen statt Zeile. Typenquote nach Lage: Handwerker kernnah, Kate am Rand, Bauernhof gemischt. Je Hofstelle: Haupthaus, 0–2 Nebengebäude (Scheune 18 x 10, Stall, Schuppen), Hof- und Gartenfläche, Zaun (6–20 Latten), Obstbaum, Heuhaufen, Holzstapel. Belebung: Brunnen, 6 Passanten, 26 Etter-Obstbäume, 7 Lücken mit Obstwiese. Kein Schachbrett: Clark-Evans R = 1,51 (n = 37; 1 = Zufall, > 2 = Raster).

Weiler: 6 Höfe an einer Y-förmigen Gasse am Ende des Hasenwinkelwegs.

Kleinstadt-Ausschnitt: Markt 80 x 60 m (80 m entlang der Streifenachse) mit Brunnen und 10 Passanten, Stadtkirche (35 x 15) an der Westseite, Rathaus Südseite, Gasthaus Ostseite, Speicher an der Marktstraße, geschlossene Zeilen mit 10–12,4 m Front um den Markt, an der Marktstraße und an der Hintergasse. Tor 200 m von der Marktmitte; Mauerbogen R 200 m in `_meta.mauer` (3 Stücke, Bresche im Nordteil, ca. 70 % erhalten). Die Stadt setzt sich außerhalb des Kerns nach Westen fort, daher "Ausschnitt".

Gelände-Regeln hart: Rinne ≥ 55 m, See ≥ 45 m jenseits r_eff (TA-Formel mit Uferrauschen), Mühlteich ≥ 15 m, Bach ≥ 20 m (TA-Gehölzsaum 17,5 m), Hang ≤ 6 %. Weich: Aue (35 % des Kerns in zwei Bändern); nur 1 von 44 Dorfparzellen und keine der anderen liegt mit dem Mittelpunkt darin.

## Wege

| Weg | Typ | Breite | Länge | max. Steigung (10 m) |
|---|---|---|---|---|
| Chaussee Erlenbach–Lindenfurt | chaussee | 6 (Trasse 11) | 1676 m | 4,0 % |
| Hauptstraße / Kirchstraße / Bachstraße | dorfstrasse | 6 | 297 / 127 / 79 m | ≤ 0,9 % |
| Marktstraße (Lindenfurt) | dorfstrasse | 6 | 160 m | 0,3 % |
| Kirchgasse / Bachgasse / Hintergasse | gasse | 5 | 161 / 77 / 212 m | ≤ 0,9 % |
| Mühlweg / Gutsweg / Hasenwinkelweg / Ostweg / Fischerpfad / 2 Weiler-Äste | feldweg | 3,5 | 218 / 503 / 637 / 137 / 105 / 65 + 63 m | Gutsweg 9,99 %, Rest ≤ 1,6 % |

Summe ca. 4,0 km. Chaussee: min. Krümmungsradius 54 m (Soll ≥ 50), max. Richtungswechsel 25,7 Grad je 6 m, keine Zickzacklinie. Alle Wege sind A*-Trassen (Kosten Steigung, Drehung, Aue, Flussnähe) → Vereinfachung → Catmull-Rom → 4–6 m Abtastung.

Brücken in `chaussee.bruecken`:
- **Rotachbrücke** (Steinbogen) bei x = 1290, von z 650 nach 525: schmalste gerade Stelle der Rinne (75 m, drei Felder), 5 Brückenfelder (⌈75/25⌉ + 2 Rampen) = 125 m, 5 Bögen à 15 m, 7 m breit, Widerlagerhöhen 43,96 / 43,17 m, Wasserspiegel 36,4 m. Rampenanteil: 25 m je Ufer, Chaussee-Band läuft über das Brückenmesh.
- **Bachbrücke** (Nature `bridge_stoneRound`, Spann 8 m) bei 1462,5 / 728,1, Bach im Feld, kein Brückenfeld.

Allee: zwei Abschnitte (s 186–354 m und 522–1650 m, zusammen 1296 m), 213 Bäume, Laubbaum und Eiche im Wechsel, 7 m von der Achse, Takt 12 m, ausgespart am Dorf, an beiden Brücken, am Tor, an Wegeinmündungen. Als Instanzen mit `parzelle:"allee"`, als Abschnitte mit Teilpolylinie im Wegedict.

Knoten (`_meta.kreuzungen`, 13): Hauptkreuzung Erlenbach (4-armig) und 12 T-Einmündungen; das Wegenetz hat eine Zusammenhangskomponente (Validator). Fischerpfad führt von der Hütte zur Chaussee, Mühl- und Gutsweg sind verbunden.

## Wachstum (A10), Erlenbach

Regeln aus 12_regelwerk_v1_1 `wachstum`: Reihenfolge Lücke, Upgrade, Teilung, Vorstadt, Gasse, Platz; verdichten vor ausdehnen; max. 1 + ort_ew_soll/500 Aktionen je Monat; 8 EW je Aktion; Haus-Ruhe 3 Monate; Kate → Handwerkerhaus ab 300 Ort-EW, Bauernhof → Großhof ab 250 EW und 30 m Nachbarabstand; RNG `PCG(hash(welt_seed, ort_id, monat))`.

| | Monat 0 | Monat 12 ohne Versorgung | Monat 12 mit Versorgung |
|---|---|---|---|
| EW | 244 | 244 (stabil, 0 Aktionen, E7) | 307 (+63) |
| Aktionen | – | 0 | 12: 7 Lücken (Mon. 1–7), 3 Upgrades Hof → Großhof (8–10), 1 Vorstadt-Hof (11), 1 Upgrade Kate → Handwerkerhaus (12) |
| Gebäude | 12 Kate, 18 Hof, 4 Handwerker | gleich | 16 Kate, 18 Hof, 3 Großhof, 5 Handwerker, +1 Hof in der Vorstadt |

Annahmen: Sim-EW 650 (Dorf typ.), Umland 406 fest (Regelwerk `umland_modell`: Wachstum nur im Ort), Rate 1,8 % je Monat bei Versorgung (Konstante `RATE_BP`, economy `wachstum.band` nicht gelesen). Das Ort-Soll steigt auf 399, der Ort bleibt wegen max. 1 Aktion/Monat bei 307 zurück (Rückstand wird nicht aufgeholt, kein Sprung). `proto_vorher_nachher.json` liefert je Fall `aktionen` (Monat, Regel, Parzelle, typ_alt/typ_neu, x, z, ew_plus), `verlauf`, `ersetze_parzellen`, `entfernte_instanzen`, `neue_instanzen`, `neue_parzellen`. Felix ersetzt die Instanzen der genannten Parzellen. Bild: `_out/bilder/uebersicht.png` (grau Lücke, grün neu, orange Upgrade).

## Validator (`stadt_validate.py`): 58 OK, 0 WARN, 0 FAIL

Geprüft: Pflichtfelder und bekannte Typen; Anzahl je Ort (Dorf 30–40 Wohnhäuser, Weiler 6, Stadt 36–44, Kirche/Gasthaus/Schmiede/Tor/Markt 80 x 60, Vierseithof 40 x 40); Abstände; je Gebäude-Footprint (Ecken, Kantenmitten, Mitte) nicht in Rinne, See, Teichen, Hang ≤ 6 %, Bach ≥ 15 m (Mühle und Fischerhütte ausgenommen); keine Mittelpunkte im Wasser; Gebäudeüberlappung inkl. Nebengebäude und Nachbarhöfe = 0; Hofstelle ≤ 1 Feld (25 x 25 m) und alle Teile in der Parzelle (+1,5 m); Weg-Steigungen (Chaussee ≤ 5 %, Straßen/Gassen ≤ 8 %, Feldwege ≤ 10 %), Radius, Glätte, keine Wegpunkte im Wasser außer Brücken, keine Gebäude auf Wegen, Netz zusammenhängend; Clark-Evans nur für das Dorf (Weiler n = 6 zu klein, Stadt geschlossene Zeilen); Wachstum (stabil ohne Versorgung, ≥ 1 Aktion je Monat, Reihenfolge, Monat 12 ohne Überlappung/Hang/Wege, EW-Summe).

Perf-Schätzung (Annahme 600 Dreiecke je Gebäudemodul, 300 je Baum, noch ohne echte Assets): 138 Gebäude + 339 Bäume ≈ 0,18 M Dreiecke; 1049 Instanzen laufen als MultiMesh je Typ, ca. 35 Typen = ca. 35 DC. Zusammen mit dem TA-Gelände (ca. 0,25 M) deutlich unter 1,0 M / 300 DC.

## Abweichungen von der Vorgabe

1. **Dorf–Kleinstadt 1,70 km statt 2,5 km.** Im 2 x 1,6 km Kern ist ein Abstand von 2,5 km bei gleichzeitigem Rotach-Streifen dazwischen nicht erreichbar; Lindenfurt liegt am NW-Rand, das Dorf am O-Rand, die Chaussee ist 1,68 km lang. Grenze 1,6 km gehalten.
2. **Aue als weiche Regel.** Die Aue deckt 35 % des Kerns in zwei Bändern; hart verboten wäre fast jede Lage. Hofstellen prüfen die Aue nur für den Hausbereich (vordere 17 m der Parzelle).
3. **Mühle 17 m östlich der Bachachse** (TA-Vorschlag lag auf der Achse, in der Rinne ±12 m).
4. **Dorfteich neu platziert** bei 1512 / 818 (Ende der Bachgasse, Gelände 45,7 m, flach); der TA-Platzhalter lag bei 1400 / 1325. Steht in `gewaesser`.
5. **Dorf r_m = 190 statt 160**, weil das Haufendorf entlang der Hauptstraße gestreckt ist (r_m = 90-Perzentil der Hofabstände + halbe Parzelle; r_max 210). Dorf–Weiler 0,94 km statt 0,8 km (Kreuzung–Weiler 0,84 km); Gut 0,70 km statt 0,6 km.
6. **Wohnhäuser Dorf 34 statt 35**; Kleinstadt 38 Gebäude statt 40 (Quote-Rundung, im Toleranzband).
7. **Erweiterungstypen** außerhalb von `haustypen` und Importrollen: `wassermuehle`, `gutshof`, `fischerhuette`, `netzgestell`, `steg`, `flaeche_*` (garten, hof, obstwiese, kirchhof, marktplatz, schlag: Bodenflecken, b x t in m). Großhof nutzt dieselbe 25-m-Parzelle und denselben Footprint wie der Bauernhof (anderes Modul, kein größerer Platzbedarf).
8. **Zusatzfelder** in den Dateien (zusätzlich zum Vertrag, abwärtskompatibel): Instanzen `ort`, `b`, `t`, `variante`, `rolle`; Wege `id`, `name`, `laenge_m`, Steigungen, `knoten`, bei der Chaussee `bruecken`, `allee`, `trasse_m`, `min_radius_m`; Orte `form`, `gebaeude`, `parzellen`.

## Offene Punkte und Hinweise für Welle 2

Für Felix:
- Platzierung: Instanz-`rot_deg` ist `rotation_degrees.y`; lokales +z (Fassade) zeigt auf (sin rot, cos rot) in (x, z), lokales +x auf (cos rot, −sin rot). `b` und `t` sind Footprint-Maße (m) für Platzhalter-Boxen; Höhe y = `hoehe_at(x, z)` der TA.
- Chaussee und Brücken: `punkte` sind 4–6 m abgetastet, Brücken liegen als `von`/`bis`/`rot_deg` in `chaussee.bruecken`; Band über die Brücke durchlaufen lassen, Rampen 25 m.
- Wachstum: `ersetze_parzellen` + `neue_instanzen` (Monat 12) statt kompletter Neuladung; Gerüstphase 1 Monat laut Regelwerk ist nicht modelliert.
- Allee als 213 Einzelinstanzen (Rolle laubbaum/eiche); bei Perf-Problemen aus den Abschnitten im Wegedict neu streuen.

Für die TA-Rolle:
- `--orte proto_orte.json --nur-boden` neu laufen lassen (Acker an echten Orten); Dorfteich aus `gewaesser.dorfteich` (1512 / 818, r 12,5, Gelände 45,7 m) statt Platzhalter 1400 / 1325.
- Gehölzsaum des Bachs an der Bachbrücke (Chaussee bei 1462,5 / 728) und an der Mühle (16 m von der Achse, Saum bis 17,5 m) freistellen; `baeume_freistellen` mit Orten, Wegen und Hofstellen, auch die 12,5-m-Parzellen am Weiler.
- Fischerhütte, Steg und Boot stehen laut `_meta.see_nutzung` am NO-Ufer (Winkel −47 Grad, Ufer r_eff 234 m, Steg 25 x 2 m, Ende 21 m im Wasser); Bootsschleife Kreis r 110 m um 1182 / 1032, 300 s Umlauf.

Offen / nicht getan:
- Wachstumsrate (180 bp/Monat) nicht gegen `economy_slice` geprüft, Konstante `RATE_BP`.
- Teilung, Gasse und Platz (Regeln 3, 5, 6) werden in 12 Monaten nie erreicht und sind nicht implementiert; Vorstadt-Slots liegen entlang der Ausfallstraßen bis 265 m Radius.
- Assets nicht in Godot geprüft (nicht nötig in Welle 1); Dreiecksbudget ist eine Schätzung.
- Gutsweg hat bei 9,99 % Steigung (Feldweg, Grenze 10 %) einen steilen Abschnitt; flachere Trasse nicht geprüft.
- Aue-Parzellen in Lindenfurt/Weiler: keine; falls die TA die Aue-Maske ändert, Validator erneut laufen lassen.
