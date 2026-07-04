#!/bin/bash
#
# Environment variable utility functions for shell scripts.

#######################################
# Safely source a dot env configuration file.
#
# If called with no argument, ENV_FILE is checked first. If ENV_FILE is not
# set or does not resolve to an existing env file, the function logs a
# verbose message and continues.
#
# If called with an argument, ENV_FILE is still checked first and the
# argument is used only if ENV_FILE does not resolve to a valid file.
#
# For either ENV_FILE or the provided argument:
#   * If the path is a directory, the function first tries
#     "<path>/.env" and then "<path>/.env.example".
#   * If the path is already a file, it is sourced directly.
#
# Globals:
#   ENV_FILE
# Arguments:
#   $1: Optional env file or directory path to source.
# Outputs:
#   Writes verbose or warning messages if no env file is found.
# Returns:
#   0 if a valid env file was sourced or no env file was usable.
#######################################
source_default_environment() {
  local requested_env_file="${1:-}"
  local resolved_env_file=""

  debug "Determining environment file from ENV_FILE or provided argument"

  if [[ -n "${ENV_FILE:-}" ]]; then
    if resolved_env_file="$(resolve_env_candidate "${ENV_FILE}")"; then
      source_env_file "${resolved_env_file}"
      return 0
    fi

    warn "ENV_FILE is set to '${ENV_FILE}', but no env file was found there"
  fi

  if [[ -n "${requested_env_file}" ]]; then
    if resolved_env_file="$(resolve_env_candidate "${requested_env_file}")"; then
      source_env_file "${resolved_env_file}"
      return 0
    fi

    warn "No env file found at provided path '${requested_env_file}'"
  fi

  verbose "No environments to source were found"
}

#######################################
# Resolve an env file or directory candidate to an existing file path.
#
# If the candidate is a directory, tries "<dir>/.env" then
# "<dir>/.env.example".
# If the candidate is a file, returns it only when it exists.
#
# Globals:
#   None
# Arguments:
#   $1: Env file or directory path.
# Outputs:
#   Writes the resolved file path to stdout.
# Returns:
#   0 if a file was found.
#   1 otherwise.
#######################################
resolve_env_candidate() {
  local candidate="${1:-}"

  if [[ -z "${candidate}" ]]; then
    return 1
  fi

  if [[ -d "${candidate}" ]]; then
    local directory="${candidate%/}"

    if [[ -f "${directory}/.env" ]]; then
      printf '%s' "${directory}/.env"
      return 0
    elif [[ -f "${directory}/.env.example" ]]; then
      printf '%s' "${directory}/.env.example"
      return 0
    fi

    return 1
  fi

  if [[ -f "${candidate}" ]]; then
    printf '%s' "${candidate}"
    return 0
  fi

  return 1
}

#######################################
# Safely source an environment file into the current shell, exporting
# every variable it defines.
#
# Sourcing executes arbitrary shell code, so as a guardrail this only
# accepts files whose final path component starts with ".env" (for
# example ".env", ".env.example", ...); anything after the
# ".env" prefix is allowed. The path is sourced exactly as provided --
# it is not rewritten, resolved, or relocated. A missing file is not an
# error: the caller simply proceeds with its defaults.
#
# Example sourcing with environment variable, .env fallback and .env.example as final fallback:
# ```bash
#   ENV_FILE_LOCATION="$(resolve_env_file "${ENV_FILE:-}" "${SCRIPT_DIR}/.env" "${SCRIPT_DIR}/.env.example")"
#   source_env_file "${ENV_FILE_LOCATION}"
# ```
#
# Globals:
#   LOG_PREFIX
# Arguments:
#   $1: Path to the environment file to source.
# Outputs:
#   Writes status messages to STDOUT (via log); writes misuse messages
#   to STDERR (via error).
# Returns:
#   0 if the file was sourced, or was absent and defaults are used.
#   Exits 1 (via error) if no path is supplied, or the final path
#   component does not start with ".env".
#######################################
source_env_file() {
  local env_file="${1:-}"

  debug "Sourcing environment variables from: $env_file"
  require_arguments 1 "$@"

  # Guardrail: refuse to source anything whose filename does not start
  # with ".env", since sourcing runs arbitrary code.
  local filename="${env_file##*/}"
  if [[ "${filename}" != .env* ]]; then
    error "Refusing to source '${env_file}'; filename must start with '.env'"
  fi

  if [[ ! -f "${env_file}" ]]; then
    warn "No env file found at ${env_file}"
    return 0
  fi

  set -a
  # shellcheck source=/dev/null
  source "${env_file}"
  set +a
}

#######################################
# Require an environment variable to be set.
# Globals:
#   None
# Arguments:
#   $1: Environment variable name to check.
# Outputs:
#   None
# Returns:
#   0 if the environment variable is set.
#   1 if the environment variable is not set.
#######################################
require_env_var() {
  local var_name="${1:-}"

  verbose "Checking required environment variable: '\$$var_name'"
  require_arguments 1 "$@"

  if [[ -z "${!var_name:-}" ]]; then
    error "Environment variable '\$$var_name' must be set to continue"
  fi
}

#######################################
# Require a command to be available on PATH.
#
# Calls error and exits if the command cannot be found. Silently continues when
# the command exists.
#
# Globals:
#   None
# Arguments:
#   $1: Command name to require.
# Outputs:
#   Writes an error message via error() when the command is missing.
# Returns:
#   0 if the command exists.
#   Exits via error() if the command is missing or no command name is provided.
#######################################
require_command() {
  local command_name="${1:-}"

  verbose "Checking if command is available: $command_name"
  require_arguments 1 "$@"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    error "Required command not found: $command_name"
  fi

  return 0
}
