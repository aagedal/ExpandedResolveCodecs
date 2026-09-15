#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle_dir="$project_dir/dist/x264_encoder_plugin.dvcp.bundle"
pkg_version="${PKG_VERSION:-0.2.0}"
pkg_identifier="${PKG_IDENTIFIER:-com.aagedal.expanded-resolve-codecs.x264}"
pkg_output="${PKG_OUTPUT:-$project_dir/dist/ExpandedResolveCodecs-x264-${pkg_version}.pkg}"
install_location="/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "This package is for Apple Silicon macOS." >&2
  exit 1
fi

command -v pkgbuild >/dev/null || {
  echo "Missing build tool: pkgbuild" >&2
  exit 1
}

if [[ ! -d "$bundle_dir" ]]; then
  echo "Missing $bundle_dir; run ./scripts/build.sh first." >&2
  exit 1
fi

codesign --verify --deep --strict "$bundle_dir" || {
  echo "The plugin bundle is not a valid code-signed bundle." >&2
  exit 1
}

mkdir -p "$(dirname "$pkg_output")"

staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/expanded-resolve-codecs-pkg.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
ditto --norsrc "$bundle_dir" "$staging_dir/x264_encoder_plugin.dvcp.bundle"

pkgbuild_args=(
  pkgbuild
  --root "$staging_dir"
  --install-location "$install_location"
  --identifier "$pkg_identifier"
  --version "$pkg_version"
  --ownership recommended
)

if [[ -n "${PKG_SIGNING_IDENTITY:-}" ]]; then
  pkgbuild_args+=(--sign "$PKG_SIGNING_IDENTITY")
fi

"${pkgbuild_args[@]}" "$pkg_output"

payload_path="$(pkgutil --payload-files "$pkg_output" | rg '^\./x264_encoder_plugin\.dvcp\.bundle/Contents/MacOS/x264_encoder_plugin\.dvcp$' || true)"
if [[ -z "$payload_path" ]]; then
  echo "Package payload does not contain the x264 plugin executable." >&2
  exit 1
fi

echo "Built $pkg_output"
echo "Identifier: $pkg_identifier"
echo "Version: $pkg_version"
if [[ -n "${PKG_SIGNING_IDENTITY:-}" ]]; then
  echo "Signed with: $PKG_SIGNING_IDENTITY"
else
  echo "Package signature: unsigned (set PKG_SIGNING_IDENTITY to sign it)"
fi
