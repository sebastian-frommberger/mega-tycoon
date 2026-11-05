#!/usr/bin/env bash
# WA-02: Messlauf Bodentextur/Relief. Aufnahme (Godot unter xvfb, opengl3, llvmpipe) + Auswertung (Python) -> CSV.
#   G=/pfad/zu/Godot_v4.7.2-stable_linux.x86_64 bash tests/wa02_bodenmetrik.sh <out_dir> [--sonne=<pitch>,<yaw>]
# Aus dem Ordner slice/ starten. Dauer ca. 1-1,5 Minuten. Ergebnis: <out_dir>/bodenmetrik.csv, hang_leuchtdichte.csv,
# bild_hashes.csv, meta.json, img/*.png. Voraussetzung: xvfb-run, python3 mit numpy, scipy, Pillow; Projekt importiert.
set -u
OUT="${1:?Ausgabeordner angeben}"
shift || true
G="${G:-godot}"
HIER="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUT"
START=$(date +%s)
timeout 600 xvfb-run -a -s "-screen 0 1600x900x24" "$G" --rendering-driver opengl3 --path "$HIER" -s res://tests/wa02_bodenmetrik.gd -- "$OUT" "$@" 2>&1 \
  | grep -E "^(STELLE|WIESE|WA02_AUFNAHME)|SCRIPT ERROR|Parse Error" 
test -f "$OUT/meta.json" || { echo "FEHLER: keine Aufnahme (meta.json fehlt)"; exit 1; }
python3 -I "$HIER/tests/wa02_auswertung.py" "$OUT" || exit 1
echo "WA02 gesamt $(( $(date +%s) - START )) s -> $OUT"
