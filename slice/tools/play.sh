#!/bin/bash
# Zocker-Session: spielt <session_ordner>/commands.txt frisch ab, schreibt shot.png, state.md, hängt an log.md an.
# Aufruf: tools/play.sh <session_ordner> [pfad/zu/godot] [--no-shot] [--fast] [--budget=<s>] [--bg]
#   --no-shot     kein Schlussbild (spart ca. 10 s), schreibt nur state.md
#   --fast        kürzere Panel-Pausen (spart ca. 0,2 s je Klickbefehl)
#   --budget=<s>  Zeitbudget für das Abspielen (Default 100): danach werden restliche Befehle nicht mehr gespielt,
#                 state.md vermerkt ABBRUCH, Exit 3. 0 = unbegrenzt. So bleibt ein Lauf unter 120 s (T-06).
#   --bg          Lauf im Hintergrund starten (kehrt sofort zurück); fertig, wenn <ordner>/fertig existiert
#                 (Inhalt: Exit-Code). Für Läufe, die das 120-s-Limit der Umgebung überschreiten.
# Anleitung: tools/play_help.md
OPTS=()
POS=()
BG=0
for a in "$@"; do
  case "$a" in
    --bg) BG=1 ;;
    --no-shot|--fast|--budget=*) OPTS+=("$a") ;;
    *) POS+=("$a") ;;
  esac
done
DIR=${POS[0]:?Aufruf: tools/play.sh <session_ordner> [godot] [--no-shot] [--fast] [--budget=<s>] [--bg]}
G=${POS[1]:-${GODOT:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}}
mkdir -p "$DIR"; DIR=$(cd "$DIR" && pwd)
[ -f "$DIR/commands.txt" ] || { echo "fehlt: $DIR/commands.txt"; exit 2; }
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
if [ "$BG" = 1 ]; then
  rm -f "$DIR/fertig"
  setsid nohup bash -c '"$0" "$@" > "$1/bg.txt" 2>&1; echo $? > "$1/fertig"' "$SELF" "$DIR" "$G" "${OPTS[@]}" < /dev/null > /dev/null 2>&1 &
  echo "Hintergrundlauf gestartet: warte auf $DIR/fertig (Ausgabe in $DIR/bg.txt)"
  exit 0
fi
cd "$(dirname "$0")/.." || exit 2
[ -d .godot ] || $G --headless --path . --import >/dev/null 2>&1
T0=$(date +%s.%N)
xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/play_session.gd -- "$DIR" "${OPTS[@]}" > "$DIR/run.txt" 2>&1
r=$?
grep -E "PLAY_OK|FEHLER|SCRIPT ERROR|ABBRUCH" "$DIR/run.txt"
printf "Laufzeit %.1f s, Exit %d -> %s/state.md%s\n" "$(echo "$(date +%s.%N) - $T0" | bc)" $r "$DIR" "$([[ " ${OPTS[*]} " == *" --no-shot "* ]] || echo ', shot.png')"
if grep -q "PLAY_OK" "$DIR/run.txt" && ! grep -q "SCRIPT ERROR" "$DIR/run.txt" && [ $r -eq 0 ]; then exit 0; fi
[ $r -ne 0 ] && exit $r
exit 1
