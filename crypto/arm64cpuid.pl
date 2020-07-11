#! /usr/bin/env perl
# Copyright 2015-2018 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the OpenSSL license (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

# LibreSSL-portable-asm note (@q66):
#
# Taken from OpenSSL 9a708bf982da1d2c9739339d16d7b021da955e00, stripped down
# to just the CPU feature probes

$flavour = shift;
$output  = shift;

$0 =~ m/(.*[\/\\])[^\/\\]+$/; $dir=$1;
( $xlate="${dir}arm-xlate.pl" and -f $xlate ) or
( $xlate="${dir}perlasm/arm-xlate.pl" and -f $xlate) or
die "can't locate arm-xlate.pl";

open OUT,"| \"$^X\" $xlate $flavour $output";
*STDOUT=*OUT;

$code.=<<___;
.text
.arch	armv8-a+crypto

.align	5
.globl	_armv7_neon_probe
.type	_armv7_neon_probe,%function
_armv7_neon_probe:
	orr	v15.16b, v15.16b, v15.16b
	ret
.size	_armv7_neon_probe,.-_armv7_neon_probe

.globl	_armv8_aes_probe
.type	_armv8_aes_probe,%function
_armv8_aes_probe:
	aese	v0.16b, v0.16b
	ret
.size	_armv8_aes_probe,.-_armv8_aes_probe

.globl	_armv8_sha1_probe
.type	_armv8_sha1_probe,%function
_armv8_sha1_probe:
	sha1h	s0, s0
	ret
.size	_armv8_sha1_probe,.-_armv8_sha1_probe

.globl	_armv8_sha256_probe
.type	_armv8_sha256_probe,%function
_armv8_sha256_probe:
	sha256su0	v0.4s, v0.4s
	ret
.size	_armv8_sha256_probe,.-_armv8_sha256_probe

.globl	_armv8_pmull_probe
.type	_armv8_pmull_probe,%function
_armv8_pmull_probe:
	pmull	v0.1q, v0.1d, v0.1d
	ret
.size	_armv8_pmull_probe,.-_armv8_pmull_probe

.globl	_armv8_sha512_probe
.type	_armv8_sha512_probe,%function
_armv8_sha512_probe:
	.long	0xcec08000	// sha512su0	v0.2d,v0.2d
	ret
.size	_armv8_sha512_probe,.-_armv8_sha512_probe
___

print $code;
close STDOUT;
