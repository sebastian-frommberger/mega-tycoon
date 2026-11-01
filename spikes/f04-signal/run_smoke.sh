#!/bin/bash
# F-06 Smoke + Runner (Felix 24.11.). Aufruf: ./run_smoke.sh [pfad/zu/godot]
# Exit 0 nur wenn test_runner und f06_smoke Exit 0 liefern UND keine Zeile "SCRIPT ERROR" ausgegeben wurde.
G=${1:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
cd "$(dirname "$0")"
$G --headless --path . --script res://test_runner.gd > test_output.txt 2>&1; r1=$?
$G --headless --path . --script res://f06/f06_smoke.gd > f06_smoke_output.txt 2>&1; r2=$?
e=$(grep -c "SCRIPT ERROR" test_output.txt f06_smoke_output.txt | awk -F: '{s+=$2} END {print s}')
echo "test_runner Exit $r1, f06_smoke Exit $r2, SCRIPT ERROR Zeilen: $e"
[ $r1 -eq 0 ] && [ $r2 -eq 0 ] && [ "$e" -eq 0 ]
