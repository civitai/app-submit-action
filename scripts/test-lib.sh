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

expect_ok   "push event"              check_event_is_push push
expect_fail "workflow_dispatch event" "triggered by 'workflow_dispatch'" check_event_is_push workflow_dispatch
expect_fail "release event"           "triggered by 'release'" check_event_is_push release
expect_fail "no event"                "triggered by 'an unknown event'" check_event_is_push ""

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
  env -i PATH="$PATH" GITHUB_EVENT_NAME="${EVENT:-push}" \
    GITHUB_REF_TYPE="$1" GITHUB_REF="$2" GITHUB_REF_NAME="${2##*/}" \
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
EVENT=workflow_dispatch expect_fail "preflight: dispatch on a tag ref" "triggered by 'workflow_dispatch'" preflight tag refs/tags/v0.3.0
EVENT=release expect_fail "preflight: release event on a tag ref" "triggered by 'release'" preflight tag refs/tags/v0.3.0
rm -rf "$app"

# A refusal is also recorded under $RUNNER_TEMP, for a later step to read.
tmp="$(mktemp -d)"
( source "$here/lib.sh"; RUNNER_TEMP="$tmp" die "recorded refusal 7731" ) 2>/dev/null
if [[ "$(cat "$tmp/civitai-app-submit-action/error" 2>/dev/null)" == "recorded refusal 7731" ]]; then
  pass=$((pass + 1))
else
  echo "FAIL: die did not record its message under RUNNER_TEMP"; fails=$((fails + 1))
fi
rm -rf "$tmp"

# What the refuses-non-tag CI job expects, on BOTH events it runs for: the real
# preflight's recorded refusal must start with expected_non_tag_refusal.
refusal_for() {
  local event="$1" ref="$2" ref_type="$3" tmp app2 want got
  tmp="$(mktemp -d)"; app2="$(mktemp -d)"
  echo '{"blockId":"demo-app","version":"0.3.0","name":"Demo"}' >"$app2/block.manifest.json"
  env -i PATH="$PATH" RUNNER_TEMP="$tmp" GITHUB_EVENT_NAME="$event" GITHUB_REF="$ref" \
    GITHUB_REF_TYPE="$ref_type" GITHUB_REF_NAME="${ref##*/}" RUNNER_OS=Linux RUNNER_ARCH=X64 \
    INPUT_API_KEY=key INPUT_PATH="$app2" bash "$here/preflight.sh" >/dev/null 2>&1
  got="$(cat "$tmp/civitai-app-submit-action/error" 2>/dev/null)"
  want="$( (source "$here/lib.sh"; expected_non_tag_refusal "$event" "$ref") )"
  rm -rf "$tmp" "$app2"
  if [[ -n "$got" && "$got" == "$want"* ]]; then
    pass=$((pass + 1))
  else
    echo "FAIL: refuses-non-tag expectation for $event $ref: want '$want…', got '$got'"
    fails=$((fails + 1))
  fi
}
refusal_for pull_request refs/pull/1/merge branch
refusal_for push refs/heads/main branch
expect_eq   "push-to-main expectation names the ref" \
  "this action submits only on a tag push, but this run is for refs/heads/main (" \
  expected_non_tag_refusal push refs/heads/main

# The release pin: the placeholder (the file as committed today), a missing sha
# and a complete pin.
pins="$(mktemp -d)"
full_pin() {
  local i=0 p
  printf 'PINNED_CLI_VERSION="v0.1.150"\n'
  for p in linux_amd64 linux_arm64 darwin_amd64 darwin_arm64; do
    i=$((i + 1))
    printf 'PINNED_CLI_SHA256_%s="%064x"\n' "$p" "$((i * 7919))"
  done
}
full_pin >"$pins/full.sh"
grep -v darwin_arm64 "$pins/full.sh" >"$pins/missing.sh"
printf 'PINNED_CLI_VERSION="PENDING-x"\n' >"$pins/placeholder.sh"
expect_ok   "release pin: complete"            bash "$here/check-release-pin.sh" "$pins/full.sh"
expect_fail "release pin: placeholder version" "PINNED_CLI_VERSION is 'PENDING-x'" bash "$here/check-release-pin.sh" "$pins/placeholder.sh"
expect_fail "release pin: a platform missing"  "PINNED_CLI_SHA256_darwin_arm64 is not a sha256" bash "$here/check-release-pin.sh" "$pins/missing.sh"
# The committed pin is still the placeholder, so a tag push today must fail.
expect_fail "release pin: the committed file"  "is not releasable" bash "$here/check-release-pin.sh"

# cli-version: pinned refuses before any download when the pin is incomplete.
install_pinned() {
  env -i PATH="$PATH" INPUT_CLI_VERSION=pinned PINNED_CLI_FILE="$1" \
    RUNNER_OS=Linux RUNNER_ARCH=X64 bash "$here/install-cli.sh"
}
expect_fail "install: pinned placeholder" "'latest' resolves to a CLI without that support" install_pinned "$pins/placeholder.sh"
printf 'PINNED_CLI_VERSION="v0.1.150"\n' >"$pins/nosha.sh"
expect_fail "install: pinned without a sha" "records no sha256 for linux_amd64" install_pinned "$pins/nosha.sh"
rm -rf "$pins"

# sha256_of agrees with a known vector.
vec="$(mktemp)"; printf 'abc' >"$vec"
expect_eq   "sha256_of" ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad sha256_of "$vec"
rm -f "$vec"

echo "$pass passed, $fails failed"
[[ $fails -eq 0 && $pass -gt 0 ]]
