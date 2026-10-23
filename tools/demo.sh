#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
command -v ffmpeg >/dev/null || { printf '%s\n' 'Install FFmpeg to encode the optional demo.'; exit 1; }
python3 tools/playthrough.py
ffmpeg -hide_banner -loglevel error -y -framerate 9.954584 \
  -i build/test-results/demo/frame-%05d.png \
  -vf 'scale=720:480:flags=neighbor' -c:v libx264 -pix_fmt yuv420p \
  -movflags +faststart build/test-results/gateblade-demo.mp4
ffmpeg -hide_banner -loglevel error -y -framerate 9.954584 \
  -i build/test-results/demo/frame-%05d.png \
  -filter_complex '[0:v]scale=480:320:flags=neighbor,split[a][b];[a]palettegen[p];[b][p]paletteuse' \
  build/test-results/gateblade-demo.gif
