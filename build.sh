#!/bin/sh

set -eu

gcc_version=${GCC_VERSION:-9.1.0}
target_registry=${ADOPTOPENJDK_TARGET_REGISTRY:-adoptopenjdk}

docker build --build-arg GCC_VERSION="$gcc_version" \
  -t "$target_registry/openjdk-gcc-builder:${gcc_version}-$(uname -m)" \
  ./builder-image/.

docker push "$target_registry/openjdk-gcc-builder:${gcc_version}-$(uname -m)"
