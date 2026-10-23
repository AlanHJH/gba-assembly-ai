#!/bin/sh
# Build upstream mGBA locally; nothing is installed globally.
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/deps
archive=build/deps/mgba-0.10.5.tar.gz
if [ ! -f "$archive" ]; then
  curl --fail --location --retry 2 --output "$archive" https://codeload.github.com/mgba-emu/mgba/tar.gz/refs/tags/0.10.5
fi
python3 - "$archive" <<'PY'
import hashlib
from pathlib import Path
import sys
expected = '91d6fbd32abcbdf030d58d3f562de25ebbc9d56040d513ff8e5c19bee9dacf14'
actual = hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest()
if actual != expected:
    raise SystemExit(f'mGBA archive checksum mismatch: {actual}')
print('Verified upstream mGBA 0.10.5 archive SHA-256.')
PY
if [ ! -d build/deps/mgba-0.10.5 ]; then
  tar -xzf "$archive" -C build/deps
fi
# An extracted release must not inherit the game's parent Git version.
GIT_CEILING_DIRECTORIES="$(pwd)/build/deps"
export GIT_CEILING_DIRECTORIES
cmake -S build/deps/mgba-0.10.5 -B build/emulator \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DSKIP_GIT=ON \
  -DBUILD_QT=OFF -DBUILD_SDL="${MGBA_BUILD_SDL:-ON}" -DBUILD_LIBRETRO=ON \
  -DBUILD_SHARED=OFF -DBUILD_STATIC=OFF \
  -DBUILD_GL=OFF -DBUILD_GLES2=OFF -DBUILD_GLES3=OFF -DUSE_EPOXY=OFF \
  -DM_CORE_GB=OFF -DUSE_FFMPEG=OFF -DUSE_LIBZIP=OFF \
  -DUSE_MINIZIP=OFF -DUSE_LUA=OFF -DUSE_SQLITE3=OFF \
  -DUSE_ELF=OFF -DUSE_DISCORD_RPC=OFF -DUSE_EDITLINE=OFF \
  -DUSE_PNG=OFF -DUSE_LZMA=OFF
cmake --build build/emulator --parallel 4
