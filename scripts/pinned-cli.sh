#!/usr/bin/env bash
# The civitai CLI release this version of the action installs by default
# (cli-version: pinned), and the sha256 of each platform's binary in it.
# Sourced by install-cli.sh and checked by check-release-pin.sh.
#
# 🔴 THE SHA256 VALUES ARE THE PIN, NOT THE TAG. civitai/cli releases are
# mutable, so a tag can later point at different bytes with a matching
# checksums.txt. install-cli.sh refuses a download whose sha256 is not the one
# recorded here.
#
# 🔴 PLACEHOLDER until the first civitai/cli release that includes
# civitai/cli#918 (CIVITAI_GITHUB_OIDC_TOKEN) exists. Before tagging a release
# of this action, set the version and all four sha256 values from that
# release's checksums.txt (the bare-binary rows, civitai_<version>_<platform>).
# The release-pin CI job fails on a tag push while any of them is unset.
# shellcheck disable=SC2034  # read by the scripts that source this file
PINNED_CLI_VERSION="PENDING-first-civitai-cli-release-with-oidc-token"
PINNED_CLI_SHA256_linux_amd64=""
PINNED_CLI_SHA256_linux_arm64=""
PINNED_CLI_SHA256_darwin_amd64=""
PINNED_CLI_SHA256_darwin_arm64=""
