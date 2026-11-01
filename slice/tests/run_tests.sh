#!/bin/bash
# F-14 Slice: headless Tests + Screenshots. Aufruf: tests/run_tests.sh [pfad/zu/godot] [shot_dir]
# Exit 0 nur wenn alle Läufe Exit 0 liefern UND keine Zeile "SCRIPT ERROR" ausgegeben wurde.
# F-18 (S5): slice_test läuft mit beiden Fahrzeug-Kernen (Default "soa" und Rückfall "alt"),
# dazu der Paritätstest alt gegen soa (tests/parity_test.gd).
G=${1:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
SHOTS=${2:-$(cd "$(dirname "$0")/../.." && pwd)/shots}
cd "$(dirname "$0")/.."
$G --headless --path . -s res://tests/slice_test.gd > tests/slice_test_output.txt 2>&1; r1=$?
$G --headless --path . -s res://tests/slice_test.gd -- --fahrzeuge=alt > tests/slice_test_alt_output.txt 2>&1; r2=$?
$G --headless --path . -s res://tests/parity_test.gd > tests/parity_test_output.txt 2>&1; r3=$?
e=$(cat tests/slice_test_output.txt tests/slice_test_alt_output.txt tests/parity_test_output.txt | grep -c "SCRIPT ERROR")
echo "slice_test (soa) Exit $r1: $(grep 'Prüfungen OK' tests/slice_test_output.txt)"
echo "slice_test (alt) Exit $r2: $(grep 'Prüfungen OK' tests/slice_test_alt_output.txt)"
echo "parity_test      Exit $r3: $(grep 'Paritätsprüfungen OK' tests/parity_test_output.txt)"
echo "SCRIPT ERROR Zeilen: $e"
if command -v xvfb-run >/dev/null; then
  mkdir -p "$SHOTS"
  xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/slice_shot.gd -- "$SHOTS" > tests/slice_shot_output.txt 2>&1
  echo "Screenshots: $(grep -c '^saved' tests/slice_shot_output.txt) Dateien in $SHOTS"
fi
[ $r1 -eq 0 ] && [ $r2 -eq 0 ] && [ $r3 -eq 0 ] && [ "$e" -eq 0 ]
