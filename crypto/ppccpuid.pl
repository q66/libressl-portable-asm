#! /usr/bin/env perl
# Copyright 2007-2020 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

# Adapted for LibreSSL-portable by stripping down

# $output is the last argument if it looks like a file (it has an extension)
# $flavour is the first argument if it doesn't look like a file
$output = $#ARGV >= 0 && $ARGV[$#ARGV] =~ m|\.\w+$| ? pop : undef;
$flavour = $#ARGV >= 0 && $ARGV[0] !~ m|\.| ? shift : undef;

$0 =~ m/(.*[\/\\])[^\/\\]+$/; $dir=$1;
( $xlate="${dir}ppc-xlate.pl" and -f $xlate ) or
( $xlate="${dir}perlasm/ppc-xlate.pl" and -f $xlate) or
die "can't locate ppc-xlate.pl";

open STDOUT,"| $^X $xlate $flavour \"$output\""
    or die "can't call $xlate: $!";

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
___

$code =~ s/\`([^\`]*)\`/eval $1/gem;
print $code;
close STDOUT or die "error closing STDOUT: $!";
