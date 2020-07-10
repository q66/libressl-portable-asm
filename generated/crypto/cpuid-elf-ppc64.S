.machine	"any"
.text

.globl	OPENSSL_altivec_probe
.type	OPENSSL_altivec_probe,@function
.section	".opd","aw"
.align	3
OPENSSL_altivec_probe:
.quad	.OPENSSL_altivec_probe,.TOC.@tocbase,0
.previous
.align	4
.OPENSSL_altivec_probe:
.long	0x10000484
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	.OPENSSL_altivec_probe,.-.OPENSSL_altivec_probe
.size	OPENSSL_altivec_probe,.-.OPENSSL_altivec_probe

.globl	OPENSSL_crypto207_probe
.type	OPENSSL_crypto207_probe,@function
.section	".opd","aw"
.align	3
OPENSSL_crypto207_probe:
.quad	.OPENSSL_crypto207_probe,.TOC.@tocbase,0
.previous
.align	4
.OPENSSL_crypto207_probe:
	.long	0x7C000E99
	.long	0x10000508
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	.OPENSSL_crypto207_probe,.-.OPENSSL_crypto207_probe
.size	OPENSSL_crypto207_probe,.-.OPENSSL_crypto207_probe
