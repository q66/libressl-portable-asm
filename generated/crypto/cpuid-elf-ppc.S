.machine	"any"
.text

.globl	OPENSSL_fpu_probe
.type	OPENSSL_fpu_probe,@function
.align	4
OPENSSL_fpu_probe:
	fmr	0,0
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	OPENSSL_fpu_probe,.-OPENSSL_fpu_probe
.globl	OPENSSL_ppc64_probe
.type	OPENSSL_ppc64_probe,@function
.align	4
OPENSSL_ppc64_probe:
	fcfid	1,1
	rldicl	0,0,32,32
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	OPENSSL_ppc64_probe,.-OPENSSL_ppc64_probe

.globl	OPENSSL_altivec_probe
.type	OPENSSL_altivec_probe,@function
.align	4
OPENSSL_altivec_probe:
.long	0x10000484
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	OPENSSL_altivec_probe,.-OPENSSL_altivec_probe

.globl	OPENSSL_crypto207_probe
.type	OPENSSL_crypto207_probe,@function
.align	4
OPENSSL_crypto207_probe:
	.long	0x7C000E99
	.long	0x10000508
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	OPENSSL_crypto207_probe,.-OPENSSL_crypto207_probe

.globl	OPENSSL_madd300_probe
.type	OPENSSL_madd300_probe,@function
.align	4
OPENSSL_madd300_probe:
	xor	0,0,0
	.long	0x10600033
	.long	0x10600031
	blr	
.long	0
.byte	0,12,0x14,0,0,0,0,0
.size	OPENSSL_madd300_probe,.-OPENSSL_madd300_probe
