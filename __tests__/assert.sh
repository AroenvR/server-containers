#!/bin/bash
#
# This script exposes test assertion helpers.

# TODO: doc
assert_exit_code() {
  local actual="$1"
  local expected="$2"

  if [[ "$actual" -ne "$expected" ]]; then
    error "ASSERTION FAILED: expected exit code $expected but got $actual" >&2
  fi
}
