#!/bin/sh
#
# This patches a LibreSSL installation.

die() {
    echo "$@"
    exit 1
}

[ -z "$1" ] && die "usage: $0 path-to-libressl-release"

if [ ! -x "$(command -v patch)" ]; then
    die "patch not found"
fi

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

if [ ! -d "$1" ]; then
    die "libressl not found"
fi

echo "copying build files..."

cp ${SCRIPT_DIR}/crypto/Makefile.am.* "$1"/crypto || \
    die "failed to copy makefiles"
cp ${SCRIPT_DIR}/crypto/*.c ${SCRIPT_DIR}/crypto/*.h "$1"/crypto || \
    die "failed to copy source files"

echo "copying generated files..."

for x in $(find "${SCRIPT_DIR}/generated" -name '*.S'); do
    x=${x#${SCRIPT_DIR}/generated/}
    mkdir -p "$1"/${x%/*} || die "failed to create ${x%/*}"
    cp ${SCRIPT_DIR}/generated/"$x" "$1"/$x || die "failed to copy $x"
done

echo "patching tree..."

for p in ${SCRIPT_DIR}/patches/*.patch; do
    patch -d "$1" -Np1 < $p || die "failed to apply $p"
done

echo "done! don't forget to regenerate autotools files before building"
