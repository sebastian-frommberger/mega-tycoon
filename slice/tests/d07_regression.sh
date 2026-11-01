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
for blk in ui kredit parity lager; do
  $G --headless --path . -s res://tests/d07_abnahme.gd -- --only=$blk > "$LOGS/abnahme_$blk.txt" 2>&1; r=$?
  e=$(grep -c "SCRIPT ERROR" "$LOGS/abnahme_$blk.txt")
  [ "$e" -gt 0 ] && r=1
  fl=$(grep "^  FAIL" "$LOGS/abnahme_$blk.txt" | sed 's/^  FAIL //' | cut -c1-90 | tr '\n' ';')
  record "d07_abnahme --only=$blk" $r "$(grep 'Abnahmeprüfungen OK' "$LOGS/abnahme_$blk.txt") ${fl:+ -- FAIL: $fl}"
done

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
