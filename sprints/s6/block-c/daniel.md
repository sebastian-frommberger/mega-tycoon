# D-08 Abnahmen, Sprint 6, Tag 8-9 (Daniel Richter, QA)

Stand: Repo-Slice (Game-Code identisch mit meiner Arbeitskopie `/tmp/claude-0/gd/sprint6/c/daniel/slice`, nur tests/ geändert). Godot 4.7.2, Sandbox, alle Zeiten Sandbox-Zeiten. Keine FPS-Aussage. Ich habe nichts aus den Entwicklernotizen übernommen, was ich nicht selbst nachgelaufen bin (Quellen je Zeile).

## 1. Abnahmetabelle

| Ticket | Urteil | Beleg (selbst geprüft) |
|---|---|---|
| F-21a Spike-Lager | **ja** | Spike sim-core in Kopie: mit Fix E9 20/20, Exit 0; Fix zurückgedreht (`mini` statt `clampi`): Exit 1, E9 rot. `md5sum -c build_md5_f16.txt` grün, economy.gd bb12c3c3…. Slice: Parität C11 10/10, parity_test 8/8, Lager 2/2. |
| T-14 | **mit Auflagen** | JSON ok: `hq.start_capital_cent` 600000 = constants, Lok-Fix 9000, kein Archetyp-Kapital (H2, slice_test). Modell mit **anderen Seeds** (1001-1300 / 2001-2300, Tobias' t13_sim, `py/d08_modell*.py`): Haberau 12,3 / 10,3 %, Kohlberg 11,0 / 11,3 %, Mittelfurt Karte (Farm 78) 17,3 / 19,7 %. M7 Median Kohlberg 36/34, Mittelfurt 43-44, Haberau 49-50 min. Zug F*(25 F.) = 33 E/min nur bei H=60, bei H=30 51. Auflagen siehe unten (A1-A3). |
| T-14b | **mit Auflagen** | Generator reproduziert md5 953b00d3 aus Karte 718e062c. 8/8, je <= 6 Zeilen. **Aber Lizenzfaktor passt nur bei 2 von 8 Städten zum Spielpreis (B-1).** |
| S-12 | **ja** | Validator Exit 0 (jsonschema + Fallback, Arbeitskopie-Schema), check_s10 grün (NW 30 % am Rand von ±5), Fluss-Schnitt s11 16/16, Parität 10/10, D-07 grün, Dorf x2 (slice_test). Kette komplett im Radius: Haberau (k1), Mittelfurt (k1, Farm 43/Mühle 44), Kohlberg (k2 + k3 inkl. Werkzeug 33), selbst aus der Karte gerechnet. md5 718e062c = D24. Nit B-15. |
| F-20 | **mit Auflagen** | d07 `--only=hq` 30/30 und mein `d08_maus` 16/16 mit echter Maus. 8/8 Vorschau, 2 Klicks Minimum (5 mit Wechsel, Esc, Rechtsklick), Hover bis Panel 2 Frames, Ring 0,35 s, kein Modal, Zeit pausiert, Esc/Rechtsklick brechen ab, Umsetzen per Ring-Klick/Toast/Maus, Regel 2 min und Gratislizenz. main.gd 3035 Zeilen (S5: 3136), kein `archetyp` in main/economy. Offen: B-1, B-3, B-4, B-7, B-9, B-10. Hover-Latenz auf Zielrechner offen. |
| U-02b | **mit Auflagen** | Mein Lauf `u02b_shots`: Linienliste 340 px, Kopfleiste 1566 <= 1600, kein Clipping, Haberau-Label sichtbar, "1 Skillpunkt gespart". **Zielpfeil-Scan 1 Treffer in 100 Ansichten** (Erzmine z3,5, Pfeil deckt "ohne Lizenz"; Felix meldete 0, Regression durch Sophies Declutter, B-6). Tempo-Schalter 56 statt 44 px bleibt bekannte Abweichung. |
| S-13 | **mit Auflagen Zielrechner** | 3 Kandidaten gefüllt (Shots). Marker auf Gras 5,26:1 mit Saum (S-08-Palette, ohne Saum 2,12), Ghost weiß 3,43:1. **"Bäume ohne Schatten" nicht erfüllt:** 2.503 Kenney-Bäume haben `cast_shadow` an (`_multimesh_mesh(..., true)`, B-5). Export enthält die GLBs nicht (B-2). Erledigt erst nach Messlauf. |
| L-12 | **mit Auflagen** | Texte sachlich, Wagnis ohne Rot (H8), Umsetzregel §1.2 in Regelpapier und im Spiel (H20-H29), 8/8. Lizenzfaktor-Zahlen im Spiel nicht gedeckt (B-1), Wagnis-Hinweis jetzt bei allen 5 (Tobias) statt nur Seehafen/Weidenau, ok. |
| SK-01 | **ja, kleine Auflage** | 631 Wörter (gut eine Seite), 3 Äste mit Prozent, Punktefluss ab M1b, kein Bau. Widerspruch: "M2 bis M7 je 1 Punkt" gegen `economy_slice.meilensteine` (nur ms_1b und ms_2 vergeben Punkte, ms_3-7 andere Belohnungen) und gegen die Kopfleiste (U-02b zählt nur M1b). Lena soll den Fluss an die Tabelle angleichen. |

## 2. Regression und Tests (alles in `slice/tests/`, Arbeitskopie)

- **D-07 vollständig grün**: `d07_regression.sh`, 478 s, 0 SCRIPT ERROR. slice_test soa/alt 72/72, parity 8/8, s11 16/16, ui 31/31, kredit 16/16, parity 12/12, lager 2/2, hq 30/30, Spikes, Statik.
- **Neu `d08_bankrott.gd`** (im Regressionsskript, 182 s): 3 Städte x 100 Seeds x 30 Spielminuten im echten Spiel (soa, echte Karte, echte Kasse/Lizenz/Kredit-Funktionen). Seed bestimmt Verhalten (Kredit-Haltung 35/45/15/5, Route, 1-3 Lkw je Linie, Puffer, Nachkauf). Determinismus geprüft (Seed 3 zweimal gleich, Gesamtlauf zweimal identisch 2/35/38 %). Wächter-Korridor je Stadt = Referenz +-10 pp.
  - Ergebnis: **Mittelfurt 2 %, Haberau 35 %, Kohlberg 38 %.**
  - **Das ist kein Beleg für das Band 10-30 %.** Der Bot ist kein kalibrierter Spieler; Referenz für das Band bleibt Tobias' Modell (meine Gegenprobe oben). Der Wert ist Drift-Wächter.
  - Nach Lkw je Linie (gleiches Verhalten in allen Städten): 1 Lkw 0 % überall; 2 Lkw Mittelfurt 0 %, Haberau 24 %, Kohlberg 49 %; 3 Lkw Mittelfurt 6 %, Haberau 63 %, Kohlberg 50 %. Bankrotttreiber ist Lkw-Überbesetzung gegen die Nachfrage (Dorf 18 E/min), nicht der Kredit. Mittelfurt ist mit diesem Verhalten kaum in die Pleite zu bringen. Das gehört in den Basti-Durchlauf (Frage: wo ist der Spaß-Bankrott?).
  - M7 (HQ Stufe 2, 12.000 $) gibt es im Godot-Slice nicht, T-14-M7 ist rein Modell.
- **Neu `d08_maus.gd`** (xvfb, im Regressionsskript ohne Bilder): **Antwort auf "echte Eingaben?": nur teilweise.** `d07 --only=hq` nutzt echte `InputEvent`s per `push_input`, aber das Zielfeld kommt aus `main.sim_hover`, die Mausposition ist konstant (0,3 / 0,55 der Fläche). Die echte Projektion Bildschirm -> Feld (`_mouse_cell`) und Verdeckung durch Panels wurden nie getestet; headless kennt keine Mausposition. `d08_maus` setzt den X-Zeiger per `warp_mouse` auf die per Kamera projizierte Stadtmitte, hovert 8/8, wählt, wechselt, Esc, Rechtsklick, gründet über Knopf, Ring-Klick, Abbruch Esc und Rechtsklick, Umsetzen nach Haberau. 16/16, Befund B-10.
- **Screenshots je Standorttyp** (1600x900, echte Maus): `/tmp/claude-0/gd/sprint6/c/daniel/shots/` `hover_<stadt>.png` (8), `gewaehlt_*`, `gegruendet_` Mittelfurt (Stadt), Kohlberg (Kleinstadt), Seehafen (Wagnis, Kleinstadt), Steinbach (Wagnis, Dorf), `umgesetzt_haberau` (Dorf), `nahzoom_*`, `u02b/`.
- **H29-Flake, Ursache:** `place_hq` startet Tempo 1, danach tickt `_physics_process` parallel zu den synchronen `run_ticks`. Jeder echte Tick während `await frames(1)` verschiebt die 2-min-Grenze um 100 ms; "bei 1199 Ticks noch frei" wird rot. Nachgestellt: ohne Fix 10 von 40 rot, mit 60 ms künstlicher Last 32 von 40, mit 120 ms 40 von 40; mit `set_speed(0)` 0 von 120. Fix: eine Zeile in H28/H29 (`m.set_speed(0)`), 3 Läufe 30/30. Kein Spielcodefehler, der Test war nicht deterministisch.
- Bleibt wackelig: A21 (Panel-Slide <= 150 ms) misst Wanduhr. Unter Parallellast rot (Sophie/Tobias sahen 191/230 ms). Regel bleibt: Suiten nur nacheinander.
- Testfixes: `u02b_shots.gd`, `s13_shots/close/labels/hq.gd` riefen das entfernte `start_game(...)` (SCRIPT ERROR) -> `place_hq`. Neu `d08_lizenzfaktor.gd` (im Regressionsskript als "OFFEN B-1", zählt nicht für den Exit). Statik meldet "OFFEN B-2".

## 3. Sprintziel

| Kriterium | Urteil | Beleg |
|---|---|---|
| 8/8 Städte mit Vorschau | ja | H4 und M1 (echte Maus, 2 Frames bis Panel) |
| <= 5 Klicks bis Start | ja | Minimum 2, gemessen 5 inkl. 3 Umwege |
| kein Dialog, kein Archetyp | ja (Code) | H3, H15, Statik; Daten-Altlast B-15 |
| 6.000 $ einheitlich | ja | H2, H16, JSON |
| >= 3 Standorte mit vollständiger Kette | ja | Haberau, Mittelfurt, Kohlberg |
| Bankrott 10-30 % (Modell) | **im Modell ja, knapp** | Haberau 10,3-12,3 %, Kohlberg 11,0-11,3 % (Stichprobenfehler ca. 1,8 pp bei n=300: der untere Rand ist nicht gesichert); Mittelfurt 17-20 % mit Kartendistanz 78 (T-14 nennt 14-15 % mit Setzung 28). Im Godot-Bot nicht bestätigt (s. o.), Playtest fehlt |
| D-07-Regression grün | ja | s. o. |

**Urteil: Sprintziel technisch erreicht, aber nicht freigabefähig für Bastis Durchlauf, bis B-1 (falsche Lizenzzahlen in der Vorschau) behoben ist.** Die Vorschau ist das Sprintziel; sie nennt bei 6 von 8 Städten einen Preisfaktor, den das Spiel nicht berechnet. Alle FPS-, Hover-Latenz- und Look-Last-Aussagen bleiben "Auflage Zielrechner".

## 4. Bugliste

| ID | Schwere | Befund | Beleg / Vorschlag |
|---|---|---|---|
| B-1 | **Hoch** | Vorschau-Lizenzfaktor ≠ Spielpreis. Spiel (`economy._licence_cost`) kennt keinen Größenfaktor: im Radius immer 0,70, außerhalb 1+0,03 x Überstand. Vorschau: Haberau 0,63 (Spiel 0,70), Mittelfurt 0,84 (0,70), Steinbach 1,6 (1,78), Eichwald 4,0 (4,45), Lindach 2,4 / Weidenau 4,2 (nennen die Werkzeugfabrik, die nicht lizenzierbar ist; echt Erzmine 3,52 / Stahlwerk 5,32), Kohlberg nennt das Kraftwerk (nicht lizenzierbar). | `d08_lizenzfaktor.gd` (1/8). Entweder Größenfaktor ins Spiel (Modell von Tobias rechnet ihn schon; Gleichstand, aber PO-Entscheid und Neumessung) oder Faktor aus Texten streichen und nur lizenzierbare Industrien nennen (30 min, Generator). Mit Spielfaktor 1,0 bleibt das Modell im Band (Mittelfurt 16,0/17,7 %, Haberau 12,3/10,3 %). |
| B-2 | **Hoch** | Export ohne Kenney-GLBs, und der Filter allein reicht nicht. `export_presets.cfg` (beide Presets): `all_resources`, include nur `data/*.json, ui/icons.json, ui/assets/*`. Beide Loader lesen per `GLTFDocument.append_from_file(ProjectSettings.globalize_path("res://..."))`, in der Exe also einen Plattenpfad neben der .exe, nicht das PCK. Folge: nur Primitive; **auch die S-11-Bäume fallen auf Quader zurück, die F-12-Messung "mit Look S-11" bildet sie dann vermutlich nicht ab.** | Nicht exportiert, Befund aus Code und Preset. Fix: `props/kenney/*.glb` in include_filter UND `append_from_file("res://...")` (geprüft: liefert OK) bzw. `append_from_buffer` mit Basis-Pfad `res://props/kenney`. **Vor Bastis Bench-Export beheben**, sonst wieder eine Messung ohne Look. Zusätzlich im Bench ein Logzeile "Bäume: Kenney/Quader". |
| B-3 | Mittel | Wagnis-Start (Seehafen, Steinbach, Eichwald, Lindach, Weidenau): Kamera fährt auf den Mittelpunkt HQ - Kohlemine = leere Wiese, HQ, Ring und Ziel nicht im Bild (`gegruendet_seehafen/steinbach.png`). Ziele zeigen für alle Wagnis-Städte auf Kohlemine -> Kraftwerk (Steinbach: 284 Felder, nächste Farm 81). | `start_targets` nimmt Endabnehmer-Bonus -1000 vor Nähe. Für Wagnis: nächster Rohstoff, Kamera auf HQ. |
| B-4 | Mittel | Mittelfurt (Favorit): M3-Hinweis "Lizenz für Stahlwerk, Straße bis Werkzeugfabrik, Linie Stahlwerk -> Werkzeugfabrik" (Kohlberg-Kette, 259 Felder), weil `hq_optionen.startkette` = k3 (Altlast). M3 wird trotzdem durch Mehl erfüllt. | Startkette Mittelfurt = k1. |
| B-5 | Mittel | Bäume werfen Schatten (2.503 Instanzen), entgegen S-13-Akzeptanz. | `main.gd:_multimesh_mesh(...)` Parameter `true` -> `false`; Look-Last erst auf Zielrechner. |
| B-6 | Mittel | Zielpfeil deckt Label (u02b-Scan 1/100: Erzmine z3,5, "ohne Lizenz" -> "ohne ▼enz"); im Kohlberg-Cluster überdecken Labels Props und einander (Stahlwerk-Label steht über dem Stadtsymbol, ein Kohlberg-Label ist im Bild nicht zu sehen, `u02b_5`, nicht weiter untersucht). | Declutter nach Pfeil-Vorrang laufen lassen; Label-Kanten sind laut Plan Stretch. |
| B-7 | Niedrig | "HQ" in Kenney Future liest sich wie "HO" im Hauptknopf ("HO HIER GRÜNDEN"). | Knopf in Poppins oder "Hauptquartier hier gründen". |
| B-8 | Niedrig | Ring schneidet Industrie-Labels im Nahzoom (Kohlemine/Kraftwerk Kohlberg z2,2; Mittelfurt: Ring läuft durch "Mühle 2 / Getreide 0 · Mehl 0" und Getreidefarm 3). Lesbar, aber unsauber. | Bestätigt. Label-Kanten R2. |
| B-9 | Niedrig | "Seehafen doppelter Text" nur halb behoben: Datenzeile weg, aber Statuszeile "Wagnis: kein Rohstoff im Radius" steht direkt über Zeile 1 "Kein Rohstoff im Radius. Nächste Mühle ..." (alle 5 Wagnis-Städte). | Erste Zeile ohne den Satz. |
| B-10 | Niedrig | Umsetzen-Modus lässt die Kamera im Gründungs-Zoom, die anderen Städte sind nicht im Bild (Test M11b); Spieler muss selbst herauszoomen. | Kamera auf Übersicht beim Umsetzen. |
| B-11 | Niedrig | Ghost im Übersichtszoom nicht erkennbar (`gewaehlt_mittelfurt.png`); Rückmeldung nur Panel, Knopf, Ring. Gesetztes HQ (dunkel mit gelben Streifen) liest sich wie Lkw/Bus. | Sophie/Aylin ansehen. |
| B-12 | Niedrig | Ring-Label "Umsetzen möglich, noch 1:58" weiß auf Schnee, nur Kontur trägt (`nahzoom_kohlberg_kohle`). Kontrast des 3D-Labels nicht gemessen (H7 misst nur Panel). | |
| B-13 | Niedrig (Test) | H29-Flake, behoben (s. o.). Start-Skripte mit `start_game` behoben. | |
| B-14 | Niedrig | `slice_test`-Reporttext "Sättigung Dorf 9 E/min" veraltet (jetzt 18). | |
| B-15 | Niedrig | `slice_map.json` und Schema tragen weiter `hq_optionen[].archetyp`/`im_slice` (Mittelfurt `im_slice: false`), `main.gd` liest `im_slice`. Nur 4 von 8 Städten haben `hq_optionen`. Nicht spielwirksam, aber widerspricht "kein Archetyp". | |

D21-Gegenprobe: Panel-Slide 150 ms, Hover 100 ms, Ring 0,35 s (alle <= 150/400 ms), angedocktes Panel, kein Modal, Wagnis ohne Rot mit Icon+Text. In Ordnung.

## 5. Export-Check (nicht exportiert)

- `data/hq_vorschau.json`: **enthalten**, gedeckt durch `data/*.json` (beide Presets).
- `props/kenney/*.glb`: **nicht enthalten**, und mit Filterergänzung allein weiter wirkungslos (`globalize_path`), siehe B-2. `Textures/colormap.png` kommt als importierte Ressource mit (`all_resources`), der Code lädt sie per `load()`.
- `tests/*` ausgeschlossen, d08-Tests landen nicht in der .exe.

## 6. Auflagen

1. **Vor Basti-Durchlauf:** B-1 (Jonas entscheidet Weg; Tobias/Felix setzen um), B-4 (Mira, eine Zeile Daten).
2. **Vor Bench-Export:** B-2 (Felix/Sophie), B-5 (Sophie). Danach neuer Zielrechner-Lauf, inkl. p95 mit `RENDER_SPLIT` (F-12-Auflage), Hover-Latenz bei ~2.000 Bäumen. Bis dahin sind S-13, F-20-Latenz und F-12-p95 "mit Auflage Zielrechner".
3. **Tag 10:** B-3, B-6, B-9, B-10 (Mira/Sophie); B-7, B-8, B-11, B-12 Politur oder R2.
4. **A1** Tobias: T-14 mit Karten-Distanz Mittelfurt Farm 78 ausweisen (Tabelle nennt Setzung 28), Haberau/Kohlberg liegen am unteren Rand (Bandsicherheit klein). **A2** Modell und Spiel angleichen (Größenfaktor, B-1). **A3** M7 ist im Slice nicht messbar, Basti-Playtest bleibt der einzige Beleg für Bankrott-Spaß.
5. **Lena:** SK-01-Punktefluss an `economy_slice.meilensteine` angleichen.
6. Regression: `d07_regression.sh` (jetzt mit d08_bankrott, d08_lizenzfaktor, d08_maus) vor jedem Merge, nacheinander. Zum Übernehmen aus der Arbeitskopie: `tests/d08_bankrott.gd`, `d08_lizenzfaktor.gd`, `d08_maus.gd`, `d07_abnahme.gd` (H29), `d07_regression.sh`, `u02b_shots.gd`, `s13_*.gd`; keine `.uid`-Dateien, keine Logs.
