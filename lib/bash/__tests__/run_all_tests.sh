#!/bin/bash
#
# This script runs all tests it is assigned to track

run_all_tests() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local boostrap_src="$script_dir/bootstrap.sh"

  if [[ ! -f "$boostrap_src" ]]; then
      echo "Failed to bootstrap test from: $boostrap_src"
      exit 1
  fi

  source "$boostrap_src"

  # What if I start sourcing here?

  debug "Finished running all tests"
}
run_all_tests