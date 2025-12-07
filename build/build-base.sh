#!/usr/bin/env bash
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Written and placed in public domain by Jeffrey Walton

# This script builds a handful of packages that are used by most GNU packages.
# The primary packages built by this script are Patchelf, Ncurses, Readline,
# iConvert and GetText.
#
# The primary packages have prerequisites, so secondary packages include
# libunistring, libxml2, PCRE2 and IDN2. GetText is rebuilt a final time
# after libunitstring and libxml2 are ready.
#
# GetText is the real focus of this script. GetText is built in two stages.
# First, the iConv/GetText pair is built due to circular dependency. Second,
# the final GetText is built which includes libunistring and libxml2.
#
# Most GNU packages will just call build-base.sh to get the common packages
# out of the way. Non-GNU packages can call the script, too.

PKG_NAME=gnu-base

###############################################################################


# PKG_NAME trick does not work here... Export INSTX_BASE_RECURSION_GUARD
# to avoid reentering this script for recipes like IDN2 and PCRE2.
# INSTX_BASE_RECURSION_GUARD goes out of scope when this shell dies.

if [[ "$INSTX_BASE_RECURSION_GUARD" == "yes" ]]; then
    exit 0
else
    INSTX_BASE_RECURSION_GUARD=yes
    export INSTX_BASE_RECURSION_GUARD
fi


###############################################################################

# Get the environment as needed.
if [[ "${SETUP_ENVIRON_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-environ.sh
    then
        echo "Failed to set environment"
        exit 1
    fi
fi

if [[ -e "${INSTX_PKG_CACHE}/${PKG_NAME}" ]]; then
    echo ""
    echo "$PKG_NAME is already installed."
    exit 0
fi

# The password should die when this subshell goes out of scope
if [[ "${SUDO_PASSWORD_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-password.sh
    then
        echo "Failed to process password"
        exit 1
    fi
fi

# GetText will be checked in build-gettext-final.sh
export INSTX_DISABLE_GETTEXT_CHECK=1

###############################################################################

if [ ! -f "${INSTX_PKG_CACHE}/cacert" ]; then

if ! ${INSTX_TOPDIR}/build.sh cacert 2025.2.80_v9.0.304-2
then
    echo "Failed to install CA Certs"
    exit 1
fi
fi
VERSION=
###############################################################################

if ! VERSION=2.71 ${INSTX_TOPDIR}/build.sh autoconf 2.71
then
    echo "Failed to build autoconf"
    exit 1
fi
VERSION=
hash -r
###############################################################################

if ! VERSION=1.15.1 ${INSTX_TOPDIR}/build.sh automake 1.15.1
then
    echo "Failed to build automake 1.15.1"
    exit 1
fi
VERSION=
hash -r
###############################################################################

if ! VERSION=1.16.5 ${INSTX_TOPDIR}/build.sh automake 1.16.5
then
    echo "Failed to build automake 1.16.5"
    exit 1
fi
VERSION=
hash -r
###############################################################################
if [ ! -f "${INSTX_PKG_CACHE}/gmp" ]; then
if ! VERSION=6.2.1 ${INSTX_TOPDIR}/build.sh gmp 6.2.1
then
    echo "Failed to build GMP 6.2.1"
    exit 1
fi
fi
VERSION=
hash -r
###############################################################################

# Solaris is missing the Boehm GC. We have to build it. Ugh...
if [[ "$IS_SOLARIS" -eq 1 ]]; then
    if ! ${INSTX_TOPDIR}/build.sh boehm-gc
    then
        echo "Failed to build Boehm GC"
        exit 1
    fi
fi
hash -r
VERSION=
###############################################################################
if [ ! -f "${INSTX_PKG_CACHE}/libffi" ]; then
if ! VERSION=3.2.1 ${INSTX_TOPDIR}/build.sh libffi 3.2.1
then
    echo "Failed to build libffi"
    exit 1
fi
fi
hash -r
VERSION=
###############################################################################
if [ ! -f "${INSTX_PKG_CACHE}/zlib" ]; then
if ! ${INSTX_TOPDIR}/build.sh zlib
then
    echo "Failed to install zlib"
    exit 1
fi
fi
hash -r
VERSION=
###############################################################################
if [ ! -f "${INSTX_PKG_CACHE}/unzip" ]; then
if ! ${INSTX_TOPDIR}/build.sh unzip
then
    echo "Failed to install unzip"
    exit 1
fi
fi
hash -r
VERSION=
###############################################################################
if [ ! -f "${INSTX_PKG_CACHE}/bzip2" ]; then
if ! VERSION=1.0.8 ${INSTX_TOPDIR}/build.sh bzip2 1.0.8
then
    echo "Failed to build bzip"
    exit 1
fi
fi
hash -r
VERSION=

###############################################################################
hash -r
VERSION=
if [ ! -f "${INSTX_PKG_CACHE}/ncurses-readline" ]; then
if ! ${INSTX_TOPDIR}/build.sh ncurses-readline
then
    echo "Failed to build Ncurses and Readline"
    exit 1
fi
fi
hash -r
###############################################################################
VERSION=
if [ ! -f "${INSTX_PKG_CACHE}/ncurses-readline" ]; then
if ! ${INSTX_TOPDIR}/build.sh ncurses-readline
then
    echo "Failed to build Ncurses and Readline"
    exit 1
fi
fi
hash -r
###############################################################################

if ! ${INSTX_TOPDIR}/build.sh iconv-gettext
then
    echo "Failed to build iConv and GetText"
    exit 1
fi
hash -r
###############################################################################

if ! ${INSTX_TOPDIR}/build.sh unistr
then
    echo "Failed to build Unistring"
    exit 1
fi
hash -r
###############################################################################

# Trigger a rebuild of tar

rm -f "${INSTX_PKG_CACHE}/tar"

if ! ${INSTX_TOPDIR}/build.sh tar
then
    echo "Failed to build tar"
    exit 1
fi
hash -r
###############################################################################

if ! ${INSTX_TOPDIR}/build.sh libxml2
then
    echo "Failed to build libxml2"
    exit 1
fi
hash -r
###############################################################################

# GetText is checked in build-gettext-final.sh
unset INSTX_DISABLE_GETTEXT_CHECK

if ! ${INSTX_TOPDIR}/build.sh gettext-final
then
    echo "Failed to build GetText final"
    exit 1
fi
hash -r
###############################################################################

# Trigger a rebuild of PCRE2

rm -f "${INSTX_PKG_CACHE}/pcre2"

if ! ${INSTX_TOPDIR}/build.sh pcre2 10.21
then
    echo "Failed to build PCRE2"
    exit 1
fi
hash -r
###############################################################################

# Trigger a rebuild of IDN2

rm -f "${INSTX_PKG_CACHE}/idn2"

if ! ${INSTX_TOPDIR}/build.sh idn2
then
    echo "Failed to build IDN2"
    exit 1
fi
hash -r
###############################################################################

# Trigger a rebuild of mpfr

rm -f "${INSTX_PKG_CACHE}/mpfr"

if ! ${INSTX_TOPDIR}/build.sh mpfr
then
    echo "Failed to build mpfr"
    exit 1
fi
hash -r
###############################################################################

# Trigger a rebuild of make

rm -f "${INSTX_PKG_CACHE}/make"

if ! ${INSTX_TOPDIR}/build.sh make
then
    echo "Failed to build make"
    exit 1
fi
hash -r
###############################################################################

# Trigger a rebuild of bintuils

rm -f "${INSTX_PKG_CACHE}/bintuils"

if ! ${INSTX_TOPDIR}/build.sh bintuils
then
    echo "Failed to build bintuils"
    exit 1
fi
hash -r
###############################################################################

touch "${INSTX_PKG_CACHE}/${PKG_NAME}"

exit 0
