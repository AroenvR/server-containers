#!/bin/bash
#
# This script runs a Ubuntu Container management toolset

#######################################
#            Script setup             #
#######################################

# Useful globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="${LOG_PREFIX:-ubuntu_server}"

# !!! Edit path to bash library !!!
BASH_LIBS_SRC="$SCRIPT_DIR/../../lib/bash/source.sh";
if [[ ! -f "$BASH_LIBS_SRC" ]]; then
  echo "Failed to find bash library at: $BASH_LIBS_SRC"
  exit 1
fi

# Source the library.
source "$BASH_LIBS_SRC"
source_default_environment "$SCRIPT_DIR"
log "Executing the $LOG_PREFIX script in directory: $SCRIPT_DIR"

#######################################
#           Setup complete!           #
#######################################

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
  log "No arguments provided, showing help page. Usage: $0 <command> [args...]
    
    Commands:
      --render              Render the final Containerfile for debugging purposes
      -b --build            Build the container's image
      --exec                Open a disposable shell inside the container
      --remove              Remove the container's image if it exists
      --ansible             
      -h --help --man       Show this help / manual

    Example exec commands:
      --exec ls -rtAhlp /shared
      --exec ansible-playbook -i localhost, /shared/ping.yml

    Environment:
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
  --render)
    render_containerfile
    ;;

  -b|--build)
    build_image
    ;;

  --exec)
    shift
    execute_podman_command "$@"
    ;;

  --remove)
    remove_image
    ;;

  --ansible)
    shift
    execute_podman_command ansible-playbook -i localhost, "$@"
    ;;

  -h|--help|--man|*) usage ;;
esac
