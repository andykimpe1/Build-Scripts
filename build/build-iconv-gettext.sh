#!/usr/bin/env bash
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Written and placed in public domain by Jeffrey Walton
# This script builds GetText and friends from sources.

# GetText is really unique among packages. It has circular dependencies on
# iConv, libunistring and libxml2. build-iconv-gettext.sh handles the
# iConv and GetText dependency. This script, build-gettext-final.sh,
# handles the libunistring and libxml2 dependencies.
#
# The way to run these scripts is, run build-iconv-gettext.sh first.
# That bootstraps iConv and GetText. Second, run build-gettext-final.sh.
# That gets the missing pieces, like libunistring and libxml support.
#
# For the iConv and GetText recipe, see
# https://www.gnu.org/software/libiconv/.
#
# Here are the interesting dependencies:
#
#   libgettextlib.so: libiconv.so
#   libgettextpo.so:  libiconv.so, libiunistring.so
#   libgettextsrc.so: libz.so, libiconv.so, libiunistring.so, libxml2.so,
#                     libgettextlib.so, libtextstyle.so
#   libiconv.so:      libgettextlib.so
#   libiunistring.so: libiconv.so

###############################################################################

# Get the environment as needed.
if [[ "${SETUP_ENVIRON_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-environ.sh
    then
        echo "Failed to set environment"
        exit 1
    fi
fi

if [[ -e "${INSTX_PKG_CACHE}/iconv" ]] && [[ -e "${INSTX_PKG_CACHE}/gettext" ]]; then
    echo ""
    echo "iConv and GetText are already installed."
    exit 0
fi

###############################################################################

# Rebuild them as a pair
rm -f "${INSTX_PKG_CACHE}/iconv"
rm -f "${INSTX_PKG_CACHE}/gettext"

###############################################################################

# pkg-config is special
export INSTX_DISABLE_ICONV_TEST=1

if [[ "$IS_DARWIN" -ne 0 ]]
then
    if ! ${INSTX_TOPDIR}/build.sh iconv-utf8mac
    then
        echo "Failed to build iConv and GetText (1st time)"
        exit 1
    fi
else
    if ! ${INSTX_TOPDIR}/build.sh iconv
    then
        echo "Failed to build iConv and GetText (1st time)"
        exit 1
    fi
fi

unset INSTX_DISABLE_ICONV_TEST

###############################################################################

if ! ${INSTX_TOPDIR}/build.sh gettext
then
    echo "Failed to build GetText"
    exit 1
fi

###############################################################################

# Due to circular dependency. Once GetText is built, we need
# to build iConvert again so it picks up the new GetText.
rm "${INSTX_PKG_CACHE}/iconv"

if [[ "$IS_DARWIN" -ne 0 ]]
then
    if ! ${INSTX_TOPDIR}/build.sh iconv-utf8mac
    then
        echo "Failed to build iConv and GetText (2nd time)"
        exit 1
    fi
else
    if ! ${INSTX_TOPDIR}/build.sh iconv
    then
        echo "Failed to build iConv and GetText (2nd time)"
        exit 1
    fi
fi

exit 0
