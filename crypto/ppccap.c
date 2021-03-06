/* Written by Daniel Kolesa (q66) for LibreSSL-portable-asm.
 * Provided under the same terms as LibreSSL ltself.
 *
 * Does not include support for AIX or old Apple stuff like the original
 * OpenSSL bits, since I have no way to test that. Also handles auxvec
 * differently so it's cross-libc.
 *
 * Follows the same style as armcap.c in LibreSSL.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <signal.h>
#include <openssl/crypto.h>

/* on Linux, we can use the auxiliary vector and avoid SIGILL stuff */
#ifdef __linux__
# define LSSL_USE_AUXV 1
#endif

#ifdef LSSL_USE_AUXV
# include <elf.h>
# include <fcntl.h>
# include <unistd.h>
# define HWCAP_VSX       (1 <<  7)
# define HWCAP_POWER6    (1 <<  9)
# define HWCAP_FPU       (1 << 27)
# define HWCAP_ALTIVEC   (1 << 28)
# define HWCAP_PPC64     (1 << 30)
/* hwcap2 */
# define HWCAP_ISA300    (1 << 23)
# define HWCAP_CRYPTO207 (1 << 25)
#endif

#include "ppc_arch.h"

unsigned int OPENSSL_ppccap_P = 0;

#ifdef OPENSSL_BN_ASM_MONT
#  include <openssl/bn.h>

int bn_mul_mont_int(BN_ULONG *rp, const BN_ULONG *ap, const BN_ULONG *bp,
					const BN_ULONG *np, const BN_ULONG *n0, int num);
int bn_mul4x_mont_int(BN_ULONG *rp, const BN_ULONG *ap, const BN_ULONG *bp,
					const BN_ULONG *np, const BN_ULONG *n0, int num);

int bn_mul_mont(BN_ULONG *rp, const BN_ULONG *ap, const BN_ULONG *bp,
				const BN_ULONG *np, const BN_ULONG *n0, int num)
{
	if (num < 4)
		return 0;

	if ((num & 3) == 0)
		return bn_mul4x_mont_int(rp, ap, bp, np, n0, num);

	/* TODO: maybe import ppc64-mont.pl and use _fpu64 for POWER6 */
	return bn_mul_mont_int(rp, ap, bp, np, n0, num);
}
#endif

#ifdef SHA256_ASM
void sha256_block_p8(void *ctx, const void *inp, size_t len);
void sha256_block_ppc(void *ctx, const void *inp, size_t len);

void sha256_block_data_order(void *ctx, const void *inp, size_t len)
{
	if (OPENSSL_ppccap_P & PPC_CRYPTO207)
		sha256_block_p8(ctx, inp, len);
	else
		sha256_block_ppc(ctx, inp, len);
}
#endif

#ifdef SHA512_ASM
void sha512_block_p8(void *ctx, const void *inp, size_t len);
void sha512_block_ppc(void *ctx, const void *inp, size_t len);

void sha512_block_data_order(void *ctx, const void *inp, size_t len)
{
	if (OPENSSL_ppccap_P & PPC_CRYPTO207)
		sha512_block_p8(ctx, inp, len);
	else
		sha512_block_ppc(ctx, inp, len);
}
#endif

#ifndef LSSL_USE_AUXV
void OPENSSL_altivec_probe(void);
void OPENSSL_crypto207_probe(void);
void OPENSSL_fpu_probe(void);
void OPENSSL_ppc64_probe(void);
void OPENSSL_madd300_probe(void);

static sigset_t all_masked;

static sigjmp_buf ill_jmp;
static void ill_handler(int sig)
{
	siglongjmp(ill_jmp, sig);
}
#endif

#if defined(__GNUC__) && __GNUC__>=2
void OPENSSL_cpuid_setup(void) __attribute__((constructor));
#endif

void
OPENSSL_cpuid_setup(void)
{
	char *e;
	static int trigger = 0;
#ifdef LSSL_USE_AUXV
	int fd;
# ifdef __powerpc64__
	Elf64_auxv_t aux;
# else
	Elf32_auxv_t aux;
# endif
#else
	struct sigaction ill_oact, ill_act;
	sigset_t oset;
#endif

	if (trigger)
		return;
	trigger = 1;

	/* compat */
	if ((e = getenv("OPENSSL_ppccap"))) {
		OPENSSL_ppccap_P = strtoul(e, NULL, 0);
		return;
	}

	OPENSSL_ppccap_P = 0;

#ifdef LSSL_USE_AUXV
	fd = open("/proc/self/auxv", O_RDONLY | O_CLOEXEC);
	unsigned long long hwcap = 0, hwcap2 = 0;
	if (fd >= 0) {
		while (read(fd, &aux, sizeof(aux)) == sizeof(aux)) {
			if (aux.a_type == AT_HWCAP) {
				hwcap = aux.a_un.a_val;
				if (hwcap2) break;
			}
			if (aux.a_type == AT_HWCAP2) {
				hwcap2 = aux.a_un.a_val;
				if (hwcap) break;
			}
		}

		if (hwcap & HWCAP_ALTIVEC) {
			OPENSSL_ppccap_P |= PPC_ALTIVEC;

			if ((hwcap & HWCAP_VSX) && (hwcap2 & HWCAP_CRYPTO207))
				OPENSSL_ppccap_P |= PPC_CRYPTO207;
		}

		/* fpu */
		if (hwcap & HWCAP_FPU) {
			OPENSSL_ppccap_P |= PPC_FPU;
# ifdef __powerpc64__
			if (hwcap & HWCAP_POWER6)
				OPENSSL_ppccap_P |= PPC_FPU64;
# else
			/* fpu64 is always fastest on 32-bit if available */
			if (hwcap & HWCAP_PPC64)
				OPENSSL_ppccap_P |= PPC_FPU64;
# endif
		}

		if (hwcap2 & HWCAP_ISA300)
			OPENSSL_ppccap_P |= PPC_MADD300;

		close(fd);
	}
#else
	/* fallback that uses SIGILL and probes */

	memset(&ill_act, 0, sizeof(ill_act));
	ill_act.sa_handler = ill_handler;
	ill_act.sa_mask = all_masked;

	sigprocmask(SIG_SETMASK, &ill_act.sa_mask, &oset);
	sigaction(SIGILL, &ill_act, &ill_oact);

	sigfillset(&all_masked);
	sigdelset(&all_masked, SIGILL);
	sigdelset(&all_masked, SIGTRAP);
# ifdef SIGEMT
	sigdelset(&all_masked, SIGEMT);
# endif
	sigdelset(&all_masked, SIGFPE);
	sigdelset(&all_masked, SIGBUS);
	sigdelset(&all_masked, SIGSEGV);

	if (sigsetjmp(ill_jmp, 1) == 0) {
		OPENSSL_altivec_probe();
		OPENSSL_ppccap_P |= PPC_ALTIVEC;
		if (sigsetjmp(ill_jmp, 1) == 0) {
			OPENSSL_crypto207_probe();
			OPENSSL_ppccap_P |= PPC_CRYPTO207;
		}
	}

	if (sigsetjmp(ill_jmp, 1) == 0) {
		OPENSSL_fpu_probe();
		OPENSSL_ppccap_P |= PPC_FPU;
# ifndef __powerpc64__
		if (sigsetjmp(ill_jmp, 1) == 0) {
			OPENSSL_ppc64_probe();
			OPENSSL_ppccap_P |= PPC_FPU64;
		}
# else
		/* FIXME, detect power6 */
# endif
	}

	if (sigsetjmp(ill_jmp, 1) == 0) {
		OPENSSL_madd300_probe();
		OPENSSL_ppccap_P |= PPC_MADD300;
	}

	sigaction (SIGILL, &ill_oact, NULL);
	sigprocmask(SIG_SETMASK, &oset, NULL);
#endif
}
