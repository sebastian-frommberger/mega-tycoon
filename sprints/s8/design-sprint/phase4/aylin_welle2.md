# Aylin, Phase 4 Welle 2: Schilder, Plaketten, Aufgabenkarten (schlank)

Stand 03.11.2026, Arbeitskopie `p4/w2/aylin/`, Godot 4.7.2 (API gegen `doc472`-Dump und `--check-only` geprüft). Grundlagen: VERTRAG.md (Welle 2), 16_prototyp_plan_v1_1 §2, §7, 14 §7, 12_welt_regelwerk_v1 (Schild, Fernsicht), Referenzbilder TF3.

## 1 Was gebaut ist

| Datei | Inhalt |
|---|---|
| `slice/proto/proto_schilder.gd` (`class_name ProtoSchilder`) | Schilder für Orte, Plaketten für Industrie, Stufen, Entzerrung, Gelände-Anker, Tooltip „Einzugsgebiet“, Kontrastfunktionen |
| `slice/proto/proto_schilder_daten.json` | Umland, Trend, Bedarf, Güter-Icons, Industrie-Farben und -Texte (nur, was nicht in `proto_orte.json` steht) |
| `slice/proto/proto_icons/p_*.png` (+ `.import`) | 6 neue Silhouetten 100 × 100: Mehlsack, Keule (Fleisch), Kettenglied, Dorf, Person, Pfeil rechts |
| `tools_proto/aylin_icons.py` | Erzeugungsskript der Icons (Stil `ui/tools/make_icons.py`, deterministisch) |
| `slice/tests/proto_schilder_test.gd` | 51 Prüfungen headless, schreibt `_out/kontrast_analytisch.csv`, `kontrast_g3_wasser.csv` |
| `slice/tests/proto_schilder_shots.gd` | Bilder (xvfb, opengl3) + Kontrastmessung im gerenderten Bild, schreibt `_out/kontrast_bild.csv` |
| `phase4/aufgabenkarten_v1_1.md` | Aufgabenkarten für Phase 5 |
| `phase4/bilder/aylin/*.jpg`, `aylin_kontrast_*.csv` | Bilder und Messwerte |

Verwendet, nicht geändert: Güter-Icons `ui/assets/icons/c_weizen.png`, `c_stadt.png`, `k_arrowUp/Down.png`, Industrie-Scheiben `ui/assets/industry/getreidefarm_frei.png`, `muehle_frei.png` (Mira, S7), Schrift Poppins (`ui/assets/fonts`). **Keine Bestandsdatei geändert.**

## 2 Hook für Felix

```gdscript
const Schilder := preload("res://proto/proto_schilder.gd")      # oder ProtoSchilder (class_name, nach --import)
# in prototyp_welt.gd nach _baue_kamera():
var schilder = Schilder.bauen(self, cam, orte, terrain)         # orte = proto_orte.json["orte"]
```
- Signatur: `static func bauen(parent: Node3D, kamera: Camera3D, orte: Array, terrain, industrie: Array = []) -> ProtoSchilder`. Fehlt `industrie`, liest die Klasse `proto_orte.json["industrie"]` selbst (Gutshof, Mühle).
- `terrain` braucht nur `hoehe_at(x, z)` (TA-Terrain und Stub gehen; `null` geht, dann Höhe 0).
- Läuft in `_process` mit Priorität 100 (nach Felix' Kamera) in einem eigenen CanvasLayer (Layer 0, unter Felix' HUD auf Layer 1). Das HUD-Panel wird automatisch als Sperrfläche erkannt; zusätzliche Flächen über `schilder.meiden` (`Array[Rect2]`).
- Für die Sim-Anbindung / A10: `setze_trend(id, "hoch"|"gleich"|"runter")`, `setze_ew(id, n)`, `setze_bedarf(id, [{gut, status: ok|warn|bad, ersatz}])`, `setze_sichtbar(an)`. Beim Umschalten auf das „Nachher“ von Erlenbach: `setze_ew("erlenbach", 307)`, `setze_trend("erlenbach", "hoch")`.
- Tests und Bilder: `liste()`, `eintrag(id)`, `texte(id)`, `tooltip_fuer(id)`, `tooltip_fuer_punkt(p)`, `zeige_tooltip(id)`.
- Der Schalter M (Modelle aus) ändert die Schilder nicht (Zeichentest A2), kein Hook nötig. Die Kamera muss im Viewport angemeldet sein (ab dem ersten Frame nach `current = true`).

## 3 Schild-Konzept

**Zeichen statt Objektgröße (E1).** Die Schilder sind Bildschirm-Overlay mit festen Pixelgrößen (Fensterhöhe/900, begrenzt auf 0,85–1,5; kleinste Schrift 12 px). Die Modelle bleiben im echten Maßstab, nur das Zeichen wächst nicht mit der Entfernung. Kein `Label3D`/`label_kscale` nötig: die Pixelgröße steht direkt fest, die FOV-Korrektur entfällt.

**Drei Stufen nach Abstand Kamera–Ort** (Hysterese 8 %, kein Flackern an der Grenze):

| Stufe | Abstand | Inhalt | Größe Kleinstadt / Dorf (px bei 900 px Höhe) |
|---|---|---|---|
| Fern | ≥ 1,5 km | Klassen-Symbol + Name | Name 17 / 14, Symbol 28 / 22 |
| Voll | 400 m – 1,5 km | Zeile 1 Symbol + Name, Zeile 2 Person + Einwohner, Trendpfeil, bis 3 Bedarf-Icons mit Statusform | Name 21 / 16, Zahl 15 / 14, Icons 22 / 18; Faktor 1,12 (bei 400 m) bis 0,92 (bei 1,5 km) |
| Nah | < 400 m | nur Name, leicht zurückgenommen (92 %) | 18 / 15 |

- **Hierarchie:** Kleinstadt (Marktflecken) immer, größer als Dorf in jeder Stufe; Dorf unter 3 km Kamera (der Zoom reicht bis 3 km, also immer); **Weiler nur im Nahbereich ≤ 500 m, nur Name** (Regelwerk: „nie“ in Übersicht, siehe Abweichung 2).
- **Anordnung:** Schild über dem Ort (Anker 18 m / 40 m über `hoehe_at`), Grundversatz nach oben (Voll 20 px, Nah 10 px), damit es nicht mitten im Dorf liegt; kurzer Zeiger mit Punkt am Ortsmittelpunkt, bei Versatz eine Linie.
- **Entzerrung** wie `label_declutter.gd`: Reihenfolge Kleinstadt, Dorf, Industrie, Weiler; weicht ein Schild einem anderen oder dem HUD, geht es in 12-px-Schritten nach oben (höchstens 8). Orte werden nie ausgeblendet, Industrie und Weiler schon, wenn sie keinen Platz finden. Test: in allen 5 Presets 0 Überlappungen.
- **Gelände:** Anker liegt immer ≥ 10 m über `hoehe_at` (kleinster Wert im Test 12 m). Die Sichtlinie Kamera–Anker wird in 20 Proben gegen `hoehe_at` geprüft; ist sie verdeckt, wird der Anker stufenweise bis 150 m angehoben (weich nachgeführt). Im Test mit künstlichem Wall (140 m hoch zwischen Kamera und Ort) wird der Anker um 15 m angehoben und die Sichtlinie ist danach frei; im echten Gelände war in keinem Preset eine Anhebung nötig.
- **Tooltip „Einzugsgebiet“:** erscheint nach 0,12 s unter dem Schild, wenn die Maus darauf steht (kein Klick, kein Modal, verschwindet beim Ziehen). Kurze Sätze, Du-Form wie `ui/fehlertexte.gd`:
  *Einzugsgebiet Erlenbach · Im Ort wohnen 244 Menschen. Das sind die Häuser, die du siehst. · Dazu kommen 406 im Umland, auf Höfen und in Weilern ringsum. · Zusammen sind das 650. Danach richtet sich der Bedarf. · Bedarf: Nahrung, zum Beispiel Mehl oder Fleisch. Wird gebraucht. · Das Umland wächst nicht. Nur der Ort wächst. · Trend: bleibt gleich. Der Ort wächst, wenn er versorgt ist.*
  Lindenfurt nennt zusätzlich, dass nur der Ausschnitt (387) gebaut ist und die Gesamtzahlen eine Annahme sind. Auch die Plaketten haben einen Tooltip (zwei Sätze, Kette Getreide → Mehl → Dorf).
- **Bedarf-Icons:** Dorf und Kleinstadt kaufen die Kategorie Nahrung (`economy_slice` `basket_by_stage`): Mehl, ersatzweise Fleisch (`goods.json` `substitut_fuer`), also Mehl-Sack / Keule mit „/“ dazwischen. Statusform nach A-07 neben dem Icon: Kreis = gedeckt (grün), Dreieck = wird gebraucht (amber), Quadrat = fehlt (rot); Form und Farbe, nie Farbe allein. Getreide steht nicht im Ortsbedarf, sondern als Eingang an der Mühle. Trendpfeil: hoch (grün), gleich (hell), runter (rot), mit Form.
- **Industrie-Plaketten (Gutshof, Mühle), wie TF3 und `industry_markers.gd`:** runde Scheibe aus den S7-Plaketten (Füllfarbe + dunkler Saum #0F1720, Icon darin), daneben der **Name in der Typfarbe** (Gutshof gelb, Mühle hell) auf der dunklen Platte; **Gebäude bleiben neutral** (G1, Material gehört Felix/TA). Im Vollschild darunter die Kette: Kettenglied, Eingang → Ausgang (Mühle: Weizen → Mehl, Gutshof: → Weizen). Scheibengröße 22–34 px nach Abstand wie S7 (34 px ab 1,5 km).
- **Aussehen:** dunkle Platte (#191714, 88 %), cremefarbener Rand 1,5 px, cremefarbene Schrift (Poppins), Eckenradius 6 px, wie das HUD.

## 4 Kontrast

WCAG 2.x, Verhältnis (L1 + 0,05) / (L2 + 0,05) wie `industry_markers.contrast`. Gates: Text ≥ 7:1 (AAA, strenger als die üblichen 4,5), Grafik (Rand, Statusformen, Scheibe) ≥ 3:1.

**Analytisch** (Test, 15 Untergründe: 12 Bodenklassen aus dem Regelwerk, Wasser A tief, Wasser B tief, Himmel am Horizont; Platte mit 88 % Deckung darüber gerechnet), `aylin_kontrast_analytisch.csv`:

| Prüfung | Minimum | Wo | Gate |
|---|---|---|---|
| Schildtext auf Platte | **11,59** (Spanne 11,59–14,79) | über Schnee | ≥ 7 |
| Industrie-Name (Gelb / Hell) auf Platte | **7,94** | über Schnee | ≥ 7 |
| Statusfarben (grün, amber, rot) auf Platte | **6,21** | über Schnee | ≥ 3 |
| Plattenrand bzw. Platte gegen Untergrund | **3,73** | Acker dunkel | ≥ 3 |
| Industrie-Scheibe: max(Füllung, Saum) gegen Untergrund (S-08) | **3,38** | Waldboden | ≥ 3 |

**Im gerenderten Bild** (xvfb, 15 Schilder in 11 Ansichten; Text = 98. Perzentil der Leuchtdichte im Schild, Platte = Median; Umgebung = Ring 4–7 px außerhalb), `aylin_kontrast_bild.csv`:

| Prüfung | Minimum | Wo |
|---|---|---|
| Text gegen Platte | **9,33** | Gut Kuppenhof, Fernstufe (gelber Name) |
| Platte gegen Umgebung | **2,95** | Erlenbach, Fernstufe (Umgebung: Ortskern mit hellen Dächern und Wiese) |
| Schild gegen Umgebung (größerer Wert aus Platte und hellem Rand) | **3,26** | Erlenbach, Fernstufe |

Befund: Der Text ist überall deutlich lesbar (gemessen ≥ 9,3:1, analytisch ≥ 7,9:1). Die Platte allein hebt sich an einer Stelle (Erlenbach aus der Ferne) nur mit 2,95:1 von der Umgebung ab; der helle Rand trägt sie auf 3,26:1 – knapp über dem Gate. Bei Bedarf Rand auf 2 px oder Platte auf 94 % anheben.

**Zusatz G3 (14 §3, nicht Teil des Auftrags, nur Messwerte):** Wasser (tiefe Farbe A `#2F6E7C` / B `#345F7E`) gegen die Uferklassen hat nur 1,1–3,0:1 Leuchtdichtekontrast (alle 14 Paare unter 3:1, `aylin_kontrast_g3_wasser.csv`); Wasser und Land unterscheiden sich vor allem im Farbton, im Bild trägt der hellere Uferverlauf die Kante. G3 „≥ 3:1 Saum oder Marker“ ist damit **nicht durch Leuchtdichte, sondern nur durch den Ufersaum im Shader** erfüllt: Entscheidung Art Director / Daniel, ob die Messung am gerenderten Saum (nicht an den Klassenfarben) gelten soll.

## 5 Messwerte Test

`proto_schilder_test` **51/51 OK** (headless, 1600 × 900): Anzahl (3 Orte + 2 Plaketten), Texte (Name, Ort-EW 244 / 387 / 48, Trend, Bedarf), Stufen und Hysterese, Kleinstadt > Dorf, Weiler-Regel, Anker über Gelände, Anhebung bei Wall, 0 Überlappungen in 5 Presets, Tooltip-Inhalt, „Modelle aus“, Kontrast (5 Gates), Kosten.
Kosten je Frame (Layout, ohne Zeichnen; headless, geteilte Maschine): **0,60 ms** bei bewegter Kamera (inklusive Sichtlinienproben), **0,06 ms** bei ruhiger Kamera. Das Zeichnen sind 5 Platten, Die Schilder sind 2D und zählen nicht zu den Szene-Dreiecken; das Perf-Gate der Szene (Übersicht ≤ 1,0 M / ≤ 300 DC) habe ich nicht separat mit und ohne Schilder gemessen (live in den Bildern: Übersicht 133 k Dreiecke / 110 DC mit Schildern).

## 6 Bilder (`phase4/bilder/aylin/`)

| Bild | Zeigt |
|---|---|
| `schilder_1_uebersicht.jpg` | Preset 1, Fernzeichen für Lindenfurt, Erlenbach, Mühle, Gutshof; Weiler ohne Schild |
| `schilder_2_dorf.jpg` | Preset 2, Vollschild Erlenbach (Einwohner, Trend, Bedarf mit Statusform) |
| `schilder_3_markt.jpg` | Preset 3, Nahstufe Lindenfurt (nur Name) |
| `schilder_4_ohne_modelle.jpg` | M gedrückt: Schilder bleiben (A2) |
| `schilder_5_tooltip_dorf.jpg`, `_6_tooltip_stadt.jpg` | Tooltip „Einzugsgebiet“ Erlenbach / Lindenfurt |
| `schilder_7_muehle_nah.jpg`, `_8_weiler_nah.jpg` | Plakette Mühle nah, Weiler nur Name |
| `schilder_9_see.jpg`, `_10_mittel.jpg`, `_11_gutshof_voll.jpg` | Vollstufe mit Plaketten und Kette Getreide → Mehl |
| `schilder_ausschnitte.jpg` | 8 Ausschnitte 2 × zum Prüfen von Schrift, Icons, Statusformen |

(Die rosa Boxen auf Häusern sind Felix' Platzhalter ohne Modell, nicht Teil der Schilder. Das HUD oben links ist Felix' Panel.)

## 7 Annahmen und Abweichungen

| # | Punkt | Entscheidung |
|---|---|---|
| 1 | 2D-Overlay statt `Label3D` + `label_kscale` | Pixelgröße direkt, Tooltip und Entzerrung einfach. Kosten: kein Tiefentest (Schild liegt immer über dem Bild, auch wenn der Ort hinter einem Hang liegt), deshalb Gelände-Anhebung und Zeiger. Gebäude verdecken Schilder nie. |
| 2 | Weiler: Regelwerk `label.hierarchie.weiler = "nie"` | Der Auftrag verlangt ein Schild je Ort. Kompromiss: in Übersicht und mittlerer Entfernung nie, nur ≤ 500 m der Name (Konstante `WEILER_NAH_BIS_M`, 0 schaltet es ab). |
| 3 | Plakette „wie industry_markers.gd (Kette-Icon)“ | Gelesen als: S7-Scheibe + Kette im Vollschild (Eingang → Ausgang). Statusmarke (Lizenz ja/nein) entfällt, der Prototyp hat keine Lizenzen. |
| 4 | Plaketten bleiben unter 400 m sichtbar | S7 schaltet sie dort ab, weil Props übernehmen. Hier sind die Gebäude neutrale Boxen ohne Zeichen, also bleibt Scheibe + Name (22 px, 92 % Deckung). |
| 5 | Industrie nicht durchsichtig | S7 nimmt die Plakette nah auf 60 % zurück; das hätte den Text-Kontrast (7,9:1) gebrochen, Text bleibt voll deckend. |
| 6 | Bedarf = Mehl / Fleisch | Spielwahrheit: Dorf und Kleinstadt haben nur die Kategorie Nahrung (Stufe `stadt` kommt erst mit Stahl). Getreide als Güter-Icon steht an der Mühle. Status „wird gebraucht“ ist ein fester Beispielwert (keine Sim im Prototyp). |
| 7 | Trend „gleich“ | E7: Wachstum ohne Versorgung bleibt stabil. Hook `setze_trend` für Welle 2/Sim. |
| 8 | Zahlen für Einzugsgebiet | Erlenbach 244 + 406 = 650 aus `proto_vorher_nachher.json`; Lindenfurt: **Annahme** Ort gesamt 2.400, Umland 550, Einzugsgebiet 2.950 (Klassenband Regelwerk), im Tooltip als Annahme markiert; Hasenwinkel ohne Einzugsgebiet (Weiler, kein Knoten). Sichtbare Ort-EW kommen aus `proto_orte.json`. |
| 9 | Eigene Daten | `proto_schilder_daten.json` (Aylin), weil das Orte-Format (Stadt) kein Umland und keinen Bedarf trägt; Ort-EW, Name, Klasse, Position unverändert aus `proto_orte.json`. |
| 10 | Mindestschrift 12 px, Skalierung 0,85–1,5 | kein Genre-Wert, Setzung nach Lesbarkeit bei 1600 × 900. |
| 11 | Neue Icons | Mehl, Fleisch, Kettenglied, Dorf, Person, Pfeil rechts fehlten (Kenney und `c_*` haben sie nicht). Eigenbau im Kenney-Stil, Quelle `tools_proto/aylin_icons.py`; Fleisch (Keule) ist bei 18 px knapp erkennbar, Sack und Ähre gut. |
| 12 | Kein Eingriff in `prototyp_welt.gd` | Der Hook ist eine Zeile für Felix (Abschnitt 2); Test und Bilder bauen die Schilder selbst an die Szene. |

## 8 Offene Punkte

- Felix: Hook einbauen; optional `meiden` mit der Fahrzeug-Info und späteren UI-Panels füllen; bei Sim-Anbindung Trend, EW, Bedarf setzen.
- Tooltip ist nur mit Maus bedienbar (Prototyp ist nur mit Maus + Tastatur spielbar); für die UI im Spiel braucht es einen Tastatur-/Fokus-Weg.
- Fleisch-Icon bei 18 px verbesserungsfähig; ein echtes Mehl-Icon kommt, wenn Sophie Güter-Icons für alle `goods.json`-Einträge zeichnet.
- Zeigen der Platte gegen helle Umgebung (2,95:1, Abschnitt 4): Entscheidung, ob Platte 94 % oder Rand 2 px.
- G3 Wasser/Land (Abschnitt 4): Art Director entscheidet über die Messmethode.
- Das Schild liegt am Ortsmittelpunkt aus `proto_orte.json` (Lindenfurt: Markt-Mitte, am Rand des gebauten Ausschnitts); bei einem größeren Stadtsektor wäre der Anker die Mitte der Stadt.
- Nicht getestet: echte Auflösungen ≠ 1600 × 900 im xvfb-Bild (Skalierung getestet nur analytisch), Mausverhalten mit echter Maus auf Bastis Rechner.

## 9 Aufrufe
```
python3 -I tools_proto/aylin_icons.py slice/proto/proto_icons
godot --headless --path slice --import
godot --headless --path slice -s res://tests/proto_schilder_test.gd
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_schilder_shots.gd -- _out/bilder
```
