#!/usr/bin/env bash
# The civitai CLI release this version of the action installs by default
# (cli-version: pinned), and the sha256 of each platform's binary in it.
# Sourced by install-cli.sh and checked by check-release-pin.sh.
#
# 🔴 THE SHA256 VALUES ARE THE PIN, NOT THE TAG. install-cli.sh refuses a
# download whose sha256 is not the one recorded here. civitai/cli turned on
# immutable releases on 2026-11-17 (v0.1.142 is the first immutable one), so
# a published release's assets can no longer be swapped; the pin stays as the
# check that does not depend on that repository setting.
#
# To move the pin: set the version to a civitai/cli release tag and all four
# sha256 values from that release's checksums.txt (the bare-binary rows,
# civitai_<version>_<platform>). The release-pin CI job fails on a tag push
# while any of them is unset.
# shellcheck disable=SC2034  # read by the scripts that source this file
PINNED_CLI_VERSION="v0.1.143"
PINNED_CLI_SHA256_linux_amd64="0277211f8419076964d1159937e6ae4308e77bf5ffee2342533e8f1377ca4ed6"
PINNED_CLI_SHA256_linux_arm64="b2e4b8540556505aac7b9fbab28e481065266611f77a43dd168922a0cec6db48"
PINNED_CLI_SHA256_darwin_amd64="46f34cd365733c2e78b722e7c3bc9dd33bc414943e337bca8c9f717484cdc697"
PINNED_CLI_SHA256_darwin_arm64="8171a5ff7fedf7791a4d756d37bf1f544afa71e10b27a998d07692b74bc4fb34"
