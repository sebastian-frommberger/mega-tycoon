# D-09 Abnahme S7-Welt (`--welt=s7`, Seed 7): Daniel, Sprint 7 Block D

Arbeitskopie `/tmp/claude-0/gd/sprint7/d/daniel/slice` (main 08b0140), Godot 4.7.2, xvfb. Spielcode nicht geändert.
Läufe: `/tmp/claude-0/gd/sprint7/d/daniel/z/<lauf>/` (commands.txt, state.md, log.md). Analyseskripte: `.../daniel/an/` (steil.py = Steigung je Ziehpfad wie `_drag_path` + `BauS7.steigung_pct`, fluss.py = Brückenquerungen mit der Uferhöhen-Regel aus `s7_world.gd`).
Validator `world_validate.py --dir world/data`: OK, 0 Verstöße (12 Städte, 21 Industrien).

## Vorab: Werkzeugfehler (QA, nicht Spiel)
`play.sh --welt=s7` war auf der echten Karte unbrauchbar: `play_session.scr_cell()` projiziert die Feldmitte auf y = 0, das Gelände liegt bei 30–150 m. Ergebnis: „Maus trifft Startfeld … nicht“ bei fast jeder Straße und bei `buy_licence kohle_3`. Bisher fiel das nicht auf, weil `u03_play_check.sh` S7 mit `MT_S7_KARTE=slice` (flach) fährt.
Fix nur in meiner Kopie (Patch `/tmp/claude-0/gd/sprint7/d/daniel/play_session_d09.patch`): Projektion auf `world_s7.hoehe_szene()`, dazu neuer Befehl `shot <name>` (Zwischenbild). **Bitte übernehmen** (Mira/Felix), sonst können Lena/Aylin die Rundgang-Befehle nicht abspielen.

## 1. Spielbarkeit: 5 Starts bis zur ersten Kette (mit Werkzeug-Fix)
| Start | Kette | Ergebnis |
|---|---|---|
| Haberau (Dorf, Landwirtschaft im Radius), `z/b` | farm_1 → muehle_1 → Haberau | 7/7 Ziele, M3 bei 5:35, 10:00 Kasse 6.713 $, Mühle→Haberau +399 $/min |
| Seehafen (Kleinstadt, Kette über den Fluss), `z/c` | farm_2 → muehle_2 → Seehafen (Brücke N–S) | 7/7, M3 bei 5:28, Brücke klappt beim ersten Versuch |
| Altenbruck (Dorf, Rohstoff im Radius), `z/a2` | kohle_3 → kraftwerk_3 | direkt: „Zu steil: 25 % …“; mit Zwischenpunkt `248,185` gebaut, 6:00 +76 $/min |
| Kohlberg (Stadt, Vorschau „Wagnis“), `z/d` | farm_3 → muehle_3 → Kohlberg | 7/7, M3 bei 5:35, **+447 $/min**: bester Start von allen |
| Haberau → Wiesental (Randfall Fluss), `z/b2`, `z/b3`, `z/s8` | muehle_1 → Wiesental | direkt abgelehnt, gerade nach Norden abgelehnt (41 %), über zwei Züge `muehle_1 → 108,335 → 133,310` gelöst |
HQ-Umsetzen auf S7 (`z/f`: Kohlberg → Altenbruck) funktioniert. Keine Stadt ist auf Seed 7 vom Fluss geteilt. Z-01 dockt an allen getesteten neuen Städten an („angeschlossen am Stadtrand …“). Keine stumme Fehlermeldung gefunden.

## Befunde nach Schwere

### Blocker
keiner. Jede getestete Kette ist baubar, auch ohne Anleitung (bei Steilstellen mit 1–2 Versuchen).

### Hoch
**H1 Stadtnamen stehen an der falschen Stadt (Übersicht).** Ab Zoom ≈ 9 sitzen die Stadtlabels 100–350 px südlich ihrer Stadt. Die großen Städte landen auf dem Nachbardorf: „Kohlberg · Stadt · 10150 Einw.“ liegt über Altenbruck, „Wiesental · Stadt · 10050“ über Haberau, „Hochstetten“ auf Getreidefarm 2. Die Labels überlappen sich gegenseitig. Repro: `camera 255 195 14` bzw. vor der Gründung `hover haberau`. Bilder: `shots/s7_3_gebirge_revier3.png`, `shots/s7_5_hq_vorschau_haberau.png`. Ein Spieler zieht so die Straße zur falschen Stadt. Dazu überlappen sich Industrie-Labels im Revier („Stahlwe[Plakette]3 Werkzeugfabrik 3“). Mira, s7_industrie-Test lief nur auf der Platzhalterkarte.
**H2 Brückenrampe zu steil an ~40 % des Flusses.** Wasserfelder bekommen als Bauhöhe die höchste Landhöhe im Umkreis 3 (`s7_world.gd` Z. 115 ff.). In Tälern mit einem höheren Ufer liegt das Brückendeck 6–12 m über dem direkt angrenzenden Uferfeld. Folge: „Zu steil 41 %“ bei einer geraden Querung. Laut Nachrechnung sind 303 von 512 Fluss-Spalten gerade (N–S) querbar. Ganze Lücken liegen genau an Spielorten: x 112–151 (Mühle 1/Wiesental), x 275–312 (Mittelfurt), x 425–456 (östlich Seehafen). Repro: HQ Haberau, `buy_licence muehle_1`, `road muehle_1 118,310`. Der Hinweis „Wasser nur gerade queren (Brücke)“ führt hier in die Sackgasse. Fix-Vorschlag Felix: Deckhöhe = max(direkt angrenzende Uferfelder) oder Rampenfelder vom Steigungstest ausnehmen. Validator und Spiel rechnen die Querung verschieden (Validator: alle Ketten erreichbar).
**H3 HQ-Vorschau nennt 9 von 12 Städten „Wagnis“, auch die beiden größten.** HQ-Radius 45–55 Felder (1,1–1,4 km), die Lage-Regeln R1–R5 setzen Industrien aber 0,75–4 km von Städten. Darum liegt fast nichts im Radius. Kohlberg zeigt „Wagnis: kein Rohstoff im Radius … nur Fernlizenzen“ und nennt die gute Agrarkette (Farm 3/Mühle 3) gar nicht. Gespielt ist Kohlberg der stärkste Start (+447 $/min nach 10 min, Kasse 6.310 $). Die Vorschau schreckt also vom besten Start ab. Tobias/Lena: Radius an den S7-Maßstab anpassen oder „Wagnis“ aus der echten Kettenrechnung ableiten.
**H4 Städte lesen sich aus der Übersicht als Straßenraster, nicht als Stadt (gegen Bastis „Straßen nicht zu groß“).** Ab ~1,5 km sieht man helle, rautenförmige Gitter mit Punkten: „Millimeterpapier“. Häuser sind kaum zu erkennen, die Stadtstraßen-Kacheln dominieren. Alle Städte haben dieselbe Rautenform. Nah (Zoom 1) ist es dagegen gut. Bilder: `shots/s7_x_stadt_raster_1500m.png`, `shots/s7_1_uebersicht_maxzoom.png`. Sophie/Mira: dunklerer, schmalerer Fern-Tint der Stadtkacheln (Sophies eigener Vorschlag), Fern-LOD ohne Gehwegkanten.

### Mittel
**M1 Industrien nur in 6 Baukasten-Clustern.** Es gibt 3 identische Montan-Reviere mit je Kohle, Erz, Stahl, Kraftwerk und Werkzeug in ≤ 1,5 km, dazu 3 Farm/Mühle-Paare in 650 m Abstand. R7/R8 sind formal erfüllt, und keine Stadt ist spezialisiert. Aber es entsteht keine TF2-Streuung: Das Süd-Zentrum (Mittelfurt, Weidenau, Rotheim, Eichwald) hat in 3 km keine Industrie (Lizenzfaktor ×9,5–×12,9).
**M2 Lage-Logik nur in Revier 3 sichtbar.** Kohle 3/Erz 3 liegen sichtbar am Gebirgsfuß. Revier 1 (NO) und 2 (SW) liegen in Quadranten mit höchstens 396 m: Die Minen stehen auf 122–149 m im scheinbar flachen Grün. Mühle 3 (274,80) liegt weder am Fluss noch am Stadtrand (1,8 km bis Kohlberg). R2 „Stadtrand“ und „40–80 Felder“ widersprechen sich. Farm 3 liegt 6 km vom Fluss.
**M3 Steilstellen an Industrie-Böschungen.** Direkte Ziehwege scheitern am Plateaurand: kohle_3→kraftwerk_3 25 %, kohle_1→kraftwerk_1 22 %, erz_2→stahl_2 33 % (Nachrechnung, im Spiel für kohle_3 bestätigt). Die Meldung nennt eine Lösung („am Hang entlang“), aber keine Richtung. Vorschlag U-03: „… z. B. erst nach Süden ziehen“ aus dem Plan berechnen, oder Ghost rot nur am Steilstück.
**M4 Fehlertext nennt die falsche Ursache.** `road muehle_1 wiesental` meldet „Wiesental ist von hier nicht anschließbar. Wähle eine andere Seite der Stadt.“ Die eigentliche Ursache ist die steile Flussquerung (H2), nicht die Stadtseite.
**M5 Diagonale Straßen sind Treppen.** Geschleppte Diagonalen erscheinen als Zickzack-Linie (`shots/s7_4_fluss_muehle1_wiesental.png`). Im Maßstab 25 m fällt das stärker auf als im Slice. Auf der diagonalen Flussquerung ist keine Brücke zu sehen.
**M6 Schnee/Rand.** Der Schnee über 780 m ist eine große, ungemusterte weiße Fläche mit harter Kante zu Fels. Aus der Übersicht liest sie sich als „Gebirge“ (gut), wirkt aber alpin und flach. Beim Max-Zoom an der Kartenecke (`shots/s7_6_kartenecke_maxzoom.png`) sieht man weichgezeichneten Rand und Schnee: kein Himmel, keine Kante (gut). Allerdings fehlt jede Markierung, wo die Baufläche endet.
**M7 Gleis-Grenze 12 % fehlt.** `rail kohle_3 stahl_3` (12,9 %) wird gebaut (`z/f`). Bekannt bei Felix, offen.
**M8 Fluss treppig.** Der Fluss ist am 25-m-Raster sichtbar gestuft und hat keine Ufer. Aue-Streifen erscheinen als gelbliche Wellenbänder quer über die Karte (`s7_5`).

### Niedrig
- N1 Hinweis nach 7/7: „Weiter: zweite Kette oder Mittelfurt beliefern.“ (main.gd 2092, Slice-Text). In S7 ist Mittelfurt eine abgelegene Kleinstadt.
- N2 Weißer Würfel in der Mitte von Wiesental (Kreuzung im Zentrum, `shots/s7_2_stadt_nah_wiesental.png`).
- N3 Erste Linie Farm→Mühle bringt in S7 nur +5…+33 $/min, weil die Strecke kurz ist (Luftlinie 600–850 m). Die Mühle→Stadt-Linie bringt dagegen +256…+447 $/min. Das ist kein Fehler, aber der erste Schritt fühlt sich wertlos an (Tobias).
- N4 Vor der Gründung steht Getreidefarm 1 doppelt als Label („Getreidefarm 1 · 1,02 km“ und Plakette mit Namen).

## Look-Urteile (gegen Bastis Feedback / Railway Empire)
| Punkt | Urteil | Bild |
|---|---|---|
| Proportion Straße : Haus, nah | **abgenommen.** Häuser realistisch klein, Kern/Mitte/Rand lesbar. Kern-Höfe sind große, leere graue Flächen | `shots/s7_2_stadt_nah_wiesental.png` |
| Proportion Straße : Haus, Übersicht | **nicht abgenommen.** Das Raster dominiert, die Stadt wirkt wie Millimeterpapier (H4) | `shots/s7_x_stadt_raster_1500m.png` |
| Landstraßen/Gleise | **abgenommen in der Breite** (schmal, passend). Diagonalen als Treppe: nicht abgenommen (M5) | `shots/s7_4_fluss_muehle1_wiesental.png` |
| Stadtrand/Ausfransung | **teilweise.** Ausfallstraßen mit Streuhäusern vorhanden, die Silhouette ist bei allen Städten eine Raute | `shots/s7_1_uebersicht_maxzoom.png` |
| Gelände/Gebirge | **abgenommen mit Auflage.** Gebirge ist lesbar, aber nur im NW. Die übrige Karte wirkt flach. Schnee zu groß und zu flach (M6) | `shots/s7_3_gebirge_revier3.png` |
| Fluss | **abgenommen mit Auflage.** Verlauf gut lesbar, Kante treppig, keine sichtbare Brücke (M5/M8) | `shots/s7_4_fluss_muehle1_wiesental.png` |
| Verschneiter Rand | **wirkt nicht schlecht,** eher neutral: weich, ohne Himmel und Kante. Kartengrenze nicht erkennbar | `shots/s7_6_kartenecke_maxzoom.png` |
| Industrie-Lesbarkeit 4 km | **abgenommen für Plakette und Fläche,** nicht von Bergen, Bäumen oder Städten verdeckt. Labels überlappen und Stadtnamen sind verrutscht (H1) | `shots/s7_3_gebirge_revier3.png` |
| HQ-Vorschau | **funktioniert** (Radius 1,38 km, Kette, Einwohner, Lizenzfaktor, Fluss). Inhaltlich irreführend (H3) | `shots/s7_5_hq_vorschau_haberau.png` |

## 4. Regressions-Lücken (Kandidaten, nicht gebaut)
1. **play.sh auf echter S7-Karte**: `u03_play_check.sh s7` ohne `MT_S7_KARTE=slice` mit den 5 Starts aus `z/` (a2, b, c, d, b3) und erwarteten Toasts. Hätte den Projektionsfehler und H2 gefunden.
2. **Spiel gegen Validator**: Für alle Kettenpaare und Stadtanschlüsse im Spiel `plan_track` direkt rechnen, mit Zwischenpunkt, wenn direkt scheitert. Ziel: mindestens 1 Lösung mit ≤ 2 Zügen. Außerdem: mindestens 80 % der Fluss-Spalten gerade querbar.
3. **Labels auf der echten Karte**: s7_industrie mit Seed-7-Daten. Jedes Stadtlabel liegt in der Stadt-Bounding-Box, und es gibt keine Label-Überlappung bei Zoom 9/14/26.
4. **5.000 Lkw auf S7**: `perf_s7.gd --welt=s7 --lkw=5000 --check` in die Regression (läuft heute nur auf dem Slice). Dazu Fahrzeughöhe auf Brücke und Hang (kein Lkw unter dem Gelände).
5. **Zeitraffer 8× mit Gelände**: Echtzeit-Lauf 8× über 3 min mit 3 Linien. Ticks je Sekunde und Frame-Zeit (heute rechnet `wait` nur Sim-Ticks und sagt nichts über die Echtzeit).
6. **HQ-Umsetzen S7**: d07_abnahme-HQ-Block mit `--welt=s7` (Umsetzen auf erhöhte Stadt, Ring-Klick auf Gelände, Frist).
7. **Gleis 12 %**: rail mit 12,9 % muss abgelehnt werden (Text wie B11).
8. **Vorschau gegen Spiel**: Je Stadt die Bot-Startkette 10 min spielen. Eine „Wagnis“-Stadt darf nicht unter den besten 3 liegen. d08_bankrott läuft nur auf Slice-Standorten.
9. **Weitere Seeds im Spiel**: s7_boot und s7_city mit 2 weiteren Seeds (Stadt vom Fluss geteilt, Z-01). Heute prüft nur der Python-Validator 20 Seeds.
10. **Slice-Texte in S7**: Hinweistexte nach Städtenamen durchsuchen, die nicht zur aktiven Welt passen (N1).
11. **Speichern/Laden**: im Spiel nicht vorhanden. Mit dem Feature: Seed, Straßen auf Gelände und Brücken müssen nach dem Laden gleich sein.

## 5. Bastis Rundgang (Material L-14, Lena/Aylin)
Voraussetzung: Patch `play_session_d09.patch`. Alle Befehle sind geprüft (Läufe `z/s8`, `z/c`, `z/a2`, `z/b3`).
1. **Zoom-Rundgang, 12,8 km bis Haus**: `camera 256 256 26` → `camera wiesental 1.0`. Zu sehen: die ganze Karte mit Fluss Linde W→O, Gebirge mit Schnee im NW, 12 Städte. Dann Wiesental nah: Kern mit Höfen, Mitte, roter Rand. (`s7_1`, `s7_2`)
2. **Erste Straße auf eine Stadt (Z-01)**: `click haberau`, `found_hq`, `buy_licence farm_1`, `road farm_1 muehle_1`, `truck_line farm_1 muehle_1`, `wait 3`, `buy_licence muehle_1`, `road muehle_1 haberau`, `truck_line muehle_1 haberau`, `wait 5`. Zu sehen: Toast „Straße gebaut: 1,88 km … angeschlossen am Stadtrand Haberau“, M3 nach ca. 5:35, 7/7 Ziele.
3. **Industrie-Lage lesen**: `camera 255 195 14`. Revier 3: Kohlemine 3 (248,179) und Erzmine 3 (231,212) am Gebirgsfuß, Stahlwerk 3 und Kraftwerk 3 in der Ebene, Werkzeugfabrik 3 (298,204) Richtung Kohlberg. Plaketten und Flächen sind lesbar. Achtung: Hier zeigt sich auch H1 (Kohlberg-Label über Altenbruck), erst nach dem Fix zeigen. (`s7_3`)
4. **Fluss und Brücke**: HQ Seehafen, `buy_licence farm_2`, `road farm_2 muehle_2`, `truck_line farm_2 muehle_2`, `wait 5`, `buy_licence muehle_2`, `road muehle_2 seehafen` (Brücke N–S über die Linde bei x 458), `truck_line muehle_2 seehafen`, dann `camera 458 235 2.5` (Kamera-Ausschnitt nicht als Bild geprüft). Die Querung klappt beim ersten Versuch. Mühle 1 → Wiesental nicht als Station nehmen, solange H2 offen ist.
5. **Gebirge und „zu steil“**: HQ Altenbruck, `buy_licence kohle_3`, `road kohle_3 kraftwerk_3` → Meldung „Zu steil: 25 % …“. Dann `road kohle_3 248,185` und `road 248,185 kraftwerk_3`, danach `truck_line kohle_3 kraftwerk_3`. Zu sehen: Gelände kostet und sperrt, und am Hang entlang geht es.

## 8-Minuten-Spielstand (Morgenzusammenfassung)
HQ Haberau, 8:00, Kasse 6.445 $, 3 Lkw-Linien (Farm 1→Mühle 1 +24, Mühle 1→Haberau +399, Mühle 1→Wiesental +256 $/min), 26 Lieferungen, 7/7 Ziele. Spielstand: `shots/spielstand_8min_state.md`, Befehle: `z/s8/commands.txt`.
Bilder (alle angesehen) unter `/tmp/claude-0/gd/sprint7/d/daniel/shots/`: `s7_1_uebersicht_maxzoom`, `s7_2_stadt_nah_wiesental`, `s7_3_gebirge_revier3`, `s7_4_fluss_muehle1_wiesental`, `s7_5_hq_vorschau_haberau`, `s7_6_kartenecke_maxzoom`, dazu `s7_x_stadt_raster_1500m`.

## Empfehlung Default S8
**Ja, S7-Welt als Default für S8, mit Auflage:** H1 (Labels) und H2 (Brückenrampe) zuerst fixen, beide sind klein und lokal. Spielbar ist die Welt schon jetzt: 5/5 Starts erreichen die erste Kette, keine Kette ist unlösbar. H3/H4 und M1 sind Design- und Look-Arbeit für S8 und blockieren den Default nicht. Der Slice bleibt als `--welt=slice` für die Regression.
