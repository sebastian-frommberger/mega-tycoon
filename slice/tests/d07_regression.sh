#!/bin/bash
# D-07 Regressionssuite (Daniel Richter, Sprint 5). Fährt ALLE Suiten nacheinander und schreibt eine Zusammenfassung.
# Aufruf: tests/d07_regression.sh [pfad/zu/godot] [spikes_root]
#   godot       Default /tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64
#   spikes_root Default /home/claude/mega-tycoon/spikes (wird vor dem Lauf kopiert, das Repo bleibt unberührt)
# Ausgabe: tests/d07_regression_summary.md (Tabelle je Suite) + Logs in tests/d07_logs/
# Exit 0 nur, wenn ALLE Suiten grün sind. Zeiten sind Sandbox-Zeiten (kein Zielrechner, keine FPS-Aussage).
G=${1:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
SPIKES=${2:-/home/claude/mega-tycoon/spikes}
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE" || exit 2
LOGS=tests/d07_logs
SUM=tests/d07_regression_summary.md
rm -rf "$LOGS"; mkdir -p "$LOGS"
rows=()
total_fail=0
T_START=$(date +%s)

record() {   # name, exit, detail
  local st="OK"
  if [ "$2" -ne 0 ]; then st="FAIL"; total_fail=$((total_fail+1)); fi
  rows+=("| $1 | $st | $3 |")
  echo "[$st] $1: $3"
}

# --- 1) Bestandssuiten des Slice (slice_test soa/alt, Parität, Screenshots-Lauf), eigener Aufruf von run_tests.sh
bash tests/run_tests.sh "$G" "$HERE/../d07_shots" > "$LOGS/run_tests.txt" 2>&1; r=$?
record "run_tests.sh (slice_test soa, slice_test alt, parity_test, 0 SCRIPT ERROR)" $r "$(grep -E 'Prüfungen OK|Paritätsprüfungen OK|SCRIPT ERROR' "$LOGS/run_tests.txt" | sed 's/Exit [0-9]*: //' | tr '\n' ';' | cut -c1-200)"

# --- 2) Unabhängige Abnahmeprüfungen (tests/d07_abnahme.gd) je Block
for blk in ui kredit parity lager hq; do
  $G --headless --path . -s res://tests/d07_abnahme.gd -- --only=$blk > "$LOGS/abnahme_$blk.txt" 2>&1; r=$?
  e=$(grep -c "SCRIPT ERROR" "$LOGS/abnahme_$blk.txt")
  [ "$e" -gt 0 ] && r=1
  fl=$(grep "^  FAIL" "$LOGS/abnahme_$blk.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
  record "d07_abnahme --only=$blk" $r "$(grep 'Abnahmeprüfungen OK' "$LOGS/abnahme_$blk.txt") ${fl:+ -- FAIL: $fl}"
done

# --- 2b) D-08 (S6): 100-Seed-Bankrottlauf im echten Spiel (3 Kandidaten-Städte × 100 Seeds × 30 Spielminuten, ca. 3 min).
# Drift-Wächter, kein Spielerbeleg für das Band 10-30 % (das ist Modell, Tobias T-14). Siehe Kopf von tests/d08_bankrott.gd.
$G --headless --path . -s res://tests/d08_bankrott.gd -- --n=100 --csv=tests/d08_logs_bankrott.csv > "$LOGS/d08_bankrott.txt" 2>&1; r=$?
e=$(grep -c "SCRIPT ERROR" "$LOGS/d08_bankrott.txt")
[ "$e" -gt 0 ] && r=1
fl=$(grep "^  FAIL" "$LOGS/d08_bankrott.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
rt=$(grep -E "^  (mittelfurt|haberau|kohlberg) " "$LOGS/d08_bankrott.txt" | sed -E 's/^ +([a-z]+) +Bankrott ([0-9]+\/[0-9]+ = [0-9]+ %).*/\1 \2/' | tr '\n' ';')
record "d08_bankrott (100 Seeds je Stadt)" $r "$(grep 'Prüfungen OK' "$LOGS/d08_bankrott.txt") $rt ${fl:+ -- FAIL: $fl}"

# --- 2c) D-08: Vorschau-Lizenzfaktor gegen Spielpreis (B-1 behoben S6 Tag 10, Generator rechnet wie economy._licence_cost).
$G --headless --path . -s res://tests/d08_lizenzfaktor.gd > "$LOGS/d08_lizenzfaktor.txt" 2>&1; r=$?
e=$(grep -c "SCRIPT ERROR" "$LOGS/d08_lizenzfaktor.txt")
[ "$e" -gt 0 ] && r=1
record "d08_lizenzfaktor (Vorschau gegen Spielpreis)" $r "$(tail -1 "$LOGS/d08_lizenzfaktor.txt" | cut -c1-120)"

# --- 2c2) S7 Block A (Mira): Z-01 Stadtanschluss beide Richtungen + B-xx (Ring-Klick, Ziele typgenau, Lizenz-Toast, -0 $)
$G --headless --path . -s res://tests/s7_mira_test.gd > "$LOGS/s7_mira.txt" 2>&1; r=$?
e=$(grep -c "SCRIPT ERROR" "$LOGS/s7_mira.txt")
[ "$e" -gt 0 ] && r=1
fl=$(grep "^  FAIL" "$LOGS/s7_mira.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
record "s7_mira (Z-01 + B-xx Regression)" $r "$(grep 'Prüfungen OK' "$LOGS/s7_mira.txt") ${fl:+ -- FAIL: $fl}"

# --- 2c3) S7 Block B (Mira): W-04 Kacheln/Autotile/Vorschau (S7) + U-03 Fehlertexte beide Welten + play.sh-Bau-Fehlerfälle
$G --headless --path . -s res://tests/s7_w04_test.gd > "$LOGS/s7_w04.txt" 2>&1; r=$?
e=$(grep -c "SCRIPT ERROR" "$LOGS/s7_w04.txt"); [ "$e" -gt 0 ] && r=1
fl=$(grep "^  FAIL" "$LOGS/s7_w04.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
record "s7_w04 (Kacheln, Autotile, Brücke, Hang-Preis, Straße:Block)" $r "$(grep 'Prüfungen OK' "$LOGS/s7_w04.txt") ${fl:+ -- FAIL: $fl}"
if command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/s7_u03_test.gd > "$LOGS/s7_u03.txt" 2>&1; r=$?
  e=$(grep -c "SCRIPT ERROR" "$LOGS/s7_u03.txt"); [ "$e" -gt 0 ] && r=1
  fl=$(grep "^  FAIL" "$LOGS/s7_u03.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
  record "s7_u03 (Fehlertexte beide Welten, Vorwarnung, Kopfleiste, Linienliste; xvfb)" $r "$(grep 'Prüfungen OK' "$LOGS/s7_u03.txt") ${fl:+ -- FAIL: $fl}"
  for w in slice s7; do
    bash tests/u03_play_check.sh "$G" $w "$LOGS/u03_play_$w" > "$LOGS/u03_play_$w.txt" 2>&1; r=$?
    record "u03_play $w (play.sh alle Bau-Fehlerfälle, 0 stumm)" $r "$(grep '^u03_play' "$LOGS/u03_play_$w.txt")"
  done
else
  record "s7_u03 / u03_play" 1 "xvfb-run fehlt"
fi

# --- 2c4) S7 Block C (Mira): W-05 Industrie-Lesbarkeit (Signalfläche + Plakette + Name, 4 km per Projektion, Status) + U8
if command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/s7_industrie_test.gd > "$LOGS/s7_industrie.txt" 2>&1; r=$?
  e=$(grep -c "SCRIPT ERROR" "$LOGS/s7_industrie.txt"); [ "$e" -gt 0 ] && r=1
  fl=$(grep "^  FAIL" "$LOGS/s7_industrie.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
  record "s7_industrie (W-05 Fläche+Icon+Name, 4 km ≥ 24 px, kein Überlappen, Status, U8; xvfb)" $r "$(grep 'Prüfungen OK' "$LOGS/s7_industrie.txt") ${fl:+ -- FAIL: $fl}"
else
  record "s7_industrie" 1 "xvfb-run fehlt"
fi

# --- 2d) D-08: HQ-Platzierung mit echter Maus (X-Zeiger über warp_mouse, echte Projektion Bildschirm -> Feld). Braucht xvfb-run.
if command -v xvfb-run >/dev/null 2>&1; then
  D08_NOSHOT=1 xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/d08_maus.gd -- "$LOGS" > "$LOGS/d08_maus.txt" 2>&1; r=$?
  e=$(grep -c "SCRIPT ERROR" "$LOGS/d08_maus.txt")
  [ "$e" -gt 0 ] && r=1
  fl=$(grep "^  FAIL" "$LOGS/d08_maus.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
  record "d08_maus (echte Maus, xvfb)" $r "$(grep 'Prüfungen OK' "$LOGS/d08_maus.txt") ${fl:+ -- FAIL: $fl}"
else
  record "d08_maus (echte Maus, xvfb)" 1 "xvfb-run fehlt"
fi

# --- 2e) S7 W-01: Suite s7_boot (Schalter --welt=s7, Kamera-Klemme 40 m-5,6 km, Maßstab 25 m/Feld, km-Texte).
# Zwei Läufe: Default-Start (muss Slice bleiben) + world_override, und der echte Kommandozeilen-Schalter.
for mode in default arg; do
  if [ "$mode" = arg ]; then a="-- --welt=s7"; else a=""; fi
  $G --headless --path . -s res://tests/s7_boot.gd $a > "$LOGS/s7_boot_$mode.txt" 2>&1; r=$?
  e=$(grep -c "SCRIPT ERROR" "$LOGS/s7_boot_$mode.txt")
  [ "$e" -gt 0 ] && r=1
  fl=$(grep "^  FAIL" "$LOGS/s7_boot_$mode.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
  record "s7_boot ($mode${a:+: --welt=s7})" $r "$(grep 'Prüfungen OK' "$LOGS/s7_boot_$mode.txt") ${fl:+ -- FAIL: $fl}"
done
# --- 2e) D-09 (S7): Perf-Baseline Slice. Dreiecke/Draw Calls/Objekte an den 6 SP-03-Kameras mit 0 und 5.000 Lkw (Zählwerte,
# keine Zeiten) gegen tests/perf_s7_baseline_slice.csv. Gate: > +10 % = rot. Neue Baseline bewusst setzen:
#   tests/perf_s7.gd -- --out=<abs>/tests/perf_s7_baseline_slice.csv (nur nach Absprache mit Daniel, Änderung im Bericht begründen).
# S7-Welt (sobald Felix' Schalter da ist): PERF_WELT=s7 PERF_BASELINE=<csv> bash tests/d07_regression.sh ...
if command -v xvfb-run >/dev/null 2>&1; then
  PW=${PERF_WELT:-slice}
  PB=${PERF_BASELINE:-$HERE/tests/perf_s7_baseline_slice.csv}
  xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/perf_s7.gd -- --welt=$PW --out=$HERE/$LOGS/perf_s7_$PW.csv --check=$PB > "$LOGS/perf_s7.txt" 2>&1; r=$?
  e=$(grep -c "SCRIPT ERROR" "$LOGS/perf_s7.txt")
  [ "$e" -gt 0 ] && r=1
  fl=$(grep "^  FAIL" "$LOGS/perf_s7.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
  record "perf_s7 ($PW, 6 Kameras x 0/5.000 Lkw, Gate +10 %)" $r "$(grep -E 'Prüfungen OK|perf_s7 FEHLER' "$LOGS/perf_s7.txt") ${fl:+ -- FAIL: $fl}"
else
  record "perf_s7" 1 "xvfb-run fehlt"
fi

# --- 3) Spike-Suiten (Kern, Signal/Diagnose) auf Kopien; prüft, dass die Slice-Änderungen die Spikes nicht berühren
if [ -d "$SPIKES" ]; then
  W=$(mktemp -d /tmp/d07_spikes.XXXXXX)
  for sp in sim-core f04-signal; do
    if [ -d "$SPIKES/$sp" ]; then
      cp -r "$SPIKES/$sp" "$W/$sp"
      bash "$W/$sp/run_smoke.sh" "$G" > "$LOGS/spike_$sp.txt" 2>&1; r=$?
      record "Spike $sp (run_smoke.sh)" $r "$(tail -1 "$LOGS/spike_$sp.txt")"
    else
      record "Spike $sp" 1 "Ordner fehlt: $SPIKES/$sp"
    fi
  done
  rm -rf "$W"
else
  record "Spike-Suiten" 1 "Spikes-Ordner fehlt: $SPIKES"
fi

# --- 4) Statische Prüfungen
python3 -I - > "$LOGS/static.txt" 2>&1 <<'PY'
import json, re, sys, pathlib, glob
root = pathlib.Path('.')
bad = []
for f in glob.glob('data/*.json') + ['ui/icons.json']:
    try:
        json.load(open(f, encoding='utf-8'))
    except Exception as e:
        bad.append(f"{f}: {e}")
print("JSON gültig:", "ja" if not bad else bad)
ic = json.load(open('ui/icons.json', encoding='utf-8'))
n = len(ic.get('icons', {}))
missing = [k for k, v in ic.get('icons', {}).items() if not (root / ic.get('pfad', 'res://ui/assets/icons/').replace('res://', '') / v['datei']).exists()]
print(f"Icons: {n} (Soll >= 24), Dateien fehlen: {missing}")
if n < 24 or missing: bad.append("icons")
modal_cls = re.compile(r'\b(AcceptDialog|ConfirmationDialog|FileDialog|PopupPanel|PopupMenu|Popup\b|Window\.new|popup_centered)')
hits = []
for f in glob.glob('**/*.gd', recursive=True):
    if f.startswith('tests/'): continue
    for i, l in enumerate(open(f, encoding='utf-8'), 1):
        if modal_cls.search(l) and not l.strip().startswith('#') and not l.strip().startswith('##'):
            hits.append(f"{f}:{i}: {l.strip()[:80]}")
print("Modal-Klassen im Code:", hits or "keine")
if hits: bad.append("modal")
fx = open('ui/ui_fx.gd', encoding='utf-8').read()
h = float(re.search(r'const HOVER_SEC := ([0-9.]+)', fx).group(1)); s = float(re.search(r'const SLIDE_SEC := ([0-9.]+)', fx).group(1))
print(f"Übergangskonstanten: Hover {h*1000:.0f} ms, Slide {s*1000:.0f} ms (Soll <= 150)")
if h > 0.15 or s > 0.15: bad.append("tween")
ex = open('export_presets.cfg', encoding='utf-8').read()
print("Export include_filter deckt ui/assets und data/*.json ab:", 'ui/assets/*' in ex and 'data/*.json' in ex)
if not ('ui/assets/*' in ex and 'data/*.json' in ex): bad.append("export")
# D-08 B-2 (behoben Tag 10): Kenney-Modelle kommen als importierte PackedScene aus dem PCK (kenney_loader.load_root).
# Spielcode darf GLBs nicht über globalize_path von der Platte lesen (in der Exe = Pfad neben der .exe).
gp = []
for f in glob.glob('**/*.gd', recursive=True):
    if f.startswith('tests/'): continue
    for i, l in enumerate(open(f, encoding='utf-8'), 1):
        code = l.split('#', 1)[0]      # S7 Block B: Kommentar ("kein globalize_path") ist kein Treffer
        if 'globalize_path' in code and ('kenney' in code.lower() or 'append_from_file' in code):
            gp.append(f"{f}:{i}")
print("B-2: Kenney-GLB über globalize_path:", gp or "keine")
if gp: bad.append("b2")
sys.exit(1 if bad else 0)
PY
r=$?
record "Statische Prüfungen (JSON, Icons >= 24, keine Modal-Klassen, Tween-Konstanten, Export-Filter)" $r "$(tr '\n' ';' < "$LOGS/static.txt" | cut -c1-220)"

# --- Zusammenfassung
T_END=$(date +%s)
{
  echo "# D-07 Regression, Sprint 5 ($(date +%Y-%m-%d), Godot $($G --version 2>/dev/null | head -1), Sandbox)"
  echo
  echo "| Suite | Ergebnis | Detail |"
  echo "|---|---|---|"
  for r in "${rows[@]}"; do echo "$r"; done
  echo
  echo "Gesamt: $([ $total_fail -eq 0 ] && echo GRÜN || echo "ROT, $total_fail Suite(n) fehlgeschlagen"), Laufzeit $((T_END-T_START)) s. Logs: $LOGS/. Keine FPS-/Zielrechner-Aussage (Sandbox, headless)."
} > "$SUM"
echo
cat "$SUM"
[ $total_fail -eq 0 ]
