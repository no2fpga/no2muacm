#!/bin/bash

set -e

TAG=`date +%Y%m%d`-`git rev-parse --short HEAD`
DEST_BIN="build/muacm-bin-${TAG}"
DEST_EXAMPLE="build/muacm-example-${TAG}"

# Build gateware
make -C gateware
bzip2 -kf build/muacm.ilang
bzip2 -kf build/muacm.v

# Save tag
echo -n "${TAG}" > "build/tag.txt"

# Build 'bin' dist directory
mkdir -p "${DEST_BIN}"

cp "build/muacm.ilang" "${DEST_BIN}"
cp "build/muacm.v" "${DEST_BIN}"
cp "utils/muacm_customize.py" "${DEST_BIN}"

cp "README.md" "${DEST_BIN}/README-core.md"
cp "README-bin.md" "${DEST_BIN}/README.md"
cp "doc/LICENSE-CERN-OHL-P-2.0.txt" "${DEST_BIN}"
cp "doc/LICENSE-MIT.txt" "${DEST_BIN}"
cp "gateware/cores/serv/LICENSE" "${DEST_BIN}/LICENSE-ISC-SERV.txt"

# Build 'example' dist directory
mkdir -p "${DEST_EXAMPLE}"
mkdir -p "${DEST_EXAMPLE}/ip"
mkdir -p "${DEST_EXAMPLE}/utils"

cp -a example/* "${DEST_EXAMPLE}"

cp "build/muacm.ilang.bz2" "${DEST_EXAMPLE}/ip"
cp "build/muacm.v.bz2" "${DEST_EXAMPLE}/ip"

cp "README.md" "${DEST_EXAMPLE}/README-core.md"
cp "doc/LICENSE-CERN-OHL-P-2.0.txt" "${DEST_EXAMPLE}"
cp "doc/LICENSE-MIT.txt" "${DEST_EXAMPLE}"
cp "gateware/cores/serv/LICENSE" "${DEST_EXAMPLE}/LICENSE-ISC-SERV.txt"

cp "utils/muacm_customize.py" "${DEST_EXAMPLE}/utils"

# Create the archives
pushd build
tar -cjvf "muacm-bin-${TAG}.tar.bz2" "muacm-bin-${TAG}"
tar -cjvf "muacm-example-${TAG}.tar.bz2" "muacm-example-${TAG}"
popd
