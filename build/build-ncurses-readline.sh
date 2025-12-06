#!/usr/bin/env bash
INSTX_TOPDIR=$(find /home/andy -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Written and placed in public domain by Jeffrey Walton
# This script builds iConv and Gettext from sources.

# Ncurses and Readline are closely coupled. Whenever
# Ncurses is built, build Readline, too.

###############################################################################

# Get the environment as needed.
if [[ "${SETUP_ENVIRON_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-environ.sh
    then
        echo "Failed to set environment"
        exit 1
    fi
fi

if [[ -e "${INSTX_PKG_CACHE}/ncurses" ]] && [[ -e "${INSTX_PKG_CACHE}/readline" ]]; then
    echo ""
    echo "Ncurses and Readline are already installed."
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

###############################################################################

# Rebuild them as a pair
rm -f "${INSTX_PKG_CACHE}/ncurses"
rm -f "${INSTX_PKG_CACHE}/readline"

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-ncurses.sh
then
    echo "Failed to build Ncurses"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-readline.sh
then
    echo "Failed to build Readline"
    exit 1
fi

###############################################################################

# Readline renames libraries, including libhistory and libreadline.
# Delete the old libraries once they are unneeded. Don't delete them
# in the readline recipe.
if [[ -n "${SUDO_PASSWORD}" ]]; then
   printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S rm -f "${INSTX_LIBDIR}/.*.old"
else
    rm -rf "${INSTX_LIBDIR}/.*.old"
fi

exit 0
