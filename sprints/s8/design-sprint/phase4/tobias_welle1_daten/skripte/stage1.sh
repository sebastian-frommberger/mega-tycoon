#!/bin/bash
# Stufe 1: formal 3 Seeds x 3 Laeufe je Variante, 60 min Horizont
cd /tmp/claude-0/gd/designsprint/p4/tobias/slice
G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64
D=/tmp/claude-0/gd/designsprint/p4/tobias/sprints/s8/design-sprint/phase4/tobias_welle1_daten
L=/tmp/claude-0/p4logs
run() { # label seed0 n orte csv
  $G --headless --path . -s res://tests/p4_umland_bot.gd -- --n=$3 --seed0=$2 --label=$1 --min=60 ${4:+--orte=$4} --csv=$D/$5 > $L/$5.log 2>&1
}
run a0_formal 0 9 "" stufe1_a0.csv &
O1=$(python3 /tmp/claude-0/p4/gen_orte.py | sed -n 1p | cut -d' ' -f2)
O2=$(python3 /tmp/claude-0/p4/gen_orte.py | sed -n 3p | cut -d' ' -f2)
O3=$(python3 /tmp/claude-0/p4/gen_orte.py | sed -n 5p | cut -d' ' -f2)
run b_w1 0 3 "$O1" stufe1_b_w1.csv
wait
run b_w2 3 3 "$O2" stufe1_b_w2.csv &
run b_w3 6 3 "$O3" stufe1_b_w3.csv
wait
echo fertig > $L/stufe1.done
