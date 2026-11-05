# Flaky-Rate (1 Läufe, Stufe beide)

| Suite | Lauf 1 | Rot | Einordnung |
|---|---|---|---|
| d07: run_tests.sh (slice_test soa, slice_test alt, parity_test, 0 SCRIPT ERROR) | ok | 0/1 |  |
| d07: d07_abnahme --only=ui | ok | 0/1 |  |
| d07: d07_abnahme --only=kredit | ok | 0/1 |  |
| d07: d07_abnahme --only=parity | ok | 0/1 |  |
| d07: d07_abnahme --only=lager | ok | 0/1 |  |
| d07: d07_abnahme --only=hq | ok | 0/1 |  |
| d07: d08_bankrott (100 Seeds je Stadt) | ok | 0/1 |  |
| d07: d08_lizenzfaktor (Vorschau gegen Spielpreis) | ok | 0/1 |  |
| d07: s7_mira (Z-01 + B-xx Regression) | ok | 0/1 |  |
| d07: s7_w04 (Kacheln, Autotile, Brücke, Hang-Preis, Straße:Block) | ok | 0/1 |  |
| d07: s7_city (W-03 Städte: Radius, Ausfransung, Gebäude, Zonen, Leerfläche, Bäume, Nachfrage) | ok | 0/1 |  |
| d07: s7_u03 (Fehlertexte beide Welten, Vorwarnung, Kopfleiste, Linienliste; xvfb) | ok | 0/1 |  |
| d07: u03_play slice (play.sh alle Bau-Fehlerfälle, 0 stumm) | ok | 0/1 |  |
| d07: u03_play s7 (play.sh alle Bau-Fehlerfälle, 0 stumm) | ok | 0/1 |  |
| d07: s7_industrie (W-05 Fläche+Icon+Name, 4 km ≥ 24 px, kein Überlappen, Status, U8; xvfb) | ok | 0/1 |  |
| d07: s7_start (Startmenü, Beispielnetz slice+s7, Einnahmen, kein Menü in Tests; xvfb) | ok | 0/1 |  |
| d07: d08_maus (echte Maus, xvfb) | ok | 0/1 |  |
| d07: s7_boot (default) | ok | 0/1 |  |
| d07: s7_boot (arg: --welt=s7) | ok | 0/1 |  |
| d07: s7_validator (Generator md5, Validator, 20 Seeds) | ok | 0/1 |  |
| d07: perf_s7 (slice, 6 Kameras x 0/5.000 Lkw, Gate +10 %) | ok | 0/1 |  |
| d07: proto_terrain_test (Proto-Suite) | ok | 0/1 |  |
| d07: ta_import_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_epochen_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_strassenband_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_welt_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_easing_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_sim_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_band_hoehe_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_schilder_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_fixpass_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_licht_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_ui_welt_test (Proto-Suite) | ok | 0/1 |  |
| d07: s8_fk02_test (Proto-Suite) | ok | 0/1 |  |
| d07: proto_mass (Proto-Suite) | ok | 0/1 |  |
| d07: s8_bot_smoke (QT-03c) | ok | 0/1 |  |
| d07: s8_exploit_smoke (QT-03c) | ok | 0/1 |  |
| d07: Spike sim-core (run_smoke.sh) | ok | 0/1 |  |
| d07: Spike f04-signal (run_smoke.sh) | ok | 0/1 |  |
| d07: Statische Prüfungen (JSON, Icons >= 24, keine Modal-Klassen, Tween-Konstanten, Export-Filter) | ok | 0/1 |  |
| fast: slice_test_soa | ok | 0/1 |  |
| fast: slice_test_alt | ok | 0/1 |  |
| fast: parity_test | ok | 0/1 |  |
| fast: s11_test | ok | 0/1 |  |
| fast: d07_abnahme_ui | ok | 0/1 |  |
| fast: d07_abnahme_kredit | ok | 0/1 |  |
| fast: d07_abnahme_parity | ok | 0/1 |  |
| fast: d07_abnahme_lager | ok | 0/1 |  |
| fast: d07_abnahme_hq | ok | 0/1 |  |
| fast: d08_lizenzfaktor | ok | 0/1 |  |
| fast: s7_boot_default | ok | 0/1 |  |
| fast: s7_boot_arg | ok | 0/1 |  |
| fast: proto_terrain_test | ok | 0/1 |  |
| fast: ta_import_test | ok | 0/1 |  |
| fast: proto_epochen_test | ok | 0/1 |  |
| fast: proto_strassenband_test | ok | 0/1 |  |
| fast: proto_welt_test | ok | 0/1 |  |
| fast: proto_sim_test | ok | 0/1 |  |
| fast: proto_band_hoehe_test | ok | 0/1 |  |
| fast: proto_schilder_test | ok | 0/1 |  |
| fast: proto_fixpass_test | ok | 0/1 |  |
| fast: proto_licht_test | ok | 0/1 |  |
| fast: proto_ui_welt_test | ok | 0/1 |  |
| fast: s8_fk02_test | ok | 0/1 |  |
| fast: proto_easing_test | ok | 0/1 |  |
| fast: proto_mass | ok | 0/1 |  |
| fast: s8_bot_smoke | ok | 0/1 |  |
| fast: s8_exploit_smoke | ok | 0/1 |  |
| fast: static_kasse (cash_cent +=/-=, Allowlist) | ok | 0/1 |  |
| fast: static_tempo (W1: kein Tempofeld in fuhrwerk_e1/frachtwagen_e1) | ok | 0/1 |  |

Zellen (Suite x Lauf): 70, davon rot: 0, Rot-Rate 0.00 %. Richtwert: Google ca. 0,15 %, ab ca. 1 % verlieren Tests Wert (mt-qa).
Suiten mit mindestens 1 Rot: 0 → Ticket je Suite (flaky: 0, durchgehend rot: 0).

## Läufe

### lauf1
- Start 2026-11-05 11:27:57, Dauer 864 s, Loadavg vor/nach: 2.00 1.97 1.94 / 1.83 2.18 2.18
- Stufe beide, Exit d07_regression.sh: 0, regress_fast.sh: 0 (0 = grün oder nicht gelaufen)
- Git: ce84121, Godot: 4.7.2.stable.official.ed1daf0bf

Messart: Wanduhr, Sandbox (2 vCPU), Suiten nacheinander, andere Agenten können parallel Last erzeugen (Loadavg je Lauf in info.txt). Keine FPS-/Zielrechner-Aussage.
