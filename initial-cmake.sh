#!/bin/bash -e
###############################################################################
# File  : initial-cmake.sh
###############################################################################

usage () {
  echo "Usage: $0 [-b build_dir] [-p prefix] [-G generator] " >&2
  echo "       source_dir [args]" >&2
  exit 2
}

# Approximation of absolute path 
abspath() { echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")" ; }

# Default options
build_dir=build
prefix_dir=install
generator="$(
  if hash ninja 2>/dev/null ; then 
    echo "Ninja"
  else 
    echo "Unix Makefiles" 
  fi
)"

# Process options
OPTIND=1
while getopts "b:p:G:" opt; do
    case "${opt}" in
        b) build_dir=${OPTARG} ;;
        p) prefix_dir="$(abspath "${OPTARG}")" ;;
        G) generator="${OPTARG}" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        *) usage; exit 2; ;;
    esac
done
shift $((OPTIND-1))

# Process first argument (source)
source_dir="$(abspath "$1")"
shift

mkdir ${build_dir} || (
  echo "Build directory exists at ${build_dir}" >&2
  exit 1
)
cd ${build_dir}

# Call cmake with remaining arguments
set -x
exec cmake -G "${generator}" "-DCMAKE_PREFIX_PATH:PATH=${prefix_dir}" \
     "$@" "${source_dir}"

###############################################################################
# end of initial-cmake.sh
###############################################################################
