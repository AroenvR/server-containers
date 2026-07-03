#!/bin/bash
#
# Library for common shell utilities and shared functions.

set -Eeuo pipefail

# Define this script's absolute path for easier down-sourcing of this library's packages.
LIBS_SOURCE_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Down-source utilities
. "$LIBS_SOURCE_SCRIPT_PATH/utils/source.sh"

# Debug log to make it clear to scripts that they've successfully sourced this library and its packages.
verbose "Sourced bash libs from $LIBS_SOURCE_SCRIPT_PATH"