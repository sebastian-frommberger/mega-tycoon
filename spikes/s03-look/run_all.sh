#!/bin/bash
# Reproduziert alle Artefakte der Look-Szene (Software-Renderer via xvfb, 1280x720).
# Aufruf: ./run_all.sh [godot-binary]
G=${1:-/tmp/claude-0/gd/Godot_v4.4.1-stable_linux.x86_64}
cd "$(dirname "$0")"
run(){ timeout 580 xvfb-run -a -s "-screen 0 1280x720x24" "$G" --rendering-driver opengl3 --rendering-method gl_compatibility --path . -- "$@" 2>&1 | grep -v -E "ALSA|status < 0|audio|V-Sync|set_use_vsync|initialize \("; }
run --shots
run --shots --hard
run --shots --labels
run --shots --nohud
run --selftest --pid=2
run --far
run --strip
run --popping
run --popping --hard
run --fly
run --fly --hard
# 5-s-Fahrt als Video (Movie Maker, 30 fps fest, ohne HUD) - Software-Renderer, nicht Echtzeit
mkdir -p video
timeout 580 xvfb-run -a -s "-screen 0 1280x720x24" "$G" --rendering-driver opengl3 --rendering-method gl_compatibility --path . --write-movie "$PWD/video/fahrt_50_1000m.avi" --fixed-fps 30 -- --movie --nohud 2>&1 | grep -v -E "ALSA|status < 0|audio|V-Sync|set_use_vsync|initialize \(" | tail -3
ffmpeg -y -loglevel error -i video/fahrt_50_1000m.avi -c:v libx264 -pix_fmt yuv420p video/fahrt_50_1000m.mp4 && echo "mp4 ok"
