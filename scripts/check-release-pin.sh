#!/usr/bin/env bash
# Fails unless the pinned CLI (scripts/pinned-cli.sh, or the file given) is
# releasable: a real vX.Y.Z version, and a 64-hex sha256 for every platform.
# Run by CI on a tag push, so a release of this action cannot ship the
# placeholder.
#
# Usage: scripts/check-release-pin.sh [pinned-cli file]
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

file="${1:-$(dirname "${BASH_SOURCE[0]}")/pinned-cli.sh}"
# shellcheck source=scripts/pinned-cli.sh
source "$file"

problems=()
if [[ ! "${PINNED_CLI_VERSION:-}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  problems+=("PINNED_CLI_VERSION is '${PINNED_CLI_VERSION:-}', not a release tag")
fi
for platform in $CLI_PLATFORMS; do
  var="PINNED_CLI_SHA256_${platform}"
  if [[ ! "${!var:-}" =~ ^[0-9a-f]{64}$ ]]; then
    problems+=("$var is not a sha256")
  fi
done

if ((${#problems[@]})); then
  die "the pinned civitai CLI in $(basename "$file") is not releasable: $(IFS=';'; echo "${problems[*]}"). Set it to the first civitai/cli release carrying #918 before tagging."
fi
echo "Pinned civitai CLI $PINNED_CLI_VERSION with sha256 for: $CLI_PLATFORMS"
