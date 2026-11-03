#!/bin/bash
cd /tmp/claude-0/gd/designsprint/p4/tobias/slice
G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64
D=/tmp/claude-0/gd/designsprint/p4/tobias/sprints/s8/design-sprint/phase4/tobias_welle1_daten
L=/tmp/claude-0/p4logs
rm -f $D/s4_skript_B.csv $D/s4_skript_C.csv
for k in b c; do
  K=$(echo $k | tr a-z A-Z)
  nice $G --headless --path . -s res://tests/p4_umland_bot2.gd -- --mode=$k --label=a0_12000_stadt --min=60 --csv=$D/s4_skript_$K.csv >> $L/s4.log 2>&1
  for spec in 4250:kleinstadt 4700:kleinstadt 3550:kleinstadt 2490:kleinstadt 2400:kleinstadt 1900:kleinstadt 1670:kleinstadt 1550:kleinstadt 1460:kleinstadt 1200:kleinstadt 900:dorf 650:dorf 520:dorf 400:dorf; do
    pop=${spec%%:*}; stg=${spec##*:}
    nice $G --headless --path . -s res://tests/p4_umland_bot2.gd -- --mode=$k --label=${pop}_$stg --min=60 --orte=mittelfurt:$pop:$stg --csv=$D/s4_skript_$K.csv >> $L/s4.log 2>&1
  done
done
echo fertig > $L/s4.done
