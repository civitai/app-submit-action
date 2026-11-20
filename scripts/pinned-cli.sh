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
PINNED_CLI_VERSION="v0.1.145"
PINNED_CLI_SHA256_linux_amd64="b5c17304daaafeecf097674f2c70c802fd0dcd8d669a774ee9707626ced2829d"
PINNED_CLI_SHA256_linux_arm64="88a64cb68833894b14adc0c6d2675355ca59161deb257d2f900c9c5fec19e3fe"
PINNED_CLI_SHA256_darwin_amd64="205c257c52a0729cb6beb46737b8403c8fbc8675741b9ca08e0b2a941dbe6a99"
PINNED_CLI_SHA256_darwin_arm64="166d6adcf5902555302b98f2f0c2c6137dff33b857931a2a692005f89b1ae23e"
