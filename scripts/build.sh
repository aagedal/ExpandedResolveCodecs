#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$project_dir/build"
x264_source="${X264_SOURCE_DIR:-$build_dir/x264-src}"
x264_install="$build_dir/x264-install"
bundle_dir="$project_dir/dist/x264_encoder_plugin.dvcp.bundle"
plugin_binary="$bundle_dir/Contents/MacOS/x264_encoder_plugin.dvcp"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "This proof of concept builds only on Apple Silicon macOS." >&2
  exit 1
fi

for command_name in git make clang++ otool codesign; do
  command -v "$command_name" >/dev/null || {
    echo "Missing build tool: $command_name" >&2
    exit 1
  }
done

mkdir -p "$build_dir" "$(dirname "$plugin_binary")"

if [[ -z "${X264_SOURCE_DIR:-}" ]]; then
  if [[ ! -d "$x264_source/.git" ]]; then
    git clone --depth 1 https://code.videolan.org/videolan/x264.git "$x264_source"
  else
    git -C "$x264_source" pull --ff-only
  fi
fi

if [[ ! -f "$x264_source/configure" ]]; then
  echo "X264_SOURCE_DIR must point to an x264 source checkout." >&2
  exit 1
fi

pushd "$x264_source" >/dev/null
./configure --prefix="$x264_install" --enable-static --disable-cli --bit-depth=8
make -j"${X264_JOBS:-4}"
make install
x264_commit="$(git rev-parse HEAD)"
popd >/dev/null

clang++ -dynamiclib -arch arm64 -fPIC -stdlib=libc++ -std=c++11 -O2 -Wall \
  -Wl,-install_name,@rpath/x264_encoder_plugin.dvcp \
  -I"$project_dir/src/include" -I"$project_dir/src" -I"$x264_install/include" \
  "$project_dir/src/plugin.cpp" \
  "$project_dir/src/x264_encoder.cpp" \
  "$project_dir/src/wrapper/host_api.cpp" \
  "$project_dir/src/wrapper/plugin_api.cpp" \
  "$x264_install/lib/libx264.a" -lz \
  -o "$plugin_binary"

codesign --force --sign - "$plugin_binary"
if otool -L "$plugin_binary" | grep -E '/opt/homebrew|libx264.*dylib'; then
  echo "Plugin unexpectedly depends on an external x264 dynamic library." >&2
  exit 1
fi

printf '%s\n' "$x264_commit" > "$project_dir/dist/x264-commit.txt"
echo "Built $plugin_binary"
echo "x264 commit: $x264_commit"
