# Fix-Pass W2 – visuelle Mängel der Look-Abnahme (Technical Artist + Mira)

Stand: Prototyp „Welt“, Welle 2 integriert. Arbeitskopie `wc/slice` (nicht `/home/claude/mega-tycoon`). Godot 4.7.2, Compatibility (opengl3).
Bilder: JPG q80 unter `bilder/fix/` (je Mangel `mN_…_vorher.jpg` / `…_nachher.jpg`, 1600×900, Nahansicht). Erzeugt mit `slice/tests/proto_shots_fix.gd`.
Maßstab: Charter E1 „nichts überzeichnet, alles im Verhältnis“, E6 abgestufte Ortsordnung (2 Kleinstädte, Marktflecken, viele Dörfer).

## Übersicht

| # | Mangel | Ursache | Fix | Beleg-Bild | offen |
|---|---|---|---|---|---|
| M1 | Fuhrwerk-Räder laufen neben dem Feldweg | Rechtsverkehr-Spur 1,5 m galt auf jedem Band; Feldweg-Fahrbahn nur 3,5 m, Gespann 2,2 m breit → rechte Räder 0,2 m über der Bandkante. Höhe/Neigung kamen nur aus der Mittellinie. | `proto_easing.gd`: `Profil.spur_fuer(fahrbahn_m)` – Band < 4 m (`SPUR_SCHMAL_M`): Bandmitte; breitere Bänder: Rechtsverkehr nur so weit, dass `SPUR_RAND_M` = 0,4 m Luft bleibt. Spur-Wechsel zwischen Wegen 3 × Kasten-Filter über 10 m (kein Positionssprung E2, kein Knick im Tempolimit). Querneigung des Bands (Höhe bei ±Breite/2) wird als zusätzliches Rollen auf die Pose gegeben (`quer`, nicht auf Brücke/Rampe, ±6°). `proto_sim.gd` reicht die Bandbreite je Probe durch (`fahrbahn_m`), `proto_strassenband.gd` hält `hoehe_funktion` für die Querneigung. | `m1_fuhrwerk_*` (40 m) | Querneigung nur Roll der Pose, kein eigenes Rad-Höhen-Sampling je Achse. |
| M2 | Gespann am Gutshof ragt über das Wegende | Pose-Mitte lief bis zum letzten Bandpunkt (Sackgasse), Gespann (≈ 10 m) ragte halb darüber hinaus. | `Routenlinie.rand_start/rand_ende` (nur an Knoten mit Grad 1 gesetzt, `proto_sim.routenlinie`): Pose wird linear auf `[halbe Länge + 0,3 m, Länge − …]` gestaucht (`pose_p`). Sim-Position/Tick-Zeiten (z.zb, p_bild) bleiben unverändert → E1–E7 unberührt. | `m2_gespann_gutshof_*` | Der Gutsweg selbst endet in den Stadt-Daten (`proto_wege.json`) ≈ 20 m vor dem Hoftor, das Gespann hält daher „im Weg“, aber nicht am Tor (Datenfrage Stadt). Beim Wenden am Ende überstreicht das Gespann konstruktiv mehr als die 3,5 m Band. |
| M3 | Schild „Lindenfurt“ schwebt neben dem Ort | Anker = Ortsmittelpunkt aus `proto_orte.json` (liegt abseits des gebauten Kerns) + 40 m Höhe; Zeiger ohne sichtbaren Fußpunkt. | `proto_schilder.gd`: Anker am Marktplatz-Mittelpunkt (Kleinstadt/Marktflecken) bzw. an der Kirche (Dorf) aus `proto_instanzen.json` (`ax/az`); Ankerhöhe Kleinstadt 40→24 m, Marktflecken 30→20 m, Dorf 18→14 m (Verhältnis zum Gelände, E1). Zeiger zeichnet immer eine Fußlinie (dunkle Unterlage + helle Linie) vom Schild bis zu einem Ring am Fußpunkt im Ort. | `m3_schild_lindenfurt_*` (350 m) | – |
| M4 | Schild „Erlenbach“ am Bildrand beschnitten | Das Layout klemmte nur Mittelpunkt/Ziel, nicht den Schildrahmen. | `proto_schilder.gd`: Rahmen wird mit `RAND_PX` = 8 px in den Viewport geklemmt; Entzerrung versucht erst nach oben, dann nach unten; Zeigerfuß gleitet entlang der Schildunterkante zum Fußpunkt; Sichtbarkeit nutzt `SICHT_RAND_PX` = 48 px Rand (Orte knapp außerhalb des Bildes behalten ein Schild am Rand). | `m4_schild_erlenbach_*` (750 m) | – |
| M5 | Wasserrad der Erlenmühle fehlt | Das Prefab `wassermuehle_rad` stand als Instanz senkrecht zur Giebelwand und 10 m vom Wasser, außerdem ohne Wasserzulauf; im Bild nicht sichtbar. | `proto_kulissen.gd`: `_muehlrad_einrichten` – prozedurales Wasserrad (Prefab-Mesh, Teil 5 dreht über TIME, Ø 5 m, Dicke 2,36 m) parallel an der teichseitigen Langwand der Mühle, Drehsinn mit dem Wasser (Unterschlächtig), Achskasten und Bohle aus Holz; Mühlgraben als 3-m-Wasserband (zwei Streifen: Teichufer → Ecke, Wand entlang → Bach) mit `proto_wasser.gd`-Material. Anker-/Lagedaten in `kulissen.lage["muehlrad"]`. | `m5_wasserrad_*` (nachher 45 m von Süden/Teichseite; vorher: dieselbe Mühle bei 180 m, dort kein Rad erkennbar – andere Kamera, weil die alte Instanz von der Südseite nicht zu sehen war) | Mühlgraben ist ein einfaches Streifenband (kein Gefälle/Stau modelliert); Ecke und Ende ragen minimal ins Feld. |
| M6 | Feld-Nähte/Moiré zwischen Feldern (750 m) | Acker-Streifenrichtung wurde je 200×125-m-Block gewürfelt: harte Nähte; Streifen mit < 1 px Periode → Moiré. | `proto_terrain.gd`: `_schlag_textur()` (Voronoi-„Schläge“ über Acker-Zellen, Richtung je Schlag, Textur `schlag`); `proto_terrain.gdshader`: Richtung aus dieser Textur, Streifenkontrast wird per `fwidth` ausgeblendet, sobald die Periode < ~½ px ist. Ein experimentelles „Feldrain“ wurde wieder entfernt (sah aus wie Risse). | `m6_felder_750m_*`, `m6b_felder_750m_*` | Richtungswechsel liegt jetzt an Schlaggrenzen (natürlich), aber an Zellrändern bleibt eine feine Stufung der Bodenkarte (25-m-Raster). |
| M7 | Marktplatz Lindenfurt flach grau | Fläche war ein einfarbiges Mesh (`flaeche_marktplatz`), keine Ausstattung. | Neuer Shader `world/proto_flaeche.gdshader` (Welt-Raum, kein UV): Modus 1 Pflaster im Läuferverband 0,46 × 0,30 m, Fugen + Tonvariation, `fwidth`-Ausblendung; Modus 2 Kies (Hofflächen). `proto_platzhalter.gd` weist `flaeche_marktplatz`→1, `flaeche_hof`→2 zu. 8 Marktstände (`marktstand`-Prefab aus Kenney-`stall.glb` + 4 Pfosten, Tuchdach, 3 Kisten; `proto_prefabs.gd`) in zwei Reihen entlang des Platzrandes (`proto_kulissen._markt_einrichten`, MultiMesh, Sichtweite 900 m). | `m7_marktplatz_*` (120 m) | Brunnen: kein eigenes Modell im Kenney-Satz, nicht gebaut (Schild-Ring markiert die Platzmitte). Stände sind aus 120 m klein; Wahl der Reihen ist Platzhalter. |
| M8 | Weiler Hasenwinkel: Schild nur < 500 m | Aylins Kompromiss („nur Name ≤ 500 m“) widerspricht dem Regelwerk und der Charter. | **Entscheidung: kein Schild.** Charter E6 kennt keine Weiler-Stufe (nur Kleinstadt/Marktflecken/Dorf), Regelwerk `label.hierarchie.weiler = "nie"`, `ortsklassen.weiler.label_uebersicht = false`; E1 (nichts überzeichnet) – ein Namensschild vor 6 Häusern wäre überzeichnet. `proto_schilder.gd`: `WEILER_NAH_BIS_M := 0.0` (Weiler nie sichtbar). Die Option „nur Name im Nahbereich“ bleibt mit einem Wert > 0 schaltbar. Tooltip/Daten bleiben unberührt. | `m8_hasenwinkel_300m_*` | Falls der PO den Nahbereichs-Namen doch will: `WEILER_NAH_BIS_M` = 500 setzen (Test passt sich an). |

## Test-/Vertragsänderungen

| Datei | Änderung | Begründung |
|---|---|---|
| `slice/tests/proto_schilder_test.gd` | Prüfung „Weiler nur im Nahbereich ≤ 500 m, nur Name“ → „Weiler: nie ein Schild“ (verzweigt auf `WEILER_NAH_BIS_M`). „Weiler nie im Übersichtsschild“ unverändert. | bewusste Vertragsänderung M8 (s. o.) |
| `slice/tests/proto_fixpass_test.gd` (neu) | 12 Prüfungen: Spur Feldweg = 0, Luft auf breiten Bändern, Halt-Rand, Feldweg-Proben auf Bandmitte, Sackgassen-Pose im Band, Wasserrad vorhanden, 8 Marktstände, Schild-Rahmen im Viewport (Preset 5), Lindenfurt-Fußpunkt, Weiler ohne Schild. | Absicherung der Fixes |

Sonst keine Teständerung. Zwischenbefund während der Arbeit: Ein erster Spur-Filter (einfacher Kasten) setzte Knicke in den Spur-Versatz; daraus entstanden Krümmungsspitzen, die das Kurventempo bremsten und `proto_easing_test` E5 (B: 20 Verstöße, 1,25 × W/2) rot färbten. Behoben, indem (a) der Spur-Übergang dreifach geglättet wird und (b) Krümmung/Tempolimit weiter aus der Referenz-Spur (konstanter Versatz `prof.spur`) berechnet werden – der Versatz ändert nur die Pose, nicht das Tempoprofil. E5 A/B wieder 1,00 × W/2, 0 Verstöße; E6 A 1,30 / B 1,38 × W/2 wie in der Integration W2 (bewusste Abweichung I11, unverändert).

## Testläufe (headless, `--path slice -s res://tests/<name>.gd`)

| Suite | Ergebnis |
|---|---|
| proto_band_hoehe_test | 2 OK, 0 FAIL |
| proto_easing_test | 15 OK, 0 FAIL, 2 bewusste Abweichungen (E6 A/B, unverändert offen) |
| proto_epochen_test | 17 OK |
| proto_schilder_test | 51 OK, 0 FAIL |
| proto_sim_test | 11 OK |
| proto_strassenband_test | 36 OK |
| proto_terrain_test | grün |
| proto_welt_test | 35 OK |
| ta_import_test, ta_welle2_test | grün (23 OK) |
| proto_mass | 95 Messzeilen, 0 FAIL |
| proto_fixpass_test (neu) | 12 OK |

`--check-only` für alle geänderten Skripte ohne Fehlerzeile. API gegen die installierte Engine geprüft (u. a. `Image.create_from_data`, `MultiMesh.use_custom_data`, `SurfaceTool`, `fwidth` im Spatial-Shader, `Basis`/`Transform3D`-Konstruktoren); Headless-Dummy-Renderer liefert Identitäts-Transforms für MultiMesh → visuelle Belege nur aus opengl3-Rendern.

## Performance-Gate (xvfb, opengl3, `fix_perf.txt`)

| Messung | vorher | nachher | Gate |
|---|---|---|---|
| Übersicht (Preset 1, 3000 m) | 145 644 Dreiecke / 107 DC | 146 208 / 118 DC | ≤ 1,0 Mio / ≤ 300 DC – eingehalten |
| Dorf (Preset 2, 450 m) | 576 861 / 120 DC | 576 967 / 123 DC | – |
| Marktplatz (120 m) | 400 935 / 54 DC | 404 633 / 57 DC | – |
| Ladezeit Szene | 2,0–2,1 s | 1,6–1,9 s (Wandzeit headless 1,96 s) | ≤ 3 s – eingehalten |

Der Mehraufwand: 8 Marktstände (MultiMesh, 1 DC), Wasserrad + Mühlgraben (≈ 4 DC), Pflaster/Kies-Shader (keine Mehrgeometrie).
Hinweis: Weitwinkel-Ansicht `m6b` (750 m, 1,06 Mio live) liegt unverändert gegenüber vorher – sie ist kein Übersichts-Gate-Preset.

## Geänderte/neue Dateien (relativ zu `wc/`)

- `slice/proto/proto_easing.gd`, `proto_sim.gd`, `proto_strassenband.gd`, `proto_schilder.gd`, `proto_kulissen.gd`, `proto_platzhalter.gd`
- `slice/world/proto_prefabs.gd`, `proto_terrain.gd`, `proto_terrain.gdshader`, `proto_flaeche.gdshader` (neu)
- `slice/tests/proto_schilder_test.gd` (Vertrag M8), `proto_fixpass_test.gd` (neu), `proto_shots_fix.gd` (neu)
- `sprints/s8/design-sprint/phase4/fixpass_w2.md`, `sprints/s8/design-sprint/phase4/bilder/fix/*.jpg` (18 Bilder)
- Von den Testläufen neu geschrieben (Messdaten): `proto_easing.csv`, `proto_mass.csv` u. ä. in `sprints/s8/design-sprint/phase4/`

## Offen (gesammelt)

1. Gutsweg endet laut `proto_wege.json` ≈ 20 m vor dem Hoftor (Datenfrage Stadt); Wenden am Sackgassen-Ende überstreicht breiter als das 3,5-m-Band.
2. Mühlgraben nur als Streifenband, ohne Gefälle/Überlauf; Rad ohne eigene Wasserwirbel.
3. Kein Brunnen auf dem Marktplatz (kein passendes Kenney-Modell); Marktstand-Anordnung Platzhalter.
4. Felder: Bodenkarte bleibt 25-m-Raster; Schlaggrenzen sind Voronoi-förmig, keine echten Flurstücke.
5. E6 (Zeitversatz Bild/Sim) weiter „ABW bewusst“ (aus Integration W2 I11), E5 grün.
6. Weiler-Nahbereichsname: Entscheidung PO offen, falls abweichend von Charter/Regelwerk gewünscht (`WEILER_NAH_BIS_M`).
