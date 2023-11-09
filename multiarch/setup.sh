#!/bin/bash
# vim: sts=2 sw=2 et ai

set -euo pipefail

if ! type docker &> /dev/null; then
  >&2 printf '❌ this script requires docker\n'
  exit 1
fi

if ! docker buildx version &> /dev/null; then
  >&2 printf '❌ this script requires the docker buildx plugin\n'
  exit 1
fi

docker run --privileged --rm tonistiigi/binfmt --install all

# this is failing, but we don't seem to need it?
# docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

if ! docker context inspect multiarch-builds > /dev/null; then
  docker context create multiarch-builds
else
  >&2 printf '✅ multiarch-builds context already configured\n'
fi

if ! docker buildx inspect multiarch > /dev/null; then
  docker buildx create --name multiarch --driver docker-container --bootstrap --use multiarch-builds
else
  >&2 printf '✅ multiarch buildx builder is already configured\n'
fi
