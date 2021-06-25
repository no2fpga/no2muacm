#!/bin/bash

set -e

TAG=`date +%Y%m%d`-`git rev-parse --short HEAD`
DEST="build/muacm-${TAG}"

# Build gateware
make -C gateware
bzip2 -kf build/muacm.ilang
bzip2 -kf build/muacm.v

# Build dist directory
mkdir -p "${DEST}"
mkdir -p "${DEST}/ip"
echo -n "${TAG}" > "build/tag.txt"

cp -a example/* "${DEST}"
cp "build/muacm.ilang.bz2" "${DEST}/ip"
cp "build/muacm.v.bz2" "${DEST}/ip"

cp "doc/LICENSE-CERN-OHL-P-2.0.txt" "${DEST}"
cp "doc/LICENSE-MIT.txt" "${DEST}"

# Create the tagged bz2
cp "build/muacm.ilang.bz2" "build/muacm-${TAG}.ilang.bz2"
cp "build/muacm.v.bz2" "build/muacm-${TAG}.v.bz2"

# Create the archive
pushd build
tar -cjvf "muacm-${TAG}.tar.bz2" "muacm-${TAG}"
popd
