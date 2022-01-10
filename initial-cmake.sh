#!/bin/sh -e
###############################################################################
# File  : initial-cmake.sh
###############################################################################

usage () {
  echo "Usage: $0 [-f] [-b build_dir] [-p prefix] [-G generator] " >&2
  echo "       [source_dir] [args]" >&2
  exit 2
}

# Approximation of absolute path 
abspath() { echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")" ; }

overwrite=false
build_dir=
prefix_dir=
generator=

# Process options
OPTIND=1
while getopts "fb:p:G:" opt; do
  case "${opt}" in
    f) overwrite=true ;;
    b) build_dir=${OPTARG} ;;
    p) prefix_dir="$(abspath "${OPTARG}")" ;;
    G) generator="${OPTARG}" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    *) usage; exit 2; ;;
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
  if hash ninja 2>/dev/null ; then 
    generator=Ninja
  else 
    generator="Unix Makefiles" 
  fi
fi

# Process first argument (source)
if [ $# -gt 0 ]; then
  source_dir="$(abspath "$1")"
  shift
else
  source_dir="$PWD"
fi

if ! mkdir "${build_dir}" ; then
  if [ $overwrite = true ] ; then
    rm -rf "${build_dir}/CMakeCache.txt" "${build_dir}/CMakeFiles"
  else
    echo "Build directory exists at ${build_dir}" >&2
    exit 1
  fi
fi
cd "${build_dir}"

# Call cmake with remaining arguments
set -x
exec cmake -G "${generator}" \
  "-DCMAKE_INSTALL_PREFIX:PATH=${prefix_dir}" \
  "-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON" \
  "$@" "${source_dir}"

###############################################################################
# end of initial-cmake.sh
###############################################################################
