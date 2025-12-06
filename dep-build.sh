#!/bin/bash
bashedit() {
sed -i '1d' $1
cat > build/$1 <<EOF
#!/usr/bin/env bash
INSTX_TOPDIR=\$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "\${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "\$0" == "\${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi
EOF
cat $1 >> build/$1
sed -i "s|./setup|\${INSTX_TOPDIR}/setup|" build/$1
sed -i "s|./build|\${INSTX_TOPDIR}/build/build|" build/$1
sed -i "s|../patch|\${INSTX_TOPDIR}/build/patch|" build/$1
sed -i "s| --ca-certificate=\"\${LETS_ENCRYPT_ROOT}\"||" build/$1
sed -i "s| --ca-certificate=\"\${GITHUB_CA_ZOO}\"||" build/$1
sed -i "s| --ca-certificate=\"\${THE_CA_ZOO}\"||" build/$1
sed -i "s| --ca-certificate=\"\${GITLAB_ROOT}\"||" build/$1
sed -i "s| --ca-certificate=\"\${DIGICERT_ROOT}\"||" build/$1
sed -i "s| --ca-certificate=\"\$ADDTRUST_ROOT\"||" build/$1
sed -i "s| --ca-certificate=\"\${IDENTRUST_ROOT}\"||" build/$1
rm -f $1
}
bashedit build-attr.sh
bashedit build-autoconf.sh
bashedit build-automake1.16.sh
bashedit build-automake1.17.sh
bashedit build-automake.sh
bashedit build-autotools.sh
bashedit build-b2sum.sh
bashedit build-base.sh
bashedit build-bash.sh
bashedit build-bayonne.sh
bashedit build-bc.sh
bashedit build-bdb.sh
bashedit build-bison-rc.sh
bashedit build-bison.sh
bashedit build-boehm-gc-7.2k.sh
bashedit build-boehm-gc.sh
bashedit build-botan.sh
bashedit build-bzip.sh
bashedit build-cacert.sh
bashedit build-cares.sh
bashedit build-clamav.sh
bashedit build-cmake-3.0.sh
bashedit build-cmake.sh
bashedit build-coreutils.sh
bashedit build-cpuid.sh
bashedit build-cryptlib.sh
bashedit build-cryptopp.sh
bashedit build-curl.sh
bashedit build-datefudge.sh
bashedit build-dejagnu.sh
bashedit build-diffutils.sh
bashedit build-dos2unix.sh
bashedit build-ecgen.sh
bashedit build-emacs-rc.sh
bashedit build-emacs.sh
bashedit build-expect.sh
bashedit build-ffmpeg.sh
bashedit build-file-roller.sh
bashedit build-findutils.sh
bashedit build-flex.sh
bashedit build-gawk.sh
bashedit build-gdb-7.12.sh
bashedit build-gdbm.sh
bashedit build-gdb.sh
bashedit build-gettext-final.sh
bashedit build-gettext.sh
bashedit build-ghidra.sh
bashedit build-ghostscript.sh
bashedit build-git.sh
bashedit build-gmake381.sh
bashedit build-gmp.sh
bashedit build-gnucobol-rc.sh
bashedit build-gnulib.sh
bashedit build-gnupg.sh
bashedit build-gnutls.sh
bashedit build-gpgerror.sh
bashedit build-grep.sh
bashedit build-groff.sh
bashedit build-guile2.sh
bashedit build-guile3.sh
bashedit build-gzip.sh
bashedit build-hfsplustools-git.sh
bashedit build-hiredis.sh
bashedit build-iconv-gettext.sh
bashedit build-iconv.sh
bashedit build-iconv-utf8mac.sh
bashedit build-icu.sh
bashedit build-idn2.sh
bashedit build-idn.sh
bashedit build-jansson.sh
bashedit build-ldns-git.sh
bashedit build-ldns.sh
bashedit build-less.sh
bashedit build-libassuan.sh
bashedit build-libedit.sh
bashedit build-libexosip2-rc.sh
bashedit build-libexosip2.sh
bashedit build-libexpat.sh
bashedit build-libffi.sh
bashedit build-libgcrypt.sh
bashedit build-libgsl-git.sh
bashedit build-libgsl.sh
bashedit build-libhsts.sh
bashedit build-libksba.sh
bashedit build-libosip2-rc.sh
bashedit build-libosip2.sh
bashedit build-libpsl.sh
bashedit build-libtasn1.sh
bashedit build-libtool.sh
bashedit build-libxml2.sh
bashedit build-libxslt.sh
bashedit build-lz4.sh
bashedit build-lzip.sh
bashedit build-m4-git.sh
bashedit build-m4-rc.sh
bashedit build-m4.sh
bashedit build-mailutils.sh
bashedit build-makedepend.sh
bashedit build-make.sh
bashedit build-mandoc.sh
bashedit build-mawk.sh
bashedit build-mg.sh
bashedit build-microhttpd.sh
bashedit build-moe.sh
bashedit build-mpc-rc.sh
bashedit build-mpc.sh
bashedit build-mpfr-rc.sh
bashedit build-mpfr.sh
bashedit build-nasm.sh
bashedit build-ncurses-readline.sh
bashedit build-ncurses.sh
bashedit build-nettle.sh
bashedit build-nghttp2.sh
bashedit build-nginx.sh
bashedit build-nPth.sh
bashedit build-nsd.sh
bashedit build-ntbTLS.sh
bashedit build-openldap.sh
bashedit build-opensc.sh
bashedit build-openssh.sh
bashedit build-openssl-1.0.2.sh
bashedit build-openssl-1.1.1.sh
bashedit build-openssl-3.1.sh
bashedit build-openssl.sh
bashedit build-openvpn.sh
bashedit build-p11kit.sh
bashedit build-parigp-data.sh
bashedit build-parigp.sh
bashedit build-patchelf.sh
bashedit build-patch-git.sh
bashedit build-patch.sh
bashedit build-pcre2.sh
bashedit build-pcre.sh
bashedit build-pcsclite.sh
bashedit build-perl.sh
bashedit build-pkgconfig.sh
bashedit build-pspp.sh
bashedit build-python2.sh
bashedit build-python3.sh
bashedit build-qemacs.sh
bashedit build-readline.sh
bashedit build-rootkey.sh
bashedit build-sed.sh
bashedit build-sipwitch.sh
bashedit build-sqlite3.sh
bashedit build-sslscan.sh
bashedit build-ssm.sh
bashedit build-tar.sh
bashedit build-tinyxml2.sh
bashedit build-ucommon.sh
bashedit build-unbound.sh
bashedit build-unistr-git.sh
bashedit build-unistr.sh
bashedit build-unzip.sh
bashedit build-uthash.sh
bashedit build-valgrind-git.sh
bashedit build-wget2.sh
bashedit build-wget.sh
bashedit build-x264.sh
bashedit build-x265.sh
bashedit build-xerces.sh
bashedit build-xproto.sh
bashedit build-xz-5.0.sh
bashedit build-xz.sh
bashedit build-yasm.sh
bashedit build-zile.sh
bashedit build-zlib.sh
bashedit build-zstd.sh