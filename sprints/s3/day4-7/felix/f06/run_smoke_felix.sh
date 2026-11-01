#!/bin/bash
# F-06 Smoke für die geänderte Kopie (Felix, S3 Tag 4–7). Die f06-Dateien hängen am Spike-Kern
# (sim_world.gd, net_graph.gd, diagnostics.gd, test_runner.gd) in spikes/f04-signal/. Das Skript baut
# eine Wegwerf-Kopie: Spike aus dem Repo + diese f06-Dateien darüber, und ruft dort run_smoke.sh auf.
# Aufruf: ./run_smoke_felix.sh [godot] [repo]
G=${1:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
REPO=${2:-/home/claude/mega-tycoon}
HERE="$(cd "$(dirname "$0")" && pwd)"
W=$(mktemp -d)
cp -r "$REPO/spikes/f04-signal/." "$W/"
cp "$HERE"/f06_*.gd "$HERE"/f06_main.tscn "$W/f06/"
bash "$W/run_smoke.sh" "$G"; r=$?
cp "$W/f06_smoke_output.txt" "$HERE/f06_smoke_output.txt"
cp "$W/test_output.txt" "$HERE/test_runner_output.txt"
echo "Arbeitskopie: $W"
exit $r
