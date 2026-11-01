# S-03 Look-Test Diorama vs. Karte: Befund und vorläufige Entscheidung

Sophie Marx, Art Lead · Stand Tag 3 (18.11.2026) · Status: **in Arbeit.** Szene läuft, Messungen nur im Software-Renderer, kein Test mit Personen. Entscheidung ist **vorläufig** (Frist Wiki 20.11.).

## 1. Was gebaut ist

Godot-Projekt `lookscene/` (4.4.1, Compatibility-Renderer, alles per GDScript, `main.gd` plus zwei Shader). Start: `./run_all.sh` erzeugt alle Artefakte neu.

| Baustein | Stand |
|---|---|
| Stadt | 300 Häuser, 5×5 Blöcke, 300 m = 30×30 Felder, Kirchturm, Bahnhof. Ringe: Kern hoch (18–26 m), Rand niedrig (ca. 6–14 m) |
| Industrien | Farm (Rundsilos, Scheune, Getreidehalde, 120 m) und Stahlwerk (Hochofen, 3 Schornsteine, Sheddach-Hallen, Erzhalden, 150 m) |
| Strecke | Doppelgleis Farm → Stadt → Stahlwerk, dazu Straße |
| MultiMesh | **200 Quader** (64 Zugwagen, 136 Lkw, Güterfarben per Instanzfarbe). Zusätzlich 680 Bäume als zweites MultiMesh, nicht Teil der 200 |
| Kamera | 50 → 1000 m in 5 s, konstante Zoomrate, Neigung 30 → 70°, FOV 40° |
| Blend | `mid_blend` um 150 m (±40), `map_blend` um 800 m (±120). Morphing statt Austausch: Höhen werden abgeflacht, Details schrumpfen auf ihren Ankerpunkt, Netz wird breiter und orange, Stadt- und Industrieflächen mit Umriss und Icons blenden per Alpha ein, Gelände entsättigt |
| Netz-Casing | dunkler Saum unter Gleis und Straße (Folge aus S-05) |
| Nicht gebaut | `visibility_range` (Felix-Review steht aus), Overlay-Ebene von Aylin, SSAO (im Compat-Renderer nicht vorhanden, S-04b), Terrain-Höhen, 2-Minuten-Video |

Belege: `uebersicht_zoomstufen.png`, `shots/` (50/150/400/800/920/1000 m), `shots_far/`, `strip/`, `video/fahrt_50_1000m.mp4` (5 s, 1280×720), `run_all.log`.

## 2. Messungen, ehrlich eingeordnet

**Frame-Zeiten: nicht repräsentativ.** xvfb mit Mesa llvmpipe (reiner Software-Renderer, 2 vCPU). 3 Durchläufe der 5-s-Fahrt in Echtzeit: Mittel 282–298 ms je Frame, 17–18 Frames pro Fahrt, **alle** Frames über 33,3 ms (`measure/flytime_blend.json`). Das sagt **nichts** über eine GPU. Das Akzeptanzkriterium „kein Frame > 33 ms“ ist damit **nicht belegt**. Es braucht einen Lauf auf Zielhardware (K-07 Zielrechner).

Ohne Renderer-Bezug gemessen:
- Szenen-Skriptzeit je Frame (Fahrzeug-Update plus Blend-Parameter): Median 1,0 ms, Maximum 2,0 ms, auf diesem Rechner. Die Logik ist nicht der Engpass, die Zahl gilt aber nicht für 10.000 Fahrzeuge.
- Engine-Zähler je Frame (inkl. Schattenpass): 94–102 Objekte, 18–26 Draw Calls, 140.100 Dreiecke bei 50 m, 28.836 bei 1000 m (`measure/szene_zaehler.csv`).

**Popping-Proxy (kein Ersatz für Reviewer).** 150 Bilder, Höhe logarithmisch 50 → 1000 m, mittlere absolute Bild-zu-Bild-Differenz (256×144, Skala 0–255), Szene eingefroren.

| Variante | Median | Maximum | Ort |
|---|---|---|---|
| Blend (Entwurf) | 11,4 | 17,1 (1,5× Median) | Plateau 835–905 m, kein Einzelsprung |
| Harter Wechsel bei 150/800 m | 11,3 | **65,2 (5,8× Median)** | 803 m |

Zwischenfund aus früheren Läufen (Dateien überschrieben): Schatten per `shadow_enabled` abzuschalten erzeugte bei 300–320 m einen Sprung (Wert 43 gegen Median 9,7), weil sich im Compat-Renderer die Gesamthelligkeit ändert. `shadow_opacity` zeigte dort keine sichtbare Wirkung. Jetzt: Schatten bleiben an, die Schattenreichweite schrumpft mit der Höhe. Kosten auf einer GPU nicht gemessen. Frühere Dither-Übergänge sah ich als Rauschen und habe sie durch Morphing ersetzt.

## 3. Entscheidung (vorläufig)

**Zoom-Blend: ja, als Morphing, nicht als Austausch.** Begründung: der harte Wechsel erzeugt im Proxy einen 5,8-fachen Ausreißer, der Blend keinen. Das ist ein Rechenindiz, kein Urteil von Personen. **Rücknahmebedingung:** 2 von 4 Reviewern sehen im Video ein Umspringen, oder ein GPU-Lauf überschreitet 33 ms.

**Lesbarkeitsgrenze (Rechnung plus mein Blick auf die Screenshots, nicht unabhängig geprüft):**
- Sichtbreite = 1,377·Höhe bei 16:9, FOV 40°, 70° Neigung (Rechnung). Bei 1000 m sind das 1,4 km Breite und ca. 1,1 m/px bei 720p. Die Stadt (330 m) misst dort 335 px, Gleis und Industrien sind klar zu lesen.
- Bei 4000 m (5,5 km, 4,3 m/px): Stadt 77 px, Netz 5 px breit, Icons lesbar. **Das ist meine vorläufige Grenze.**
- Bei 6000 m: nur noch Icons erkennbar, das Gelände-Muster rauscht (das 70-m-Zellmuster des Bodens blendet nicht mit der Höhe aus, Mangel der Szene).
- **Folge für F-08:** Die Kartenstufe endet in der Szene bei 1000 m und zeigt dann nur ca. 1 % einer 1.024²-Karte (10,24 km). Eine Gesamtansicht bräuchte ca. 7,4 km Höhe, dort ist die Stadt 37 px groß und das Netz nur noch eine dünne Linie. Ohne Aggregation (Icon-Cluster, Güterfluss-Bänder) ist ein 10-km-Netz nicht lesbar. Eine 512²-Karte (5,12 km) passt ab ca. 3,7 km Höhe komplett ins Bild und bleibt nach dieser Rechnung lesbar. Das ist ein Argument für die **Rückfallgröße 512²**, nicht für eine Entscheidung. Gilt für eine Szene mit 3 Objekten, 720p und hohem Kontrast.

## 4. Akzeptanzkriterien

| Kriterium | Stand |
|---|---|
| Testszene selbst gebaut (1 Stadt, 2 Industrien, Strecke, 200 MultiMesh-Quader) | **ja** (Log: 300 Häuser, 200 Instanzen) |
| Fahrt 50 → 1000 m in 5 s, kein Frame > 33 ms | **nein, nicht belegt** (Software-Renderer, alle Frames ≈ 290 ms) |
| 3 von 4 Reviewern sehen kein Popping im Video | **nicht geprüft** (5-s-Video liegt vor, keine Reviewer). Proxy-Messung statt dessen |
| 4 von 6 Kollegen finden Stadt, Industrie, Strecke in < 10 s | **nicht geprüft, an echten Personen prüfen.** Aufbau und Klick-Tool in `s03_testaufbau_kollegentest.md` |
| Entscheidung Blend ja/nein plus Lesbarkeitsgrenze im Wiki bis 20.11. | **teilweise:** vorläufig in diesem Dokument, nicht im Wiki |

## 5. Bekannte Mängel der Szene

Z-Fighting des Weihers ab ca. 1500 m (Tiefenpräzision bei near = 2 m, Fix nicht getestet: near-Plane mit der Höhe skalieren). Fahrzeuge werden an den Pfadenden ausgeblendet, damit das Umsetzen nicht springt. Industrieflächen sind in der Karte die gesättigtesten Flächen neben dem Spielernetz, das kann mit Signalorange konkurrieren. Das Video hat 5 s, nicht 2 min.

## 6. Restaufwand

ca. 1 T: GPU-Lauf (0,25), Video auf 2 min mit Kommentar (0,25), Reviewer und 6 Kollegen (0,25 plus Katrin), Felix-Review `visibility_range` (0,5 h), Wiki-Eintrag.
