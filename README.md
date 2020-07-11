# Assembly extensions for LibreSSL-portable

Since LibreSSL-portable does not support assembly for minority architectures
such as POWER and Aarch64, this repo aims to re-add those to get better
performance - on systems with hardware crypto, such as POWER8 and newer,
the difference can be as much as 20x in some cases.

The assembly files are taken from CRYPTOGAMS by Andy Polyakov (dot-asm),
see https://github.com/dot-asm/cryptogams and `LICENSE.cryptogams`.

- CRYPTOGAMS commit: `1d27e4fefa7bf058e6ac921eb75b6d3b4b84bfc9`

The following files are taken from OpenSSL and are subject to the OpenSSL
license; pre-Apache 2.0 commits were used:

- `vpaes-armv8.pl`: `46f4e1bec51dc96fa275c168752aa34359d9ee51`
- `armv8-mont.pl`: `6aa36e8e5a062e31543e7796f0351ff9628832ce`
- `ppc-mont.pl`: `774ff8fed67e19d4f5f0df2f59050f2737abab2a`
- `ppccpuid.pl`: OpenSSL 1.1.1g, just CPU probes

See `LICENSE.openssl` for those.

Some files are currently adapted from OpenSSL commit
`163b8016160f03558d8352b76fb594685cb39f7d`

**For LibreSSL version: 3.1.3**

## How?

CRYPTOGAMS uses a `perlasm` system to deal with assembly preprocessing. That
means assembly files are Perl scripts. You can run those, it will generate
stuff for your particular system flavor, and then they get compiled in, with
logic to pick up the right stuff at runtime.

LibreSSL-portable lacks this system, instead using already generated assembly
files. Therefore, we have to run the `perlasm` generation externally, and then
provide these files to LibreSSL.

Fortunately, for most part they are already compatible. All that was necessary
to do was pretty much to add the right runtime CPU detection logic, and in a
few places patch things a little (`hwaes`, `gcm128`), and feed the results
to the build system.

Keep in mind that not *all* assembly stuff is imported. There are things that
LibreSSL doesn't have assembly for even on `x86_64`, as well as things OpenSSL
has and LibreSSL lacks entirely, and so on.

## Contents

This project consists of:

- Assembly files (`perlasm`) from the CRYPTOGAMS project
- Assembly files (`perlasm`) from the OpenSSL project where not in the above
- Generated assembly files (`.S`) using the above sources
- CPU feature checkers (new)
- Makefiles for assembly platforms
- LibreSSL patches
- Scripts to put it all together

## Supported platforms

 - 64-bit little endian POWER, ELFv2 ABI
 - 64-bit big endian POWER, ELFv2 or ELFv1 ABI
 - 32-bit big endian PowerPC

## Usage

The project ships with pre-generated assembly files. You can re-generate
them using `generate.sh` if you want or don't trust that I'm not a malicious
entity :). You will need `perl` installed if you want to do that.

Otherwise, to patch a LibreSSL distribution, run `patch_libressl.sh` with
a path to LibreSSL as the only argument.

After that, regenerate the autotools buildsystem and build as usual. Assembly
is enabled by default for all supported architectures.
