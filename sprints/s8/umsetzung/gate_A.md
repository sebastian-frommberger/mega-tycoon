# Gate A (Ende Block A), 05.11.2026, Stand s8

| Kriterium (ergebnis.md §6) | Ergebnis | Messart |
|---|---|---|
| volle Regression `d07_regression.sh` inkl. 11 Proto-Suiten | 35/35 Zeilen OK, 0 FAIL, 12 min 52 s | gemessen, 1 Lauf |
| Slice bitgleich: d08 --n=20 CSV md5 | 5cce648a... = Baseline | gemessen |
| slice_test 74/74 (soa, alt), parity 8/8, s11 16/16 | ok | gemessen |
| schnelle Stufe `regress_fast.sh` < 5 min | 98 s (Daniel: 3x ~70 s) | gemessen |
| Welt startet ueber Knopf, Pause/Tempo, `--tempo_k` | Knopf 5/5 Starts (xvfb), Tempo headless/simuliert belegt, **nicht auf GPU**; `--tempo_k` wirkt, **E5/E6 bei k=4/8 rot** (AT-04) | gemessen |
| Licht neu | **nur ausgelagert (WA-03a)**, WA-03b folgt nach FZ-09 | – |

Abweichungen: Szene startet noch mit fester Kette (AT-08 fehlt); E5/E6 bei k>1 offen -> FZ-09; Hang-D und BT-2 anders definiert (entscheidungslog.md). P-Menue-Absturz nicht reproduziert (QT-04).
Gate A: **gruen mit den genannten Abweichungen.** Test-Build fuer L1 (Tag 4) = s8 nach FZ-09 oder Stand jetzt (siehe L1-Karte).
