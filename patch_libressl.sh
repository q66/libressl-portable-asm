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

if [ ! -d "$1" ]; then
    die "libressl not found"
fi

echo "copying build files..."

cp crypto/Makefile.am.* "$1"/crypto || die "failed to copy makefiles"
cp crypto/*.c crypto/*.h "$1"/crypto || die "failed to copy source files"

echo "copying generated files..."

for x in $(find generated -name '*.S'); do
    x=${x#generated/}
    mkdir -p "$1"/${x%/*} || die "failed to create ${x%/*}"
    cp generated/"$x" "$1"/$x || die "failed to copy $x"
done

echo "patching tree..."

for p in patches/*.patch; do
    patch -d "$1" -Np1 < $p || die "failed to apply $p"
done

echo "done! don't forget to regenerate autotools files before building"
