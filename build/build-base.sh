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

if ! ${INSTX_TOPDIR}/build.sh cacert
then
    echo "Failed to install CA Certs"
    exit 1
fi
###############################################################################

if ! ${INSTX_TOPDIR}/build.sh autoconf
then
    echo "Failed to build autoconf"
    exit 1
fi

###############################################################################

if ! VERSION=1.15.1 ${INSTX_TOPDIR}/build.sh automake
then
    echo "Failed to build automake 1.15.1"
    exit 1
fi

###############################################################################

if ! VERSION=1.16.5 ${INSTX_TOPDIR}/build.sh automake
then
    echo "Failed to build automake 1.16.5"
    exit 1
fi
###############################################################################

if ! ${INSTX_TOPDIR}/build.sh gmp
then
    echo "Failed to build GMP"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build.sh guile2
then
    echo "Failed to build guile2"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build.sh make
then
    echo "Failed to build make"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build.sh ncurses-readline
then
    echo "Failed to build Ncurses and Readline"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build.sh iconv-gettext
then
    echo "Failed to build iConv and GetText"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build.sh unistr
then
    echo "Failed to build Unistring"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build.sh libxml2
then
    echo "Failed to build libxml2"
    exit 1
fi

###############################################################################

# GetText is checked in build-gettext-final.sh
unset INSTX_DISABLE_GETTEXT_CHECK

if ! ${INSTX_TOPDIR}/build.sh gettext-final
then
    echo "Failed to build GetText final"
    exit 1
fi

###############################################################################

# Trigger a rebuild of PCRE2

rm -f "${INSTX_PKG_CACHE}/pcre2"

if ! ${INSTX_TOPDIR}/build.sh pcre2
then
    echo "Failed to build PCRE2"
    exit 1
fi

###############################################################################

# Trigger a rebuild of IDN2

rm -f "${INSTX_PKG_CACHE}/idn2"

if ! ${INSTX_TOPDIR}/build.sh idn2
then
    echo "Failed to build IDN2"
    exit 1
fi

###############################################################################

touch "${INSTX_PKG_CACHE}/${PKG_NAME}"

exit 0
