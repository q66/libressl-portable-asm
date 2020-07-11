#! /usr/bin/env perl
# Copyright 2007-2020 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the OpenSSL license (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

# LibreSSL-portable-asm note (@q66):
#
# Taken from OpenSSL 1.1.1g, stripped down to just the CPU feature probes

$flavour = shift;

$0 =~ m/(.*[\/\\])[^\/\\]+$/; $dir=$1;
( $xlate="${dir}ppc-xlate.pl" and -f $xlate ) or
( $xlate="${dir}perlasm/ppc-xlate.pl" and -f $xlate) or
die "can't locate ppc-xlate.pl";

open STDOUT,"| $^X $xlate $flavour ".shift || die "can't call $xlate: $!";

if ($flavour=~/64/) {
    $CMPLI="cmpldi";
    $SHRLI="srdi";
    $SIGNX="extsw";
} else {
    $CMPLI="cmplwi";
    $SHRLI="srwi";
    $SIGNX="mr";
}

$code=<<___;
.machine	"any"
.text

.globl	.OPENSSL_fpu_probe
.align	4
.OPENSSL_fpu_probe:
	fmr	f0,f0
	blr
	.long	0
	.byte	0,12,0x14,0,0,0,0,0
.size	.OPENSSL_fpu_probe,.-.OPENSSL_fpu_probe
.globl	.OPENSSL_ppc64_probe
.align	4
.OPENSSL_ppc64_probe:
	fcfid	f1,f1
	extrdi	r0,r0,32,0
	blr
	.long	0
	.byte	0,12,0x14,0,0,0,0,0
.size	.OPENSSL_ppc64_probe,.-.OPENSSL_ppc64_probe

.globl	.OPENSSL_altivec_probe
.align	4
.OPENSSL_altivec_probe:
	.long	0x10000484	# vor	v0,v0,v0
	blr
	.long	0
	.byte	0,12,0x14,0,0,0,0,0
.size	.OPENSSL_altivec_probe,.-..OPENSSL_altivec_probe

.globl	.OPENSSL_crypto207_probe
.align	4
.OPENSSL_crypto207_probe:
	lvx_u	v0,0,r1
	vcipher	v0,v0,v0
	blr
	.long	0
	.byte	0,12,0x14,0,0,0,0,0
.size	.OPENSSL_crypto207_probe,.-.OPENSSL_crypto207_probe

.globl	.OPENSSL_madd300_probe
.align	4
.OPENSSL_madd300_probe:
	xor	r0,r0,r0
	maddld	r3,r0,r0,r0
	maddhdu	r3,r0,r0,r0
	blr
	.long	0
	.byte	0,12,0x14,0,0,0,0,0
.size	.OPENSSL_madd300_probe,.-.OPENSSL_madd300_probe
___

$code =~ s/\`([^\`]*)\`/eval $1/gem;
print $code;
close STDOUT or die "error closing STDOUT: $!";
