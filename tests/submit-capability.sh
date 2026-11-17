#!/usr/bin/env bash
# Runs scripts/submit.sh against a REAL civitai CLI binary, up to the network:
# the OIDC token request goes to a closed local port, so no token is requested
# and nothing is submitted. Every run must get PAST the CLI capability check and
# stop at the token request; a run that stops at the capability check is a false
# refusal.
#
# Usage: tests/submit-capability.sh <civitai binary> [submit.sh to test] [runs]
# EXPECT (environment) says what must hold, and decides the exit status:
#   reached      (default) every run reached the token request
#   refused-any  at least one run was refused at the capability check
#                (the control that a broken check IS caught)
#   refused-all  every run was refused (a CLI without the capability)
# The counts are printed either way.
set -uo pipefail

cli="${1:?usage: submit-capability.sh <civitai binary> [submit.sh] [runs]}"
script="${2:-$(dirname "${BASH_SOURCE[0]}")/../scripts/submit.sh}"
runs="${3:-50}"

app="$(mktemp -d)"
trap 'rm -rf "$app"' EXIT
echo '{"blockId":"capability-check","version":"0.1.0","name":"Capability check"}' >"$app/block.manifest.json"

reached=0
refused=0
other=0
for _ in $(seq "$runs"); do
  out="$(env -i PATH="$PATH" HOME="$app" \
    CIVITAI_CLI="$cli" INPUT_API_KEY=not-a-real-key INPUT_PATH="$app" \
    INPUT_AUDIENCE=civitai.com INPUT_BASE_URL=http://127.0.0.1:9 \
    ACTIONS_ID_TOKEN_REQUEST_URL='http://127.0.0.1:9/token?api-version=2.0' \
    ACTIONS_ID_TOKEN_REQUEST_TOKEN=not-a-real-token \
    bash "$script" 2>&1)"
  if [[ "$out" == *"does not send a GitHub Actions OIDC token"* ]]; then
    refused=$((refused + 1))
  elif [[ "$out" == *"could not get a GitHub OIDC token"* ]]; then
    reached=$((reached + 1))
  else
    other=$((other + 1))
    echo "unexpected output:"; echo "$out" | sed 's/^/    /'
  fi
done

echo "$runs runs: $reached reached the token request, $refused falsely refused at the capability check, $other other"
case "${EXPECT:-reached}" in
  reached) [[ $reached -eq $runs ]] ;;
  refused-any) [[ $refused -gt 0 && $other -eq 0 ]] ;;
  refused-all) [[ $refused -eq $runs ]] ;;
  *) echo "unknown EXPECT=${EXPECT}"; exit 2 ;;
esac
