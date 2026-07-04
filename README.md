# Bash Library

A modular bash library providing useful functions.  
Adheres to [GitHub's shell styling guide](https://google.github.io/styleguide/shellguide.html) as much as possible.

## Overview

This library aggregates reusable shell functions organized into focused modules:

```plaintext
<bash_lib_root>/
├── utils/              # Utility functions provided by this library.
│   ├── environment/    # Environment variable utility functions.
│   ├── file_management/# File management utility functions.
│   ├── logging/        # Logging utility functions.
│   └── podman/         # Utilities for the podman library.
│
└── source.sh           # This libary's entry point to source.
```

## Usage

Source this library's entry point in your original scripts:

```bash
# Capture the current script's absolute path.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Set a prefix for logging traceability
LOG_PREFIX="example_logging_prefix"

# Source (import) the library.
source "$SCRIPT_DIR/../../lib/source.sh"

# Log a message to using one of the sourced library's utilities.
log "Starting build process"
```

### Debug Logging

Enable verbose logging by setting the `DEBUG` variable:

```bash
DEBUG=1 source "$SCRIPT_DIR/../../lib/source.sh"
```

## Path traversal

Some utility functions provide path traversal logic. They expect to find a `.git` file/directory or a ROOT marker.  
If they don't find what they expect to find within 5 traversals or when finding certain files/directories such as `/` starting directories, `.` starting directories or f.ex. a `.bashrc/` file, they will fail.
