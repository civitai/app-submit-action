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
PINNED_CLI_VERSION="v0.1.146"
PINNED_CLI_SHA256_linux_amd64="9a4f567300eedac677beafd034d5e3b8ecc145b63de80e9a6aa8ec25bd57dad5"
PINNED_CLI_SHA256_linux_arm64="5176ee0c5c3a72425cdf35374295e3623de848235a0838d1dc7eff9a77f3dd6f"
PINNED_CLI_SHA256_darwin_amd64="dae3a2086f7f54311aa76016faf05a4bcfa8a88b55572ecf42b8721f1fd4f285"
PINNED_CLI_SHA256_darwin_arm64="1a1773861dae60828c2aff9f2062c6665529793dd7cd16464ff00656d9bfc4bf"
