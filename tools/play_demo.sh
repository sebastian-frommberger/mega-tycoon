#!/bin/bash
# Demo-Sprint: Demo starten (Linux/macOS). Aufruf: tools/play_demo.sh [pfad/zu/godot] [weitere Spielargumente, z. B. --vertrag_seed=3]
# Windows: play_demo.bat im Repo-Hauptordner. Im Editor: Main Run Args = "-- --demo" oder im Startmenü "Demo spielen" (Taste D).
G=${1:-${GODOT:-godot}}
[ $# -gt 0 ] && shift
HERE="$(cd "$(dirname "$0")/.." && pwd)"
if ! command -v "$G" >/dev/null 2>&1 && [ ! -x "$G" ]; then
  echo "Godot nicht gefunden: '$G'. Aufruf: tools/play_demo.sh /pfad/zu/Godot_v4.7.2 (oder Variable GODOT setzen)."; exit 2
fi
[ -d "$HERE/slice/.godot" ] || "$G" --headless --path "$HERE/slice" --import >/dev/null 2>&1
exec "$G" --path "$HERE/slice" -- --demo "$@"
