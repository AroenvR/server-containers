#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="${LOG_PREFIX:-ubuntu_server}"

source "$SCRIPT_DIR/../../libs/source.sh"
log "Executing the $LOG_PREFIX script in directory: $SCRIPT_DIR"

# Source environment variables from $ENV_FILE, fallback to .env, then .env.example.
if [[ -n "${ENV_FILE:-}" ]]; then
  env_file_location="$ENV_FILE"
elif [[ -f "$SCRIPT_DIR/.env" ]]; then
  env_file_location="$SCRIPT_DIR/.env"
else
  env_file_location="$SCRIPT_DIR/.env.example"
fi

source_env_file "$env_file_location"

require_env_var "IMAGE_NAME"
require_env_var "IMAGE_VERSION"
IMAGE_REF="$IMAGE_NAME:$IMAGE_VERSION"

HOST_SHARED_DIR="${HOST_SHARED_DIR:-$SCRIPT_DIR/shared}"

#######################################
# Render a Containerfile from a template by substituting version variables
#
# Globals:
#   SCRIPT_DIR        - Directory containing the Containerfile.template
#   IMAGE_VERSION     - Image version string to substitute for the __IMAGE_VERSION__ placeholder
# Arguments:
#   None
# Outputs:
#   Prints the rendered Containerfile content to stdout.
# Returns:
#   0 on success; exits with error if template file is not found.
#######################################
render_containerfile() {
  local CONTAINERFILE_TEMPLATE="$SCRIPT_DIR/Containerfile.template"

  require_file "$CONTAINERFILE_TEMPLATE"

  local template_content
  template_content="$(<"$CONTAINERFILE_TEMPLATE")"
  template_content="${template_content//__IMAGE_VERSION__/$IMAGE_VERSION}"

  printf '%s\n' "$template_content"
}

#######################################
# Build a Podman image from the rendered Containerfile
#
# Globals:
#   IMAGE_REF         - Full image reference (name:tag) for the image to build
#   SCRIPT_DIR        - Context directory to pass to podman build
# Arguments:
#   None
# Outputs:
#   Prints build progress and info via the `info` logging function.
# Returns:
#   Exit status of the podman build command.
#######################################
build_image() {
  info "Building image: $IMAGE_REF"

  require_command "podman"

  render_containerfile | podman build \
    -t "$IMAGE_REF" \
    -f - \
    "$SCRIPT_DIR"
}

#######################################
# Remove a local Podman image if present
#
# Globals:
#   IMAGE_REF - Full image reference (name:tag)
# Arguments:
#   None
# Outputs:
#   Logs operation via `info` and `error` helpers.
# Returns:
#   Exit status of `podman image rm`; non-zero on failure.
#######################################
remove_image() {
  info "Removing image: $IMAGE_REF"

  require_podman_image "$IMAGE_REF"

  podman image rm "$IMAGE_REF"
}

#######################################
# Print usage information and current environment configuration
#
# Globals:
#   env_file_location - The sourced environment file location
#   IMAGE_NAME        - The container image name
#   IMAGE_VERSION     - The container image version
#   CONTAINER_MOUNT_DIR - Container mount target directory
# Arguments:
#   None
# Outputs:
#   Prints usage information and environment variables via `log` function.
# Returns:
#   None
#######################################
usage() {
  log "Script usage: $0 <command> [args...]
    
    Commands:
      --exec                  Open a disposable shell inside the container
      -b --build            Build the container's image
      --remove              Remove the container's image if it exists
      --render              Render the Containerfile for debugging purposes
      -h --help --man       Show this help / manual

    Environment:
      ENV_FILE=$env_file_location
      IMAGE_NAME=$IMAGE_NAME
      IMAGE_VERSION=$IMAGE_VERSION
      IMAGE_REF=$IMAGE_REF
      CONTAINER_MOUNT_DIR=$CONTAINER_MOUNT_DIR
      HOST_SHARED_DIR=$HOST_SHARED_DIR
      CONTAINER_LOCALE=$CONTAINER_LOCALE
"
}

cmd="${1:--help}"
case "$cmd" in
  -b|--build)
    build_image
    ;;

  --remove)
    remove_image
    ;;

  --exec)
    shift
    execute_podman_command "$@"
    ;;

  --render)
  render_containerfile
  ;;

  -h|--help|--man|*) usage ;;
esac
