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
PINNED_CLI_VERSION="v0.1.142"
PINNED_CLI_SHA256_linux_amd64="43773853ef50b5475ce4d7e25947b905fd0adaa3938f183a4751ecd7a58d9976"
PINNED_CLI_SHA256_linux_arm64="6d6739c2e82b1c1b80af5cbb506f836648bfa9a391f84d097b8aa154753b07d5"
PINNED_CLI_SHA256_darwin_amd64="ec63a84636f05dfc159fb8b5448f79413dfc423f9acf47022fdb4d93c5ec10a7"
PINNED_CLI_SHA256_darwin_arm64="6ee2e0a3bf38189b1e3b76f6e40228c6c05dec297a47e2ee08e917eacc157da0"
