/* Modified for usage with LibreSSL-portable. */

/*
 * Copyright 2009-2020 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the Apache License 2.0 (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <signal.h>
#include <unistd.h>
#if defined(__linux) || defined(_AIX)
# include <sys/utsname.h>
#endif
#if defined(_AIX53)     /* defined even on post-5.3 */
# include <sys/systemcfg.h>
# if !defined(__power_set)
#  define __power_set(a) (_system_configuration.implementation & (a))
# endif
#endif
#if defined(__APPLE__) && defined(__MACH__)
# include <sys/types.h>
# include <sys/sysctl.h>
#endif
#include <openssl/crypto.h>
#include <openssl/bn.h>
#include <openssl/chacha.h>

#include "cryptlib.h"
#include "ppc_arch.h"

unsigned int OPENSSL_ppccap_P = 0;

static sigset_t all_masked;


#ifdef OPENSSL_BN_ASM_MONT
int bn_mul_mont(BN_ULONG *rp, const BN_ULONG *ap, const BN_ULONG *bp,
                const BN_ULONG *np, const BN_ULONG *n0, int num)
{
    int bn_mul_mont_int(BN_ULONG *rp, const BN_ULONG *ap, const BN_ULONG *bp,
                        const BN_ULONG *np, const BN_ULONG *n0, int num);
    int bn_mul4x_mont_int(BN_ULONG *rp, const BN_ULONG *ap, const BN_ULONG *bp,
                          const BN_ULONG *np, const BN_ULONG *n0, int num);

    if (num < 4)
        return 0;

    if ((num & 3) == 0)
        return bn_mul4x_mont_int(rp, ap, bp, np, n0, num);

    /*
     * There used to be [optional] call to bn_mul_mont_fpu64 here,
     * but above subroutine is faster on contemporary processors.
     * Formulation means that there might be old processors where
     * FPU code path would be faster, POWER6 perhaps, but there was
     * no opportunity to figure it out...
     */

    return bn_mul_mont_int(rp, ap, bp, np, n0, num);
}
#endif
void sha256_block_p8(void *ctx, const void *inp, size_t len);
void sha256_block_ppc(void *ctx, const void *inp, size_t len);
void sha256_block_data_order(void *ctx, const void *inp, size_t len);
void sha256_block_data_order(void *ctx, const void *inp, size_t len)
{
    OPENSSL_ppccap_P & PPC_CRYPTO207 ? sha256_block_p8(ctx, inp, len) :
        sha256_block_ppc(ctx, inp, len);
}

void sha512_block_p8(void *ctx, const void *inp, size_t len);
void sha512_block_ppc(void *ctx, const void *inp, size_t len);
void sha512_block_data_order(void *ctx, const void *inp, size_t len);
void sha512_block_data_order(void *ctx, const void *inp, size_t len)
{
    OPENSSL_ppccap_P & PPC_CRYPTO207 ? sha512_block_p8(ctx, inp, len) :
        sha512_block_ppc(ctx, inp, len);
}

static sigjmp_buf ill_jmp;
static void ill_handler(int sig)
{
    siglongjmp(ill_jmp, sig);
}

void OPENSSL_altivec_probe(void);
void OPENSSL_crypto207_probe(void);

#ifdef __linux__
# include <sys/auxv.h>
# define OSSL_IMPLEMENT_GETAUXVAL
#endif

/* I wish <sys/auxv.h> was universally available */
#define HWCAP                   16      /* AT_HWCAP */
#define HWCAP_ALTIVEC           (1U << 28)
#define HWCAP_VSX               (1U << 7)

#define HWCAP2                  26      /* AT_HWCAP2 */
#define HWCAP_VEC_CRYPTO        (1U << 25)

# if defined(__GNUC__) && __GNUC__>=2
__attribute__ ((constructor))
# endif
void OPENSSL_cpuid_setup(void)
{
    char *e;
    struct sigaction ill_oact, ill_act;
    sigset_t oset;
    static int trigger = 0;

    if (trigger)
        return;
    trigger = 1;

    if ((e = getenv("OPENSSL_ppccap"))) {
        OPENSSL_ppccap_P = strtoul(e, NULL, 0);
        return;
    }

    OPENSSL_ppccap_P = 0;

#if defined(_AIX)
    if (sizeof(size_t) == 4) {
        struct utsname uts;
# if defined(_SC_AIX_KERNEL_BITMODE)
        if (sysconf(_SC_AIX_KERNEL_BITMODE) != 64)
            return;
# endif
        if (uname(&uts) != 0 || atoi(uts.version) < 6)
            return;
    }

# if defined(__power_set)
    /*
     * Value used in __power_set is a single-bit 1<<n one denoting
     * specific processor class. Incidentally 0xffffffff<<n can be
     * used to denote specific processor and its successors.
     */
    if (__power_set(0xffffffffU<<14))           /* POWER6 and later */
        OPENSSL_ppccap_P |= PPC_ALTIVEC;

    if (__power_set(0xffffffffU<<16))           /* POWER8 and later */
        OPENSSL_ppccap_P |= PPC_CRYPTO207;

    return;
# endif
#endif

#if defined(__APPLE__) && defined(__MACH__)
    {
        int val;
        size_t len = sizeof(val);

        len = sizeof(val);
        if (sysctlbyname("hw.optional.altivec", &val, &len, NULL, 0) == 0) {
            if (val)
                OPENSSL_ppccap_P |= PPC_ALTIVEC;
        }

        return;
    }
#endif

#ifdef OSSL_IMPLEMENT_GETAUXVAL
    {
        unsigned long hwcap = getauxval(HWCAP);
        unsigned long hwcap2 = getauxval(HWCAP2);

        if (hwcap & HWCAP_ALTIVEC) {
            OPENSSL_ppccap_P |= PPC_ALTIVEC;

            if ((hwcap & HWCAP_VSX) && (hwcap2 & HWCAP_VEC_CRYPTO))
                OPENSSL_ppccap_P |= PPC_CRYPTO207;
        }
    }
#endif

    sigfillset(&all_masked);
    sigdelset(&all_masked, SIGILL);
    sigdelset(&all_masked, SIGTRAP);
#ifdef SIGEMT
    sigdelset(&all_masked, SIGEMT);
#endif
    sigdelset(&all_masked, SIGFPE);
    sigdelset(&all_masked, SIGBUS);
    sigdelset(&all_masked, SIGSEGV);

    memset(&ill_act, 0, sizeof(ill_act));
    ill_act.sa_handler = ill_handler;
    ill_act.sa_mask = all_masked;

    sigprocmask(SIG_SETMASK, &ill_act.sa_mask, &oset);
    sigaction(SIGILL, &ill_act, &ill_oact);

#ifndef OSSL_IMPLEMENT_GETAUXVAL
    if (sigsetjmp(ill_jmp, 1) == 0) {
        OPENSSL_altivec_probe();
        OPENSSL_ppccap_P |= PPC_ALTIVEC;
        if (sigsetjmp(ill_jmp, 1) == 0) {
            OPENSSL_crypto207_probe();
            OPENSSL_ppccap_P |= PPC_CRYPTO207;
        }
    }
#endif

    sigaction(SIGILL, &ill_oact, NULL);
    sigprocmask(SIG_SETMASK, &oset, NULL);
}
