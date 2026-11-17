#!/usr/bin/env bash
# Installs the civitai CLI from its GitHub Release and prints the binary's path
# on stdout.
#
# Inputs (environment):
#   INPUT_CLI_VERSION  "pinned" (the default), a release tag (e.g. v0.1.142) or
#                      "latest".
#                      - pinned: the version in scripts/pinned-cli.sh, and the
#                        download must match the sha256 recorded THERE for the
#                        platform (as well as the release's checksums.txt). The
#                        bytes are pinned, not just the tag.
#                      - a tag or latest: checked only against that release's own
#                        checksums.txt. civitai/cli releases are mutable and carry
#                        no signature or build-provenance attestation, so this
#                        trusts the release as currently published.
#   PINNED_CLI_FILE    override for scripts/pinned-cli.sh (tests)
#   RUNNER_OS, RUNNER_ARCH, RUNNER_TEMP  set by GitHub Actions
set -euo pipefail
here="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=scripts/lib.sh
source "$here/lib.sh"

repo="https://github.com/civitai/cli"
want="${INPUT_CLI_VERSION:?the cli-version input is empty}"
platform="$(cli_platform "${RUNNER_OS:-}" "${RUNNER_ARCH:-}")"

pinned_sha=""
if [[ "$want" == "pinned" ]]; then
  # shellcheck source=scripts/pinned-cli.sh
  source "${PINNED_CLI_FILE:-$here/pinned-cli.sh}"
  if [[ "$PINNED_CLI_VERSION" == PENDING-* ]]; then
    die "no civitai CLI release that sends the GitHub Actions OIDC token is pinned in this version of the action yet. Pass cli-version: <a release that supports CIVITAI_GITHUB_OIDC_TOKEN>. 'latest' resolves to a CLI without that support until a civitai/cli release carrying #918 exists, and it trusts the release as published (no byte pin)."
  fi
  want="$PINNED_CLI_VERSION"
  var="PINNED_CLI_SHA256_${platform}"
  pinned_sha="${!var:-}"
  [[ "$pinned_sha" =~ ^[0-9a-f]{64}$ ]] ||
    die "this version of the action pins civitai CLI $want but records no sha256 for $platform."
fi

if [[ "$want" == "latest" ]]; then
  # The /releases/latest page redirects to /releases/tag/<tag>; no API token needed.
  url="$(curl -sSfLI --retry 3 -o /dev/null -w '%{url_effective}' "$repo/releases/latest")" ||
    die "could not resolve the latest civitai CLI release."
  tag="${url##*/}"
else
  tag="$want"
fi
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "cli-version must be 'pinned', 'latest' or a release tag like v0.1.142 (got '$tag')."

asset="$(cli_asset_name "$tag" "$platform")"
dir="${RUNNER_TEMP:-/tmp}/civitai-cli-$tag"
mkdir -p "$dir"
curl -sSfL --retry 3 -o "$dir/$asset" "$repo/releases/download/$tag/$asset" ||
  die "could not download $asset from civitai/cli release $tag."
curl -sSfL --retry 3 -o "$dir/checksums.txt" "$repo/releases/download/$tag/checksums.txt" ||
  die "could not download checksums.txt from civitai/cli release $tag."

actual="$(sha256_of "$dir/$asset")"
expected="$(awk -v a="$asset" '$2 == a { print $1 }' "$dir/checksums.txt")"
[[ -n "$expected" ]] || die "checksums.txt for $tag has no entry for $asset."
[[ "$actual" == "$expected" ]] || die "checksum mismatch for $asset (checksums.txt says $expected, got $actual)."
if [[ -n "$pinned_sha" && "$actual" != "$pinned_sha" ]]; then
  die "civitai CLI $tag for $platform is not the binary this action pins (pinned sha256 $pinned_sha, got $actual). The release may have been replaced; refusing it."
fi

mv "$dir/$asset" "$dir/civitai"
chmod +x "$dir/civitai"
echo "Installed civitai CLI $tag ($platform)${pinned_sha:+, sha256 matches the pin}." >&2
echo "$dir/civitai"
