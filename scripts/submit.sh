#!/usr/bin/env bash
# Requests the GitHub Actions OIDC token and runs `civitai app submit`.
#
# Inputs (environment):
#   CIVITAI_CLI        path to the civitai binary (from install-cli.sh)
#   INPUT_API_KEY      the Civitai API key
#   INPUT_PATH         the app directory
#   INPUT_AUDIENCE     the OIDC audience the Civitai server pins
#   INPUT_BASE_URL     the Civitai base URL
#   ACTIONS_ID_TOKEN_REQUEST_URL / _TOKEN  set by GitHub when the job has
#                      `permissions: id-token: write`
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cli="${CIVITAI_CLI:?}"

# A CLI too old to send the token would submit without it, and the submission
# would silently carry no verified source. Its help names the variable it reads.
#
# Captured first, then matched: never `"$cli" ... | grep -q` here. Under
# pipefail, grep -q exits at the first match, the CLI is still writing its help
# and dies of SIGPIPE (141), and the pipeline fails as if the variable were
# missing (measured: 76 of 100 runs falsely refused against a real CLI;
# tests/submit-capability.sh is the regression check).
help="$("$cli" app submit --help 2>/dev/null)" || help=""
if [[ "$help" != *CIVITAI_GITHUB_OIDC_TOKEN* ]]; then
  die "this civitai CLI does not send a GitHub Actions OIDC token. Set cli-version to a release that supports CIVITAI_GITHUB_OIDC_TOKEN."
fi

# Requested last, right before the submit, because the token is short-lived.
# The request URL already carries a query string, so the audience is appended.
response="$(curl -sSf --retry 3 \
  -H "Authorization: bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN:?}" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL:?}&audience=${INPUT_AUDIENCE:?}")" ||
  die "could not get a GitHub OIDC token. Check that the job has 'permissions: id-token: write'."
token="$(jq -r '.value // empty' <<<"$response")"
unset response
[[ -n "$token" ]] || die "GitHub returned no OIDC token."
# Never printed; masked in case anything echoes it.
echo "::add-mask::$token"

CIVITAI_TOKEN="${INPUT_API_KEY:?}" \
  CIVITAI_GITHUB_OIDC_TOKEN="$token" \
  CIVITAI_BASE_URL="${INPUT_BASE_URL:?}" \
  "$cli" app submit "${INPUT_PATH:-.}" --yes
