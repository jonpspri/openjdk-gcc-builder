#!/bin/sh

set -eu

gcc_version=${GCC_VERSION:-8.2.0}
target_registry=${ADOPTOPENJDK_TARGET_REGISTRY:-adoptopenjdk}

docker build --build-arg GCC_VERSION="$gcc_version" \
  -t "$target_registry/openjdk_glib_builder:${gcc_version}-$(uname -m)" .

docker push "$target_registry/openjdk_glib_builder:${gcc_version}-$(uname -m)"
