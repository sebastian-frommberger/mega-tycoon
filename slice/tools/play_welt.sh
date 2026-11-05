#!/bin/bash
# QT-05 (S8, Daniel): Welt-Session headless abspielen. Gegenstück zu tools/play.sh (das steuert nur main.tscn).
# Aufruf: tools/play_welt.sh <commands.txt|ordner> [--out=<ordner>] [--budget=<s>] [--strikt] [--tempo_k=N] [--godot=<pfad>]
#   Standard-Session: tests/play_welt_sessions/loop_l2.txt. Ausgabe (state.md, log.md, run.txt) in --out
#   (Default: /tmp/claude-0/play_welt/<name>). Exit: 0 grün · 1 Prüfung fehlgeschlagen · 3 Zeitbudget (Default 120 s) · 4 --strikt + UI übersprungen
#   Zusätzlich harte Grenze per `timeout` = Budget + 60 s (hängende Läufe = Exit 124).
# Heute headless (API-Ebene); UI-Sessions unter xvfb kommen mit AT-07/AT-08 dazu.
G=${GODOT:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
ARGS=(); POS=(); BUDGET=120; OUT=""
for a in "$@"; do
  case "$a" in
    --godot=*) G="${a#--godot=}" ;;
    --budget=*) BUDGET="${a#--budget=}"; ARGS+=("$a") ;;
    --out=*) OUT="${a#--out=}"; ARGS+=("$a") ;;
    --strikt|--tempo_k=*) ARGS+=("$a") ;;
    *) POS+=("$a") ;;
  esac
done
CMD=${POS[0]:-$(cd "$(dirname "$0")/.." && pwd)/tests/play_welt_sessions/loop_l2.txt}
cd "$(dirname "$0")/.." || exit 2
[ -d .godot ] || "$G" --headless --path . --import >/dev/null 2>&1
if [ -z "$OUT" ]; then
  n=$(basename "$CMD" .txt); [ -d "$CMD" ] && n=$(basename "$CMD")
  OUT=/tmp/claude-0/play_welt/$n; ARGS+=("--out=$OUT")
fi
mkdir -p "$OUT"
T0=$(date +%s.%N)
timeout -k 5 $(( $(printf "%.0f" "$BUDGET") + 60 )) "$G" --headless --path . -s res://tests/play_welt.gd -- "$CMD" "${ARGS[@]}" > "$OUT/run.txt" 2>&1
r=$?
grep -E "PLAY_OK|PLAY_FAIL|FEHLER|SCRIPT ERROR|ABBRUCH|UEBERSPRUNGEN" "$OUT/run.txt"
printf "Laufzeit %.1f s, Exit %d -> %s/state.md\n" "$(echo "$(date +%s.%N) - $T0" | bc)" $r "$OUT"
if grep -q "SCRIPT ERROR" "$OUT/run.txt"; then exit 1; fi
if [ $r -eq 0 ] && ! grep -q "PLAY_OK" "$OUT/run.txt"; then exit 1; fi
exit $r
