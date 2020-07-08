# Assembly extensions for LibreSSL-portable

Since LibreSSL-portable does not support assembly for minority architectures
such as POWER and Aarch64, this repo aims to re-add those to get better
performance - on systems with hardware crypto, such as POWER8 and newer,
the difference can be as much as 20x in some cases.

Synchronized from OpenSSL commit: `163b8016160f03558d8352b76fb594685cb39f7d`

**For LibreSSL version: 3.1.3**

## How?

OpenSSL uses a `perlasm` system to deal with assembly preprocessing. That means
assembly files are Perl scripts. You can run those, it will generate stuff for
your particular system flavor, and then they get compiled in, with logic to
pick up the right stuff at runtime.

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

- Original perlasm assembly files (unmodified, besides `ppccpuid.pl` having
  some unneeded bits removed) - you can verify those against OpenSSL
- Generated assembly files for all targets
- Auxiliary C source files from OpenSSL (modified, stripped down)
- Makefiles for assembly platforms
- LibreSSL patches
- Scripts to put it all together

Files `AUTHORS.txt` and `LICENSE.txt` are imported directly from OpenSSL.

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
