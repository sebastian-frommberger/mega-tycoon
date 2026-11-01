#!/bin/bash
# F-14 Slice: headless Tests + Screenshots. Aufruf: tests/run_tests.sh [pfad/zu/godot] [shot_dir]
# Exit 0 nur wenn slice_test Exit 0 liefert UND keine Zeile "SCRIPT ERROR" ausgegeben wurde.
G=${1:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
SHOTS=${2:-$(cd "$(dirname "$0")/../.." && pwd)/shots}
cd "$(dirname "$0")/.."
$G --headless --path . -s res://tests/slice_test.gd > tests/slice_test_output.txt 2>&1; r1=$?
e=$(grep -c "SCRIPT ERROR" tests/slice_test_output.txt)
echo "slice_test Exit $r1, SCRIPT ERROR Zeilen: $e"
if command -v xvfb-run >/dev/null; then
  mkdir -p "$SHOTS"
  xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/slice_shot.gd -- "$SHOTS" > tests/slice_shot_output.txt 2>&1
  echo "Screenshots: $(grep -c '^saved' tests/slice_shot_output.txt) Dateien in $SHOTS"
fi
[ $r1 -eq 0 ] && [ "$e" -eq 0 ]
