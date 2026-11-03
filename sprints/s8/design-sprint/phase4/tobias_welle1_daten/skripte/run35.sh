#!/bin/bash
while pgrep -f "[p]4_umland_bot2.gd" > /dev/null; do sleep 5; done
xargs -P2 -L1 /tmp/claude-0/p4/job2.sh < /tmp/claude-0/p4/stage35.jobs
echo alle > /tmp/claude-0/p4logs/stage35.done
