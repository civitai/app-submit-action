#!/usr/bin/env bash
# Tests for scripts/lib.sh and scripts/preflight.sh. Run: bash scripts/test-lib.sh
set -uo pipefail
# shellcheck disable=SC1091  # lib.sh is sourced by absolute path at run time
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fails=0
pass=0

# expect_ok <name> <command...>: the command must exit 0.
expect_ok() {
  local name="$1"; shift
  if out="$( (source "$here/lib.sh"; "$@") 2>&1 )"; then
    pass=$((pass + 1))
  else
    echo "FAIL (expected success): $name"; echo "$out" | sed 's/^/    /'
    fails=$((fails + 1))
  fi
}

# expect_fail <name> <message substring> <command...>: the command must exit
# non-zero AND say the expected thing, so a failure for another reason does not pass.
expect_fail() {
  local name="$1" want="$2"; shift 2
  if out="$( (source "$here/lib.sh"; "$@") 2>&1 )"; then
    echo "FAIL (expected failure): $name"; fails=$((fails + 1)); return
  fi
  if [[ "$out" != *"$want"* ]]; then
    echo "FAIL (wrong message): $name"; echo "    want: $want"; echo "    got:  $out"
    fails=$((fails + 1)); return
  fi
  pass=$((pass + 1))
}

# expect_eq <name> <expected stdout> <command...>
expect_eq() {
  local name="$1" want="$2"; shift 2
  local got
  got="$( (source "$here/lib.sh"; "$@") 2>&1 )"
  if [[ "$got" == "$want" ]]; then
    pass=$((pass + 1))
  else
    echo "FAIL: $name: want '$want', got '$got'"
    fails=$((fails + 1))
  fi
}

expect_ok   "tag ref"                 check_ref_is_tag tag refs/tags/v1.2.3
expect_fail "branch ref"              "submits only on a tag push" check_ref_is_tag branch refs/heads/main
expect_fail "tag type, branch ref"    "submits only on a tag push" check_ref_is_tag tag refs/heads/v1.2.3
expect_fail "pull request ref"        "submits only on a tag push" check_ref_is_tag "" refs/pull/7/merge

expect_ok   "v-prefixed tag"          check_tag_matches_version v1.2.3 1.2.3
expect_ok   "bare tag"                check_tag_matches_version 1.2.3 1.2.3
expect_ok   "prerelease"              check_tag_matches_version v1.2.3-rc.1 1.2.3-rc.1
expect_fail "other version"           "tag v1.2.4 does not match the manifest version 1.2.3" check_tag_matches_version v1.2.4 1.2.3
expect_fail "prefix only"             "does not match" check_tag_matches_version release-1.2.3 1.2.3
expect_fail "no manifest version"     'has no "version"' check_tag_matches_version v1.2.3 ""

expect_eq   "linux x64 platform"      linux_amd64 cli_platform Linux X64
expect_eq   "macos arm64 platform"    darwin_arm64 cli_platform macOS ARM64
expect_fail "windows runner"          "unsupported runner OS" cli_platform Windows X64
expect_eq   "bare-binary asset name"  civitai_0.1.141_linux_amd64 cli_asset_name v0.1.141 linux_amd64

# preflight.sh end to end, against a temporary app directory.
app="$(mktemp -d)"
echo '{"blockId":"demo-app","version":"0.3.0","name":"Demo"}' >"$app/block.manifest.json"
preflight() {
  env -i PATH="$PATH" GITHUB_REF_TYPE="$1" GITHUB_REF="$2" GITHUB_REF_NAME="${2##*/}" \
    RUNNER_OS=Linux RUNNER_ARCH=X64 INPUT_API_KEY="${3-key}" INPUT_PATH="$app" \
    ACTIONS_ID_TOKEN_REQUEST_URL="${4-https://example.invalid/token?api-version=2.0}" \
    ACTIONS_ID_TOKEN_REQUEST_TOKEN="${4-t}" \
    bash "$here/preflight.sh"
}
expect_ok   "preflight: matching tag"           preflight tag refs/tags/v0.3.0
expect_fail "preflight: branch push"            "submits only on a tag push" preflight branch refs/heads/main
expect_fail "preflight: tag != version"         "tag v0.3.1 does not match the manifest version 0.3.0" preflight tag refs/tags/v0.3.1
expect_fail "preflight: no api key"             "api-key input is empty" preflight tag refs/tags/v0.3.0 ""
expect_fail "preflight: no id-token permission" "id-token: write" preflight tag refs/tags/v0.3.0 key ""
rm -rf "$app"

echo "$pass passed, $fails failed"
[[ $fails -eq 0 && $pass -gt 0 ]]
