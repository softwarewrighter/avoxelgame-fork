#!/usr/bin/env bash
set -euo pipefail
# Produces libLSE.dylib (macOS) or libLSE.so (Linux) in ./libs,
# alongside copies of the SDL3 shared libraries it links against.
cd "$(dirname "$0")/../lse"
mkdir -p build && cd build
cmake ..
make
make install
