#!/bin/bash
# U-03 (S7, Mira): play.sh-Durchlauf aller Bau-Fehlerfälle (tests/u03_bau_fehler.txt) mit echter Maus.
# Grün nur, wenn jede abgelehnte Zeile eine Spielmeldung hat (0 stumme Ablehnungen) und alle 12 Fehlerfälle abgelehnt wurden.
# Aufruf aus slice/: bash tests/u03_play_check.sh [godot] [slice|s7] [ordner]
G=${1:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
W=${2:-slice}
D=${3:-$(mktemp -d)}
cd "$(dirname "$0")/.." || exit 2
mkdir -p "$D"; cp tests/u03_bau_fehler.txt "$D/commands.txt"; rm -f "$D/log.md"
MT_S7_KARTE=slice bash tools/play.sh "$D" "$G" --no-shot --fast --budget=0 --welt=$W > "$D/check_run.txt" 2>&1
r=$?
n_err=$(grep -c "^FEHLER Zeile" "$D/run.txt")
n_silent=$(grep "^FEHLER Zeile" "$D/run.txt" | grep -vc "Spiel meldet")
echo "u03_play welt=$W: $n_err Ablehnungen, davon stumm $n_silent (Soll 12 / 0), play.sh Exit $r"
grep "^FEHLER Zeile" "$D/run.txt" | grep -v "Spiel meldet" | sed 's/^/  STUMM /'
[ "$r" -eq 0 ] && [ "$n_err" -eq 12 ] && [ "$n_silent" -eq 0 ] && { echo "U03_PLAY_OK"; exit 0; }
exit 1
