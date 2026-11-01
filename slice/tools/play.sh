#!/bin/bash
# Zocker-Session: spielt <session_ordner>/commands.txt frisch ab, schreibt shot.png, state.md, hängt an log.md an.
# Aufruf: tools/play.sh <session_ordner> [pfad/zu/godot]     Anleitung: tools/play_help.md
DIR=${1:?Aufruf: tools/play.sh <session_ordner>}
G=${2:-${GODOT:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}}
mkdir -p "$DIR"; DIR=$(cd "$DIR" && pwd)
[ -f "$DIR/commands.txt" ] || { echo "fehlt: $DIR/commands.txt"; exit 2; }
cd "$(dirname "$0")/.." || exit 2
[ -d .godot ] || $G --headless --path . --import >/dev/null 2>&1
T0=$(date +%s.%N)
xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/play_session.gd -- "$DIR" > "$DIR/run.txt" 2>&1
r=$?
grep -E "PLAY_OK|FEHLER|SCRIPT ERROR" "$DIR/run.txt"
printf "Laufzeit %.1f s, Exit %d -> %s/state.md, shot.png\n" "$(echo "$(date +%s.%N) - $T0" | bc)" $r "$DIR"
grep -q "PLAY_OK" "$DIR/run.txt" && ! grep -q "SCRIPT ERROR" "$DIR/run.txt"
