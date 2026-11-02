#!/bin/bash
# W-06 (S7, Felix): Suite s7_validator. Aufruf aus slice/: bash tests/s7_validator.sh [logordner]
#  1) Determinismus + Aktualität: Default-Seed (world_s7_meta.json) neu erzeugen, alle 7 Dateien md5-gleich zu world/data/
#  2) Validator auf world/data/ (Schema, Regeln R1-R8, Ketten, Plateaus, Fluss, Erreichbarkeit, md5 der Rohdaten): Exit 0
#  3) 20 Seeds (1..20) im Speicher erzeugen + validieren: 0 Verstöße, 0 unlösbar (2 Prozesse parallel)
# Exit 0 nur, wenn alle drei Schritte grün sind. Python: python3 -I, numpy (+ scipy für Faltung/Komponenten).
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE" || exit 2
L=${1:-$(mktemp -d)}
mkdir -p "$L"
fail=0
SEED=$(python3 -I -c "import json; print(json.load(open('world/data/world_s7_meta.json'))['seed'])")
T=$(mktemp -d)
cp world/data/rules_s7.json "$T/"
python3 -I tools/world_gen.py --seed "$SEED" --out "$T" --quiet > "$L/gen.txt" 2>&1 || fail=1
nd=0
for f in hoehe_s7.r16 rand_s7.r16 fluss_s7.u8 world_s7_meta.json world_s7.json hq_vorschau_s7.json; do
  a=$(md5sum < "world/data/$f" | cut -c1-32); b=$(md5sum < "$T/$f" | cut -c1-32)
  [ "$a" = "$b" ] || { echo "md5 abweichend: $f ($a / $b)"; nd=$((nd+1)); }
done
echo "s7_validator Determinismus: Seed $SEED neu erzeugt, $nd von 6 Dateien abweichend (Soll 0)"
[ $nd -eq 0 ] || fail=1
rm -rf "$T"
python3 -I tools/world_validate.py --dir world/data > "$L/validate_default.txt" 2>&1 || fail=1
echo "s7_validator Karte world/data: $(grep VALIDIERUNG "$L/validate_default.txt")"
python3 -I -u tools/world_validate.py --seeds 1..10 > "$L/seeds_a.txt" 2>&1 & p1=$!
python3 -I -u tools/world_validate.py --seeds 11..20 > "$L/seeds_b.txt" 2>&1 & p2=$!
wait $p1 || fail=1
wait $p2 || fail=1
ok=$(cat "$L/seeds_a.txt" "$L/seeds_b.txt" | grep -c "^SEED [0-9]*: OK")
echo "s7_validator 20 Seeds: $ok/20 OK (0 Verstöße, lösbar)"
grep -h "VERSTOESSE\|UNLOESBAR" "$L/seeds_a.txt" "$L/seeds_b.txt" | head -5
[ "$ok" -eq 20 ] || fail=1
exit $fail
