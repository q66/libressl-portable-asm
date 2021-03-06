#!/bin/sh
#
# This generates all the assembly files required for build, for all platforms.
#
# Currently supported:
#
# - 64-bit little endian POWER, ELFv2 ABI
# - 64-bit big endian POWER, ELFv2 or ELFv1 ABI
# - 32-bit big endian PowerPC
# - Aarch64
# - ARM

die() {
    echo "$@"
    exit 1
}

if [ ! -x "$(command -v perl)" ]; then
    die "perl not found"
fi

get_flavor() {
    case "$1" in
        armv4) echo linux32; return 0 ;;
        aarch64) echo linux64; return 0 ;;
        ppc64le) echo linux64le; return 0 ;;
        ppc64v2) echo linux64v2; return 0 ;;
        ppc64) echo linux64; return 0 ;;
        ppc) echo linux32; return 0 ;;
        *) ;;
    esac
    die "unknown flavor '$1'"
}

# perlasm ARCH INFILE OUTFILE
perlasm() {
    if [ -n "$4" ]; then
        perl crypto/$2 $(get_flavor $1) generated/crypto/$3-elf-$1.S || \
            die "failed to generate '$4'"
    else
        perl crypto/$2 $(get_flavor $1) > generated/crypto/$3-elf-$1.S || \
            die "failed to generate '$4'"
    fi
}

rm -rf generated || die "failed to remove old files"
mkdir -p generated/crypto/aes   || die "failed to create output dirs"
mkdir -p generated/crypto/bn    || die "failed to create output dirs"
mkdir -p generated/crypto/modes || die "failed to create output dirs"
mkdir -p generated/crypto/sha   || die "failed to create output dirs"

# ppc

generate_ppc() {
    perlasm $1 aes/asm/aes-ppc.pl aes/aes
    perlasm $1 aes/asm/aesp8-ppc.pl aes/aesp8
    perlasm $1 aes/asm/vpaes-ppc.pl aes/vpaes
    perlasm $1 bn/asm/ppc-mont.pl bn/mont
    perlasm $1 modes/asm/ghashp8-ppc.pl modes/ghashp8 outarg
    perlasm $1 sha/asm/sha1-ppc.pl sha/sha1
    perlasm $1 sha/asm/sha512-ppc.pl sha/sha256 outarg
    perlasm $1 sha/asm/sha512-ppc.pl sha/sha512 outarg
    perlasm $1 sha/asm/sha512p8-ppc.pl sha/sha256p8 outarg
    perlasm $1 sha/asm/sha512p8-ppc.pl sha/sha512p8 outarg
    perlasm $1 ppccpuid.pl cpuid outarg
}

generate_ppc ppc64le
generate_ppc ppc64v2
generate_ppc ppc64
generate_ppc ppc

# aarch64

perlasm aarch64 aes/asm/aesv8-armx.pl aes/aesv8 outarg
perlasm aarch64 aes/asm/vpaes-armv8.pl aes/vpaes outarg
perlasm aarch64 bn/asm/armv8-mont.pl bn/mont outarg
perlasm aarch64 modes/asm/ghashv8-armx.pl modes/ghashv8 outarg
perlasm aarch64 sha/asm/sha1-armv8.pl sha/sha1 outarg
perlasm aarch64 sha/asm/sha512-armv8.pl sha/sha256 outarg
perlasm aarch64 sha/asm/sha512-armv8.pl sha/sha512 outarg
perlasm aarch64 arm64cpuid.pl cpuid outarg

# arm

perlasm armv4 aes/asm/aes-armv4.pl aes/aes outarg
perlasm armv4 aes/asm/bsaes-armv7.pl aes/bsaes outarg
perlasm armv4 aes/asm/aesv8-armx.pl aes/aesv8 outarg
perlasm armv4 modes/asm/ghash-armv4.pl modes/ghash outarg
perlasm armv4 modes/asm/ghashv8-armx.pl modes/ghashv8 outarg
perlasm armv4 sha/asm/sha1-armv4-large.pl sha/sha1 outarg
perlasm armv4 sha/asm/sha256-armv4.pl sha/sha256 outarg
perlasm armv4 sha/asm/sha512-armv4.pl sha/sha512 outarg

exit 0
