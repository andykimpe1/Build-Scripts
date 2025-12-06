#!/usr/bin/env bash
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Written and placed in public domain by Jeffrey Walton
# This script builds Autotools from sources. A separate
# script is available for Libtool for brave souls.

# Trying to update Autotools may be more trouble than it is
# worth. If the upgrade goes bad, then you can uninstall
# it with the script clean-autotools.sh

###############################################################################

# Get the environment as needed.
if [[ "${SETUP_ENVIRON_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-environ.sh
    then
        echo "Failed to set environment"
        exit 1
    fi
fi

# The password should die when this subshell goes out of scope
if [[ "${SUDO_PASSWORD_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-password.sh
    then
        echo "Failed to process password"
        exit 1
    fi
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-cacert.sh
then
    echo "Failed to install CA Certs"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-m4.sh
then
    echo "Failed to build M4"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-autoconf.sh
then
    echo "Failed to build Autoconf"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-automake.sh
then
    echo "Failed to build Automake"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-libtool.sh
then
    echo "Failed to build Libtool"
    exit 1
fi

###############################################################################

exit 0
