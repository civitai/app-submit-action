#!/usr/bin/env bash
# Shared helpers for the action's scripts. Sourced, never executed.
# Every function is pure (arguments in, exit status and stderr out) so
# scripts/test-lib.sh can test it without a runner.

die() {
  # A GitHub Actions error annotation, then fail. The message is also kept in
  # $RUNNER_TEMP/civitai-app-submit-action/error, so a later step (this repo's
  # CI) can assert WHY the action stopped, not only that it did.
  echo "::error title=civitai/app-submit-action::$*" >&2
  if [[ -n "${RUNNER_TEMP:-}" ]]; then
    mkdir -p "$RUNNER_TEMP/civitai-app-submit-action" 2>/dev/null &&
      printf '%s\n' "$*" >"$RUNNER_TEMP/civitai-app-submit-action/error" 2>/dev/null
  fi
  exit 1
}

# check_event_is_push <GITHUB_EVENT_NAME>
# Only a push of a tag is a release: a workflow_dispatch or release event can
# run on a tag ref too, but GitHub's token then names that event and the
# Civitai server refuses it. Refusing here costs nothing to download.
check_event_is_push() {
  if [[ "$1" != "push" ]]; then
    die "this action submits only on a tag push, but this run was triggered by '${1:-an unknown event}'. Trigger the workflow with 'on: push: tags: [\"v*\"]'."
  fi
}

# check_ref_is_tag <GITHUB_REF_TYPE> <GITHUB_REF>
# The action submits only from a tag push: the server checks that the tag is the
# manifest version, and a branch push carries no version to check.
check_ref_is_tag() {
  local ref_type="$1" ref="$2"
  if [[ "$ref_type" != "tag" || "$ref" != refs/tags/* ]]; then
    die "this action submits only on a tag push, but this run is for ${ref:-an unknown ref} (${ref_type:-no ref type}). Trigger the workflow with 'on: push: tags: [\"v*\"]'."
  fi
}

# check_tag_matches_version <tag> <manifest version>
# The tag must be the manifest version, with or without a leading "v". The
# server refuses any other tag; checking here fails faster and says which file
# to change.
check_tag_matches_version() {
  local tag="$1" version="$2"
  if [[ -z "$version" || "$version" == "null" ]]; then
    die "block.manifest.json has no \"version\"."
  fi
  if [[ "$tag" != "$version" && "$tag" != "v$version" ]]; then
    die "tag $tag does not match the manifest version $version. Tag v$version (or $version), or bump \"version\" in block.manifest.json."
  fi
}

# cli_platform <RUNNER_OS> <RUNNER_ARCH>
# Prints the civitai CLI release platform suffix (e.g. linux_amd64).
cli_platform() {
  local os arch
  case "$1" in
    Linux) os=linux ;;
    macOS) os=darwin ;;
    *) die "unsupported runner OS '$1': use a Linux or macOS runner." ;;
  esac
  case "$2" in
    X64) arch=amd64 ;;
    ARM64) arch=arm64 ;;
    *) die "unsupported runner architecture '$2': use an X64 or ARM64 runner." ;;
  esac
  echo "${os}_${arch}"
}

# cli_asset_name <tag, e.g. v0.1.141> <platform>
# The bare-binary asset name goreleaser publishes: civitai_<version>_<platform>.
cli_asset_name() {
  local tag="$1" platform="$2"
  echo "civitai_${tag#v}_${platform}"
}
