#!/bin/bash
# lauf.sh <ordner> <name> <k> <set|-> [weitere Bot-Args]
G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64
cd /tmp/claude-0/gd/s8work/oe3/slice
O=$1; N=$2; K=$3; S=$4; shift 4
SA=""; [ "$S" != "-" ] && SA="--oe_set=$S"
t0=$(date +%s)
timeout 1800 $G --headless --path . -s res://tests/s8_loop_bot.gd -- --tempo_k=$K $SA --csv=$O/$N.csv "$@" > $O/$N.log.txt 2>&1
echo "$N exit $? $(( $(date +%s)-t0 )) s load $(cut -d' ' -f1 /proc/loadavg)" >> $O/zeiten.txt
