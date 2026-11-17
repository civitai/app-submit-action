#!/usr/bin/env bash
# Checks that run before anything is downloaded or requested.
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

check_event_is_push "${GITHUB_EVENT_NAME:-}"
check_ref_is_tag "${GITHUB_REF_TYPE:-}" "${GITHUB_REF:-}"
cli_platform "${RUNNER_OS:-}" "${RUNNER_ARCH:-}" >/dev/null

[[ -n "${INPUT_API_KEY:-}" ]] || die "the api-key input is empty. Pass it from a repository secret: api-key: \${{ secrets.CIVITAI_API_KEY }}"

if [[ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" || -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]]; then
  die "this job cannot request a GitHub OIDC token. Add 'permissions: id-token: write' (and 'contents: read') to the job that uses this action."
fi

manifest="${INPUT_PATH:-.}/block.manifest.json"
[[ -f "$manifest" ]] || die "no block.manifest.json at ${INPUT_PATH:-.}. Set the path input to your app's directory."
version="$(jq -r '.version // empty' "$manifest")"
check_tag_matches_version "${GITHUB_REF_NAME:-}" "$version"

echo "Submitting ${INPUT_PATH:-.} at tag ${GITHUB_REF_NAME} (manifest version $version)."
