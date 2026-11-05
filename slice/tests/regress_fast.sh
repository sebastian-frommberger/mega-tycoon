#!/bin/bash
# QT-01b (S8, Daniel): schnelle Regressionsstufe, Ziel < 300 s Wanduhr. Jeder Commit, vor dem Gate zusätzlich die volle Stufe (d07_regression.sh).
# Aufruf: tests/regress_fast.sh [pfad/zu/godot]
# Inhalt: slice_test soa/alt, parity_test, s11_test (= run_tests.sh ohne Screenshot-Lauf), d07_abnahme alle 5 Blöcke, d08_lizenzfaktor,
#   s7_boot (Default + --welt=s7), alle Proto-Suiten, statische Checks (Kasse W12, Tempo W1). NICHT enthalten (nur volle Stufe): d08_bankrott n=100,
#   s7_mira/w04/city/u03/industrie/start/validator, d08_maus, perf_s7, u03_play, Spikes, d07-Statik, Screenshots.
# Timeout je Godot-Aufruf = max(60, 3 x Baseline-Sekunden) aus sprints/s8/umsetzung/baseline/laufzeiten.txt (eine Quelle). Timeout = FAIL mit "TIMEOUT".
# Exit 0 nur, wenn alle Schritte grün sind. "SCRIPT ERROR" im Log zählt als Fehler. Suiten laufen nacheinander (keine Parallelläufe).
# FAST_SKIP_GODOT=1 überspringt alle Godot-Schritte außer FAST_EXTRA (schneller Test der statischen Checks und des Timeouts).
# Test des Timeout-Pfads: FAST_EXTRA=<abs/pfad/zu/haengt.gd> FAST_EXTRA_TIMEOUT=10 tests/regress_fast.sh  (Wegwerf-Skript, nicht im Repo)
# Ausgabe: stdout, tests/fast_summary.md, Logs in tests/fast_logs/ (beides in .gitignore).
G=${1:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE" || exit 2
BASE=../sprints/s8/umsetzung/baseline/laufzeiten.txt
LOGS=tests/fast_logs
SUM=tests/fast_summary.md
rm -rf "$LOGS"; mkdir -p "$LOGS"
rows=(); total_fail=0; T_START=$(date +%s.%N)

limit_for() {   # name -> Sekunden
  local b; b=$(awk -v n="$1" '$1==n {print $2}' "$BASE" 2>/dev/null | head -1)
  if [ -z "$b" ]; then echo 300; return; fi
  awk -v b="$b" 'BEGIN { t = int(3*b + 0.999); if (t < 60) t = 60; print t }'
}

record() {   # name, status(0/1), detail, sekunden
  local st="OK"
  if [ "$2" -ne 0 ]; then st="FAIL"; total_fail=$((total_fail+1)); fi
  rows+=("| $1 | $st | $4 | $3 |")
  printf "[%s] %s (%s s): %s\n" "$st" "$1" "$4" "$3"
}

# godot_step <name> <timeout_s|auto> <godot-args...>   Log: $LOGS/<name>.txt
godot_step() {
  local name=$1 to=$2; shift 2
  [ -n "$FAST_SKIP_GODOT" ] && [ "$name" != extra_haengt ] && return   # nur für Tests der Skript-Pfade (statische Checks, Timeout)
  [ "$to" = auto ] && to=$(limit_for "$name")
  local t0; t0=$(date +%s.%N)
  timeout -k 5 "$to" "$G" --headless --path . "$@" > "$LOGS/$name.txt" 2>&1
  local r=$? sec; sec=$(awk -v a="$t0" -v b="$(date +%s.%N)" 'BEGIN{printf "%.1f", b-a}')
  local e; e=$(grep -c "SCRIPT ERROR" "$LOGS/$name.txt")
  local fl; fl=$(grep "^  FAIL" "$LOGS/$name.txt" | sed 's/^  FAIL //' | cut -c1-80 | head -3 | tr '\n' ';')
  local ok; ok=$(grep -E 'Prüfungen OK|Paritätsprüfungen OK|Abnahmeprüfungen OK' "$LOGS/$name.txt" | tail -1 | cut -c1-80)
  if [ $r -eq 124 ] || [ $r -eq 137 ]; then
    record "$name" 1 "TIMEOUT nach ${to} s (Standard: 3 x Baseline, min. 60 s), Exit $r" "$sec"
  elif [ $r -ne 0 ] || [ "$e" -gt 0 ]; then
    record "$name" 1 "Exit $r, SCRIPT ERROR $e ${fl:+-- FAIL: $fl}" "$sec"
  else
    record "$name" 0 "${ok:-Exit 0}" "$sec"
  fi
}

# --- 1) Slice-Bestand (wie run_tests.sh, ohne Screenshot-Lauf)
godot_step slice_test_soa auto -s res://tests/slice_test.gd
godot_step slice_test_alt auto -s res://tests/slice_test.gd -- --fahrzeuge=alt
godot_step parity_test auto -s res://tests/parity_test.gd
godot_step s11_test auto -s res://tests/s11_test.gd
# --- 2) d07_abnahme, alle Blöcke
for blk in ui kredit parity lager hq; do
  godot_step "d07_abnahme_$blk" auto -s res://tests/d07_abnahme.gd -- --only=$blk
done
# --- 3) d08 Lizenzfaktor, s7_boot
godot_step d08_lizenzfaktor auto -s res://tests/d08_lizenzfaktor.gd
godot_step s7_boot_default auto -s res://tests/s7_boot.gd
godot_step s7_boot_arg auto -s res://tests/s7_boot.gd -- --welt=s7
# --- 4) Proto-Suiten (Ausgabe außerhalb res://: proto_mass schreibt sonst nach sprints/ und ändert getrackte Dateien)
for s in proto_terrain_test ta_import_test proto_epochen_test proto_strassenband_test proto_welt_test proto_sim_test \
         proto_band_hoehe_test proto_schilder_test proto_fixpass_test proto_licht_test proto_ui_welt_test s8_fk02_test; do
  godot_step "$s" auto -s res://tests/$s.gd
done
godot_step proto_easing_test auto -s res://tests/proto_easing_test.gd -- --csv="$HERE/$LOGS/proto_easing.csv"
godot_step proto_mass auto -s res://tests/proto_mass.gd -- --csv="$HERE/$LOGS/proto_mass.csv"
# --- 5) Optional: Wegwerf-Testfall für den Timeout-Pfad
if [ -n "$FAST_EXTRA" ]; then
  godot_step extra_haengt "${FAST_EXTRA_TIMEOUT:-10}" -s "$FAST_EXTRA"
fi

# --- 6) Statische Checks
# 6a) Kasse (W12): jede Zeile "cash_cent +=/-=" ausserhalb tests/ muss in economy.gd, credit.gd, core/konto.gd stehen oder in der Allowlist
# (tests/kasse_allowlist.txt: Datei|Muster|Ablauf JJJJ-MM-TT|Grund; Muster statt Zeilennummer, abgelaufen = FAIL). Neuer Treffer = FAIL.
t0=$(date +%s.%N)
python3 -I - > "$LOGS/static_kasse.txt" 2>&1 <<'PY'
import re, sys, glob, datetime
dauerhaft = {"economy.gd", "credit.gd", "core/konto.gd"}
allow = []
for l in open("tests/kasse_allowlist.txt", encoding="utf-8"):
    l = l.rstrip("\n")
    if not l.strip() or l.lstrip().startswith("#"): continue
    f, muster, ablauf, grund = [x.strip() for x in l.split("|", 3)]
    allow.append((f, muster, datetime.date.fromisoformat(ablauf), grund))
heute = datetime.date.today()
rx = re.compile(r"cash_cent\s*[-+]=")
bad, treffer, genutzt = [], 0, set()
for f in sorted(glob.glob("**/*.gd", recursive=True)):
    if f.startswith("tests/"): continue
    for i, l in enumerate(open(f, encoding="utf-8"), 1):
        if not rx.search(l.split("#", 1)[0]): continue
        treffer += 1
        if f in dauerhaft: continue
        hit = [a for a in allow if a[0] == f and a[1] in l]
        if not hit:
            bad.append(f"NEU {f}:{i}: {l.strip()[:80]}")
        else:
            if hit[0] in genutzt: bad.append(f"MEHRFACH (Allowlist-Eintrag deckt nur eine Zeile) {f}:{i}: {l.strip()[:80]}")
            genutzt.add(hit[0])
            if hit[0][2] < heute: bad.append(f"ABGELAUFEN ({hit[0][2]}) {f}:{i}: {l.strip()[:80]}")
print(f"Kasse: {treffer} Treffer ausserhalb tests/, {len(genutzt)} Allowlist-Einträge genutzt, Verstöße: {len(bad)}")
for b in bad: print("  " + b)
sys.exit(1 if bad else 0)
PY
r=$?; record "static_kasse (cash_cent +=/-=, Allowlist)" $r "$(tr '\n' ';' < "$LOGS/static_kasse.txt" | cut -c1-200)" "$(awk -v a="$t0" -v b="$(date +%s.%N)" 'BEGIN{printf "%.1f", b-a}')"
# 6b) Tempo (W1): fuhrwerk_e1/frachtwagen_e1 in vehicles.json ohne Tempofeld; fehlen die Einträge, besteht der Check.
t0=$(date +%s.%N)
python3 -I - > "$LOGS/static_tempo.txt" 2>&1 <<'PY'
import json, sys
d = json.load(open("data/vehicles.json", encoding="utf-8"))
liste = d["fahrzeuge"] if isinstance(d, dict) else d
gesucht = {"fuhrwerk_e1", "frachtwagen_e1"}
bad, gefunden = [], []
for v in liste:
    if v.get("id") in gesucht:
        gefunden.append(v["id"])
        for k in v:
            if "tempo" in k.lower() or "speed" in k.lower(): bad.append(f"{v['id']}.{k}")
print(f"Tempo: Einträge gefunden {gefunden or 'keine (Check besteht)'}, Tempofelder: {bad or 'keine'}")
sys.exit(1 if bad else 0)
PY
r=$?; record "static_tempo (W1: kein Tempofeld in fuhrwerk_e1/frachtwagen_e1)" $r "$(tr '\n' ';' < "$LOGS/static_tempo.txt" | cut -c1-200)" "$(awk -v a="$t0" -v b="$(date +%s.%N)" 'BEGIN{printf "%.1f", b-a}')"

# --- Zusammenfassung
T_SEC=$(awk -v a="$T_START" -v b="$(date +%s.%N)" 'BEGIN{printf "%.0f", b-a}')
{
  echo "# regress_fast ($(date +%Y-%m-%d), Godot $("$G" --version 2>/dev/null | head -1), Sandbox, Wanduhr)"
  echo
  echo "| Schritt | Ergebnis | Sekunden | Detail |"
  echo "|---|---|---|---|"
  for r in "${rows[@]}"; do echo "$r"; done
  echo
  echo "Gesamt: $([ $total_fail -eq 0 ] && echo GRÜN || echo "ROT, $total_fail Schritt(e) fehlgeschlagen"), Laufzeit ${T_SEC} s (Ziel < 300 s)."
} > "$SUM"
echo; cat "$SUM"
[ $total_fail -eq 0 ]
