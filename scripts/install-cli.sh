#!/usr/bin/env bash
# Installs the civitai CLI from its GitHub Release, verified against the
# release's checksums.txt, and prints the binary's path on stdout.
#
# Inputs (environment):
#   INPUT_CLI_VERSION  a release tag (e.g. v0.1.142) or "latest"
#   RUNNER_OS, RUNNER_ARCH, RUNNER_TEMP  set by GitHub Actions
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

repo="https://github.com/civitai/cli"
want="${INPUT_CLI_VERSION:-latest}"
platform="$(cli_platform "${RUNNER_OS:-}" "${RUNNER_ARCH:-}")"

if [[ "$want" == "latest" ]]; then
  # The /releases/latest page redirects to /releases/tag/<tag>; no API token needed.
  url="$(curl -sSfLI --retry 3 -o /dev/null -w '%{url_effective}' "$repo/releases/latest")" ||
    die "could not resolve the latest civitai CLI release."
  tag="${url##*/}"
else
  tag="$want"
fi
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "cli-version must be 'latest' or a release tag like v0.1.142 (got '$tag')."

asset="$(cli_asset_name "$tag" "$platform")"
dir="${RUNNER_TEMP:-/tmp}/civitai-cli-$tag"
mkdir -p "$dir"
curl -sSfL --retry 3 -o "$dir/$asset" "$repo/releases/download/$tag/$asset" ||
  die "could not download $asset from civitai/cli release $tag."
curl -sSfL --retry 3 -o "$dir/checksums.txt" "$repo/releases/download/$tag/checksums.txt" ||
  die "could not download checksums.txt from civitai/cli release $tag."

expected="$(awk -v a="$asset" '$2 == a { print $1 }' "$dir/checksums.txt")"
[[ -n "$expected" ]] || die "checksums.txt for $tag has no entry for $asset."
if command -v sha256sum >/dev/null; then
  actual="$(sha256sum "$dir/$asset" | awk '{ print $1 }')"
else
  actual="$(shasum -a 256 "$dir/$asset" | awk '{ print $1 }')"
fi
[[ "$actual" == "$expected" ]] || die "checksum mismatch for $asset (expected $expected, got $actual)."

mv "$dir/$asset" "$dir/civitai"
chmod +x "$dir/civitai"
echo "Installed civitai CLI $tag ($platform)." >&2
echo "$dir/civitai"
