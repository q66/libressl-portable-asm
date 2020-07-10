.machine	"any"
.abiversion	2
.text

.globl	OPENSSL_altivec_probe
.type	OPENSSL_altivec_probe,@function
.align	4
OPENSSL_altivec_probe:
.localentry	OPENSSL_altivec_probe,0

.long	0x10000484
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	OPENSSL_altivec_probe,.-OPENSSL_altivec_probe

.globl	OPENSSL_crypto207_probe
.type	OPENSSL_crypto207_probe,@function
.align	4
OPENSSL_crypto207_probe:
.localentry	OPENSSL_crypto207_probe,0

	.long	0x7C000E99
	.long	0x10000508
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	OPENSSL_crypto207_probe,.-OPENSSL_crypto207_probe
