#!/bin/bash
# job2.sh <label> <stadt> <n> <seed0> <orte|-> <csvname>   (v2-Skript mit ertrag_end/senke_end)
cd /tmp/claude-0/gd/designsprint/p4/tobias/slice
G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64
D=/tmp/claude-0/gd/designsprint/p4/tobias/sprints/s8/design-sprint/phase4/tobias_welle1_daten
L=/tmp/claude-0/p4logs
O=""; [ "$5" != "-" ] && O="--orte=$5"
$G --headless --path . -s res://tests/p4_umland_bot2.gd -- --n=$3 --seed0=$4 --label=$1 --stadt=$2 --min=60 $O --csv=$D/$6 > $L/$6.log 2>&1
echo "$6 fertig $(date +%T)" >> $L/jobs3.done
