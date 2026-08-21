#!/bin/sh
###############################################################################
# File  : initial-cmake.sh
###############################################################################

set -e

usage () {
  echo "Usage: $0 [-f] [-b build_dir] [-p prefix] [-G generator]"
  echo "       [-P preset] [source_dir] [args]"
}

log() { printf "%s\n" "$1" >&2 ; }
abspath() { printf "%s/%s" "$(cd "$(dirname "$1")" && pwd)" "$(basename "$1")" ; }
is_command() { \command -v "$1" >/dev/null 2>&1 ; }

# Check for cmake first
if ! is_command cmake; then
  log "Error: 'cmake' command not available"
  exit 1
fi

overwrite=false
build_dir=
prefix_dir=
generator=
extra_args=

# Process options
OPTIND=1
while getopts "fb:p:GP:" opt; do
  case "${opt}" in
    f) overwrite=true ;;
    b) build_dir=${OPTARG} ;;
    p) prefix_dir="$(abspath "${OPTARG}")" ;;
    P) extra_args="${extra_args} --preset=${OPTARG}" ;;
    G) generator="${OPTARG}" ;;
    \?) log "Invalid option: -$OPTARG" ; exit 1 ;;
    *) usage; exit 2;;
  esac
done
shift $((OPTIND-1))

# Set defaults if not given
if [ -z "${prefix_dir}" ]; then
  prefix_dir="${PWD}/install"
fi
if [ -z "${build_dir}" ]; then
  build_dir="${PWD}/build"
fi
if [ -z "${generator}" ]; then
  if is_command ninja >/dev/null 2>&1 ; then
    generator=Ninja
  else
    generator="Unix Makefiles"
  fi
fi

# Process first argument (source)
list_presets=false
if [ $# -gt 0 ]; then
  source_dir="$(abspath "$1")"
  shift
else
  if [ -f CMakePresets.json ] || [ -f CMakeUserPresets.json ]; then
    list_presets=true
  else
    log "No user/built-in CMake presets are available"
  fi
  source_dir="$PWD"
fi

if ! mkdir "${build_dir}" 2>/dev/null ; then
  if [ $overwrite = true ] ; then
    rm -rf "${build_dir}/CMakeCache.txt" "${build_dir}/CMakeFiles"
  else
    log "Build directory exists at ${build_dir}: use -f to override"
    exit 1
  fi
  if test -L "${build_dir}" ; then
    build_dir="$(readlink "${build_dir}")"
    log "Build directory is a symlink -> ${build_dir}"
  fi
  if is_command tmutil ; then
    # Don't back up build directories
    (
      if tmutil addexclusion "${build_dir}"; then
        log "Time machine exclusion added"
      else
        log "Failed to add time machine exclusion"
      fi
    ) &
  fi
fi

if ${list_presets}; then
  cmake --list-presets configure "${source_dir}"
  log "(Invoke preset with -P or --preset=)"
fi

# Call cmake with remaining arguments
set -x
exec cmake -G "${generator}" --log-level=verbose \
  ${extra_args} \
  "-DCMAKE_INSTALL_PREFIX:PATH=${prefix_dir}" \
  "-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON" \
  "$@" \
  "-B" "${build_dir}" \
  "-S" "${source_dir}"

###############################################################################
# end of initial-cmake.sh
###############################################################################
